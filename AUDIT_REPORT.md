# Code Audit Report — Las Vegas Food Curator

**Repository:** `shane7out/Instagram`
**Audit date:** 2026-07-24
**Scope:** Full codebase — application source (`*.py`), deployment config, docs, and tests.

---

## 1. Executive Summary

The project is a Python/Streamlit + instagrapi application that discovers Las Vegas
food content on Instagram, filters it by follower/engagement thresholds, and reposts
approved videos to Instagram Stories with an attribution overlay. A background worker
(`bot_worker.py`) runs discovery on a schedule; a Streamlit dashboard (`dashboard.py`)
provides human-in-the-loop review.

Overall the architecture is reasonable and the intent is clear, but the code is **not
production-ready**. There are several **crashing bugs on primary code paths**, a
**stored-XSS vector in the dashboard**, and **missing secret hygiene** (no `.gitignore`,
so Instagram session tokens and `.env` can be committed). There is effectively no
automated test coverage. The most serious items should be fixed before this is run
against a real Instagram account.

| Severity | Count | Examples |
|----------|-------|----------|
| 🔴 High | 6 | `st.run()` crash, `mentions` NameError, XSS via `unsafe_allow_html`, no `.gitignore`, wrong instagrapi API usage, ffmpeg filter injection |
| 🟠 Medium | 8 | daily-limit counter not persisted/reset, N+1 API calls, unused `PostLog`, misleading "Published Today", broken test, bare `except` |
| 🟡 Low | 7 | unpinned deps, committed `__pycache__`, docs/path drift, redundant video libs, etc. |

---

## 2. High-Severity Findings

### H-1 — `main.py` default path crashes: `st.run()` does not exist
`main.py:35`
```python
def run_dashboard():
    import streamlit as st
    st.run("dashboard.py")   # AttributeError: module 'streamlit' has no attribute 'run'
```
Running `python main.py` (the default, no-args branch) always crashes. Streamlit apps are
launched with the `streamlit run dashboard.py` CLI, not a `st.run()` call. Either remove
`run_dashboard()` and print instructions, or shell out to `streamlit run`.

### H-2 — `NameError` in discovery when a media has user tags
`bot_engine.py:298`
```python
mentions=','.join([m.tag for h in media.usertags]) if hasattr(media, 'usertags') else '',
```
The comprehension iterates `for h in media.usertags` but references `m` — `NameError`
the moment a discovered post has any usertags. This aborts the item (and, via the
`except` at line 312, rolls back the whole hashtag batch). Also, usertag objects expose
a `.user`, not `.tag`. Correct form is roughly `','.join(t.user.username for t in media.usertags)`.

### H-3 — Stored XSS in the dashboard via `unsafe_allow_html`
`dashboard.py:318-327` (also `264`, `321`)
```python
st.markdown(f"""
<div class="media-card">
    <h4>📹 {item.code}</h4>
    <p><strong>Creator:</strong> @{creator.username ...}</p>
    ...
""", unsafe_allow_html=True)
```
`creator.username`, `item.code`, and `item.caption` originate from Instagram (fully
attacker-controlled) and are interpolated into raw HTML with `unsafe_allow_html=True`.
A crafted username/caption (e.g. containing `<img src=x onerror=...>`) executes script
in the operator's dashboard session. Escape all external strings (`html.escape(...)`)
before interpolation, or render them via normal Streamlit widgets instead of raw HTML.

### H-4 — No `.gitignore`: secrets and session tokens can be committed
Repo root has **no `.gitignore`**, and `__pycache__/*.pyc` is already tracked. The app
writes highly sensitive artifacts to the working directory:
- `lasvegas_restaurants_session.json` — a persisted instagrapi session (auth tokens;
  equivalent to a logged-in Instagram session).
- `.env` — Instagram username/password (per `config.example`).
- `lasvegas_restaurants.db` — the SQLite database.
- `downloads/`, `processed/` — third-party video content.

Any `git add .` (exactly what `DEPLOYMENT_GUIDE.md:44` instructs) risks pushing a live
session token and credentials to a **public** repo. Add a `.gitignore` covering
`.env`, `*_session.json`, `*.db`, `__pycache__/`, `downloads/`, `processed/`, `logs/`
and remove `__pycache__` from tracking.

### H-5 — Wrong instagrapi API usage: `user_medias(username, ...)`
`bot_engine.py:177`
```python
medias = self.client.user_medias(username, amount=10)
```
instagrapi's `user_medias()` expects a numeric **user_id (pk)**, not a username. Passing
a username will fail (or trigger an extra resolve). As written, `get_engagement_rate()`
will typically return `0` for every creator, and since discovery filters on
`engagement_rate < self.min_engagement_rate` (default 2.0), **every candidate is silently
dropped** and discovery yields nothing. Resolve the pk first (`user_id_from_username`)
or reuse the pk already fetched in `get_user_info`.

### H-6 — FFmpeg `drawtext` filter injection via creator username
`video_utils.py:59,75`
```python
credit_text = f"Credit: @{creator_username}"
"-vf", f"...drawtext=text='{credit_text}':...",
```
The username is interpolated unescaped into an FFmpeg filtergraph string wrapped in
single quotes. A username containing `'`, `:`, `\`, or `%` breaks the filter or alters
its behavior (filtergraph injection). Because these values come from Instagram, this is
attacker-influenced. `subprocess` is invoked without a shell (so no OS-command injection),
but the filter itself is corruptible — sanitize/escape the text or pass it via a
`textfile=`/`drawtext` `text_shaping` safe mechanism.

---

## 3. Medium-Severity Findings

### M-1 — Daily action limit is neither persisted nor reset
`bot_engine.py:75,361,472` — `actions_today` is an in-memory counter. In the worker it
is never reset between days (`reset_daily_counter()` is never called in `bot_worker.py`),
and it resets to 0 on every process restart (Railway restarts on failure, up to 10
times per `railway.json`). The "safety feature" advertised in the README does not
reliably cap posts. Persist the count (with a date) in `AppSettings` or the DB.

### M-2 — N+1 Instagram API calls during discovery
`bot_engine.py:255` then `269`→`194` — for each media, `get_user_info()` is called, and
then `get_engagement_rate()` calls `get_user_info()` **again** plus `user_medias()`.
This doubles user lookups and adds a media fetch per candidate, multiplying rate-limit
exposure (the very thing the bot tries to avoid). Fetch user info once and pass it down.

### M-3 — `PostLog` model is defined but never written
`database_models.py:96-108` — `PostLog` exists but no code ever inserts a row. Publishing
history relies solely on `MediaItem.status`/`date_published`, so per-attempt success/error
history (including failed posts) is lost. Either use `PostLog` in `post_to_story`/
`publish_media` or remove it.

### M-4 — "Published Today" metric is misleading
`dashboard.py:166` shows `counts.get('published', 0)` labeled "Published Today", but
`get_media_status_counts` (`database_models.py:135`) counts **all** published items with
no date filter. The number will only ever grow. Filter by `date_published >= today` or
relabel.

### M-5 — Broken end-to-end test
`test_dashboard.cjs` — hardcodes `PROJECT_DIR = '/workspace/lvfc_bot'` (does not match
this repo layout), and `await new Promise(r => setTimeout(r, 10))` waits **10 ms**
(almost certainly meant to be `10000`). It is also `.cjs` using ESM `import` syntax. As
committed it cannot pass and is not wired into any CI. There is no Python test coverage
at all.

### M-6 — Broad transaction rollback discards good items
`bot_engine.py:310-315` — `discover_content` commits once per hashtag, but any exception
mid-loop triggers `self.db_session.rollback()`, discarding items already added for that
hashtag that hadn't been committed. Commit per item (or use savepoints) so one bad media
doesn't lose a batch.

### M-7 — Bare `except:` clauses hide errors
`bot_engine.py:122` (session verify), `bot_engine.py:152` (logout),
`video_utils.py:140` (duration). Bare `except` swallows `KeyboardInterrupt`/`SystemExit`
and masks real failures. Catch specific exceptions and log them.

### M-8 — `download_media` likely misuses `media_download`
`bot_engine.py:331` — `self.client.media_download(media_item.original_media_pk, output_path)`.
instagrapi's `media_download(media_pk, folder=...)` takes a **folder** and derives the
filename itself, returning the resulting `Path`. Passing a full file path (and ignoring
the return value while assuming `output_path` is written) can produce a file at an
unexpected location or a mismatch with `media_item.file_path`. Verify against the
installed instagrapi signature.

---

## 4. Low-Severity Findings

- **L-1 — Unpinned dependencies.** `requirements.txt` uses only `>=` bounds. A future
  `instagrapi`/`streamlit`/`moviepy` release can break builds silently. Pin or use a lockfile.
- **L-2 — `__pycache__` committed.** Compiled `.pyc` files are tracked; remove and ignore.
- **L-3 — Redundant video stacks.** The project pulls in `ffmpeg-python`, `moviepy`,
  **and** shells out to the `ffmpeg` binary directly. `video_utils.py` has two parallel
  implementations (`process_video` via subprocess and `create_vertical_video` via moviepy);
  the latter is never called. Pick one path.
- **L-4 — Docs/layout drift.** `README.md` and `DEPLOYMENT_GUIDE.md` repeatedly reference
  a `lvfc_bot/` subdirectory and `lvfc_bot/dashboard.py`, but all files live at the repo
  root. Deployment steps (Streamlit "Main file path", Railway "root directory") will be wrong.
- **L-5 — Dead `sys.path` manipulation.** `dashboard.py:14` inserts the repo's *parent*
  directory on `sys.path`; imports resolve from the repo root instead. It's a no-op at best.
- **L-6 — CLI reads password with `input()`.** `main.py:53` echoes the password to the
  terminal; use `getpass.getpass()`.
- **L-7 — `bot_worker.py` logs all env var names on failure.** `bot_worker.py:48` dumps
  `list(os.environ.keys())`. It leaks only key names (not values), but is noisy and
  unnecessary in logs.

---

## 5. Legal / Operational Notes (not code defects)

- **Instagram ToS & automation.** Programmatic login, scraping, and auto-posting via
  `instagrapi` (an unofficial private-API client) violates Instagram's Terms of Service
  and risks account suspension. The README's own disclaimer acknowledges this.
- **Copyright / rights.** Reposting other creators' videos — even with a "Credit: @user"
  overlay — does not by itself grant a license to redistribute. The `AUTO_APPROVE=true`
  path (`bot_worker.py:87`) would repost without any human rights check.

These are business/compliance risks the owner should weigh independently of the code.

---

## 6. Prioritized Remediation Plan

1. **Add `.gitignore`** and untrack `__pycache__`; verify no session/`.env`/`.db` files
   are (or have been) committed. *(H-4)*
2. **Fix crashing bugs:** `st.run()` *(H-1)*, the `mentions` comprehension *(H-2)*, and
   the `user_medias(username)` call *(H-5)* — without these, the default entry point and
   discovery don't work end-to-end.
3. **Escape external strings** in the dashboard's `unsafe_allow_html` blocks and in the
   FFmpeg `drawtext` filter. *(H-3, H-6)*
4. **Persist & reset the daily post counter** and add real post logging via `PostLog`.
   *(M-1, M-3)*
5. **Reduce API amplification** in discovery. *(M-2)*
6. **Repair or remove the test**, and add minimal Python unit tests around
   `discover_content` filtering and `get_media_status_counts`. *(M-5)*
7. **Reconcile docs with the actual repo layout**, pin dependencies, and drop the unused
   video path. *(L-1, L-3, L-4)*

---

*Prepared as a static review. No code was executed against a live Instagram account and
no runtime/dynamic analysis was performed; findings are based on source inspection.*
