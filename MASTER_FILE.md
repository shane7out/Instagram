# MASTER FILE — Shane's Web Properties & Automation

**Last updated:** 2026-07-24
**Purpose:** Single cold-start reference. Paste this into a new code chat and you have enough
context to continue any of the projects below without prior conversation history.

> **Credentials are redacted in this file.** This repo (`shane7out/Instagram`) is **public**.
> See [§0.3 Where the real secrets live](#03-where-the-real-secrets-live) before you go looking
> for a PIN that isn't here.

---

## Table of contents

- [§0 The operation at a glance](#0-the-operation-at-a-glance)
- [§1 LVR Dashboard & related sites](#1-lvr-dashboard--related-sites) — Firebase/RTDB stack
  - [1.1 How to deploy (read first)](#11-how-to-deploy-read-first)
  - [1.2 Projects & sites map](#12-projects--sites-map)
  - [1.3 Access tiers](#13-access-tiers)
  - [1.4 Brandon / guest10 implementation](#14-brandon--guest10-implementation)
  - [1.5 Dashboard data model](#15-dashboard-data-model)
  - [1.6 Audit status](#16-audit-status)
  - [1.7 ALS — Alternative Living Spaces](#17-als--alternative-living-spaces)
  - [1.8 Badge Trading](#18-badge-trading)
  - [1.9 Torch Dating](#19-torch-dating)
- [§2 LVFC — this repo (Instagram automation)](#2-lvfc--this-repo-instagram-automation)
  - [2.1 What it does](#21-what-it-does)
  - [2.2 File-by-file reference](#22-file-by-file-reference)
  - [2.3 Data model](#23-data-model)
  - [2.4 Configuration](#24-configuration)
  - [2.5 Deployment as documented](#25-deployment-as-documented)
  - [2.6 Known issues — fixed 2026-07-24](#26-known-issues--fixed-2026-07-24)
- [§3 Consolidated open items](#3-consolidated-open-items)

---

## §0 The operation at a glance

One owner, one Mac, several small tools. Two entirely separate technology stacks:

| Stack | Tech | Hosting | Data store | Covered in |
|---|---|---|---|---|
| Web properties | Single-file HTML apps | Firebase Hosting | Shared Firebase RTDB | §1 |
| Instagram automation (LVFC) | Python | Streamlit Cloud + Railway | Postgres via `DATABASE_URL` | §2 |

The two stacks do not talk to each other, and do not need to.

### 0.1 Properties

| Property | URL | Status |
|---|---|---|
| LVR Dashboard | lvr-data-a60c1.web.app | Live, v438 |
| ALS (containers) | the-atl.web.app | Live |
| Badge Trading | badge-trading.web.app | Live; custom domain pending DNS |
| Torch Dating | lvr-data-a60c1.web.app/dating.html | Live, SPARK_V=53 |
| LVFC Instagram bot | this repo | Code fixed 2026-07-24; needs Postgres + a live run — §2.6 |

### 0.2 Tooling paths on the Mac (not on default PATH)

```
node   = /Users/mac/.local/bin/node
gcloud = /Users/mac/Downloads/google-cloud-sdk/bin/gcloud
```

Deploy scripts call `gcloud auth print-access-token`; that session is already logged in.

### 0.3 Where the real secrets live

Nothing secret is committed to this repo. Real values live in:

1. **Dashboard PINs** — plaintext in the deployed `index.html` source (obscurity only, by design)
   and in the memory files below.
2. **Memory files (source of truth, more detail than this doc):**
   `/Users/mac/.claude/projects/-Users-mac/memory/` — `project_lv_dashboard.md`,
   `project_the_atl.md`, `project_badgetrading.md`, `project_spark_dating.md`, plus feedback and
   security notes. Index: `MEMORY.md`.
3. **Instagram credentials** — Railway environment variables; never committed (`config.example`
   is a template only).

### 0.4 Archived reference material

**The previous LVR master file, dated 2026-07-16, was archived on 2026-07-24 — not deleted.**

It was superseded by this document, but it is worth remembering it exists. This file and the
2026-07-24 handoff it was built from are *summaries*: the memory files in §0.3 are described as
carrying more detail than the handoff does. So if something about the LVR dashboard seems
missing here — an older decision, a workaround, a value nobody wrote down twice — the 7/16 file
is the first place to look before reconstructing it from scratch.

It was moved rather than removed specifically because `~/Downloads/lv-repo-new` is TCC-blocked,
so there may be no git history to recover it from.

---

## §1 LVR Dashboard & related sites

All sites are **single-file HTML apps** deployed to **Firebase Hosting**, backed by a shared
Firebase Realtime Database.

### 1.1 How to deploy (read first)

Three hard-won constraints. Violating any of them wastes an afternoon:

- **The real dashboard repo `~/Downloads/lv-repo-new` is TCC-blocked** (macOS privacy) for Bash
  and file tools. Do not rely on it.
- **Working copy is `/Users/mac/lv-dash-work/index.html`** — pulled live from production and
  edited there. It matches prod.
- **`firebase deploy` FAILS on this machine.** The CLI's parallel uploader drops connections.
  Everything deploys via **REST-API overlay scripts that upload serially. Never switch back to
  the CLI.**

Deploy the dashboard:

```bash
cd /Users/mac/lv-dash-work
node deploy-overlay.js
```

`deploy-overlay.js` reads the current *live* hosting version's full file manifest, keeps every
other file's hash unchanged, and overlays only `/index.html` + `/version.json`. That is why
deploying without the full repo works at all.

> **Always bump `var APP_VERSION=NNN` in `index.html` AND `{v:NNN}` in `version.json` together.**
> If they drift, open tabs either reload-loop or never auto-update. (A 430-vs-434 mismatch caused
> exactly this; fixed — both now move together. Currently **v438**.)

#### Edit method that works reliably

Write a Node script to a scratchpad file. Do **not** use inline `node -e` — single quotes inside
the HTML break shell quoting and the edit silently no-ops.

Use an exact-once anchor check so a bad anchor fails loudly instead of corrupting the file:

```js
const rep = (o, n, t) => {
  const c = s.split(o).length - 1;
  if (c !== 1) { console.log(t + ' FAIL occ=' + c); process.exit(1); }
  s = s.replace(o, n);
};
```

Then syntax-gate every `<script>` block with `new vm.Script()` (skip `type=...json`) before
deploying.

### 1.2 Projects & sites map

| Site (URL) | Firebase project | Hosting siteId | Local folder | Deploy script |
|---|---|---|---|---|
| lvr-data-a60c1.web.app (dashboard + `/dating.html` + `/badges.html`) | lvr-data-a60c1 | lvr-data-a60c1 | `/Users/mac/lv-dash-work` | `deploy-overlay.js` |
| the-atl.web.app (ALS containers) | classiccarsforsale-co | the-atl | `/Users/mac/the-atl` | `_tools/deploy.js` |
| badge-trading.web.app | lvr-data-a60c1 | badge-trading | `/Users/mac/badgetrading` | `deploy-badge.js` |

**Shared RTDB base:** `https://lvr-data-a60c1-default-rtdb.firebaseio.com`

RTDB rules of engagement:

- **Deletes/wipes are blocked by security rules** (hardened 2026-07-06). To "remove" data, write
  `on:0` or null via `PATCH`. Do not `DELETE`.
- **Preview shares LIVE data.** Never run mutating actions in preview.
- Seed new records to staging first.

### 1.3 Access tiers

PINs are redacted here (public repo); real values are in the deployed `index.html` and the memory
files — see [§0.3](#03-where-the-real-secrets-live).

| PIN / link | Who | Access |
|---|---|---|
| `1379**` | Owner | Full. Remembered via localStorage `lv_owner_session_v2` |
| `2323**` | Co-editor (friend) | Full co-editor, shares live data, no deploy. Private DM node `coeditor_dm` |
| `7788**` | Influencer-only co-editor | Locked to Influencers list (`lv-inflonly`) |
| `9988**` | **Brandon Shi (platepost.io)** | Limited co-editor: **only 10 restaurants, no ads**, private DM node `guest10_dm` |
| `?u=brandon-****` | Brandon passwordless link | Same as above, no PIN — one tap in |

**Pin-pad pills** (external shortcuts on the lock screen): Deals, ALS (→ the-atl.web.app),
Brandon (→ passwordless link), lasvegasrestaurantspecials.com, Vegas Pets, Shane's Foreclosures,
Badges, Credit, Business Funding, Dating.

### 1.4 Brandon / guest10 implementation

Current work in flight. All of it hangs off one flag.

- **Flag:** `_guest10` — sessionStorage `lv_guest10`, persisted in `lv_owner_session_v2.guest10`.
- **Constants:** `GUEST10_PIN` (see §0.3), `GUEST10_NUMS=[]`.
  **Empty array = first 10 restaurants by num.** Fill with specific record nums to hand-pick
  which 10 he sees.
- **Filter:** `_guest10Filter()` trims `RESTAURANTS` to 10 and rebuilds `_numToIdx`. Hooked into
  `dashRender()` and `dashUpdateStats()`.
- **Private DM:** node `guest10_dm` (local key `guest10_dm_v1`), separate from both the owner's
  and the `2323**` co-editor's nodes.
- **No ads:** `advertisers-tab-btn` hidden via JS in `_applyCoEditorUI` when `_guest10`, plus CSS
  `body.lv-guest10 #advertisers-tab-btn{display:none}`. `showAllAdsView()` bounces guest10 back to
  `showDashTab()`.
- **Passwordless link:** checked at the top of `_pinInit()` — if `location.search` matches
  `/[?&]u=brandon-XXXX(&|$)/`, set the flags, then `_bioUnlock()` + `_coeDmLoad()`.
- **"Brandon" pill** sits on the pin-pad row after ALS and links to the passwordless URL. One-tap
  public entry; owner accepted the tradeoff since the view is limited and the blast radius small.

**Brandon's cold-outreach pitch** (platepost.io = video digital menus), kept here because it gets
reused verbatim:

> Hi [Name] — I'm Brandon with PlatePost. Love what you're doing at [Restaurant]. Quick idea:
> we turn your menu into short video clips of the actual dishes, so people decide with their eyes
> before they order. Restaurants using it are seeing around a 15% lift in sales — bigger tickets,
> fewer "what's this like?" questions. No app for your guests, works with a QR or tablet. Mind if
> I send a 30-second example made with one of your dishes?

### 1.5 Dashboard data model

Roughly 474 built-in records plus ~1000 in the database.

| Entity | Nodes |
|---|---|
| Restaurants | `dashboard/customrecords` (array) + `dashboard_crec` (keyed adds); tombstones in `dashboard_deleted` |
| Advertisers | `dashboard_adv_crec` / `dashboard_adv_deleted` |
| Influencers | `infl_approved` + `dashboard_infl_crec` |
| Backups | `dashboard_advertisers_backup_daily/{YYYY-MM-DD}` |

**DM writes are append-only and detached from the full-node PUT** (owner-clobber fix, 2026-07-12).
Owner DMs reach the cloud only via per-key `_fbPatch('dm/'+num)`; co-editors write their own
nodes. Do not reintroduce a whole-node DM write.

### 1.6 Audit status

Run of 2026-07-24, **paused mid-run**.

**Passed:**

- Static analysis: 13 script blocks, **0 syntax errors**; 310 handlers all defined; 0 unexpected
  duplicate functions.
- Data integrity: restaurants 682 records / 0 ghosts; influencers 0 duplicates; staging stable at
  541 across all 8 daily backups (no clobber); 0 duplicate IG handles in `crec`.

**Failed — needs a decision:**

- **Advertisers: 8 ghost records.** These nums appear in **both** `dashboard_adv_crec` and
  `dashboard_adv_deleted`. Sitting on tombstones means they are invisibly hidden *and* carry
  num-collision risk.

  All 8 are law firms: HKM, Baziyants, Robinson, Eglet, Van Law, THE702FIRM, Lerner Rowe, Harris.

  ```
  nums: 17650, 17653, 17681, 17704, 17724, 17790, 17794, 17797
  ```

  **Decide: unhide (clear the tombstone) or purge the crec entry.** Not yet actioned.

**Not done:**

- Runtime view-sweep — READ-ONLY preview, all views, target 0 console errors.
- Resulting improvement list.

### 1.7 ALS — Alternative Living Spaces

`the-atl.web.app` — Craigslist shipping-container deal finder for Brandon's friend. 1000-mile
radius of Las Vegas, styled exactly like the owner's Deals site (white/blue). **6-digit PIN**
(his birthday; value in memory files).

**Pipeline:** `_tools/harvest.js` sweeps `sapi.craigslist.org` with `searchPath=sso` (by-owner
only) using adaptive price-band bisection, and writes a compact `als-data.json` where each row is:

```
[title, price, lat, lon, odo, imgId, slug, token, loc, bizFlag, rentFlag]
```

`_tools/deploy.js` publishes.

**Filters:** real-container regex; reject accessories, junk, plastic totes; dealer detector sets
`bizFlag`; rentals split to their own 🔑 tab; minimum $300 and must have a photo. Distance is
computed from **zip 89139** (6500 W Richmar Ave). Live count updates while dragging sliders.
⭐ Favorites → node `als_favs`; ✕ blocklist → node `als_hidden`, and the harvester never
re-imports a blocked listing. No search bar; even 3-column pill grid with a white ring.

**Auto-refresh:** daily at 6:30 AM via launchd
`~/Library/LaunchAgents/com.als.daily-refresh.plist` → `_tools/daily-refresh.sh` (harvest +
deploy, 3× retry, log at `_tools/refresh.log`). **Requires the Mac to be awake.**

Preview config name `the-atl`, port 8930. Lock-screen title "ALS"; LVR pill "ALS".

### 1.8 Badge Trading

Self-contained badge page live at **badge-trading.web.app** (the siteId `badgetrading` was
globally reserved, hence the hyphen). The same file is also served at
`lvr-data-a60c1.web.app/badges.html` — **keep both in sync.**

**DNS is pending the owner.** Custom domains badgetrading.com + www are registered in Firebase.
The owner must set these records at Porkbun:

| Action | Record | Value |
|---|---|---|
| Delete | A @ | 207.207.210.36 and 207.207.210.50 (parking) |
| Add | A @ | 199.36.158.100 |
| Add | TXT @ | `hosting-site=badge-trading` |
| Change | CNAME www | badge-trading.web.app |
| **Keep** | TXT (SPF) | unchanged |

Once records propagate, Firebase auto-verifies and issues SSL.

Recent fix: filter chips now wrap (no off-screen overflow), search box shortened, Medic/EMT label
no longer cut off.

### 1.9 Torch Dating

`lvr-data-a60c1.web.app/dating.html` — **SPARK_V=53**.

Rebranded Spark → **torch.dating**, with a hand-drawn TORCH illustration (SVG: gradient flame,
gold collar, bronze handle) in the topbar, onboarding, and filter header.
Deploy: `spark-dating/_tools/deploy-dating.js`.

Features built: Tonight's Torch (daily pick), Blind Torch (photos unblur through chat), Torch Test
(quiz → 4 types), Voice intros, Vouches.

> **Open question.** SEO/canonical tags still point at **torchdating.com**. The owner said "torch
> dot dating" — confirm which domain was actually registered. If it's **torch.dating**, flip the
> canonical, OG, and JSON-LD URLs. If it's torchdating.com, the current state is correct and this
> item closes.

---

## §2 LVFC — this repo (Instagram automation)

**Las Vegas Food Curator** — discovers high-quality Las Vegas food videos on Instagram, filters
by creator quality, and reposts approved clips to `@lasvegas_restaurants` Stories with a credit
overlay.

Python, SQLAlchemy/SQLite, instagrapi, Streamlit, FFmpeg.

### 2.1 What it does

Intended flow:

```
Railway worker (every 6h)
   → scan hashtags for videos
   → filter: public, ≥1000 followers, ≥2% engagement
   → write rows to database (status = pending_approval)
Streamlit dashboard
   → human reviews the queue
   → approve → download → FFmpeg credit overlay → post to Stories
```

Until 2026-07-24 this flow **had never worked** — three of the Instagram API methods it called
did not exist, and the two components did not share a database. Both are fixed; see
[§2.6](#26-known-issues--fixed-2026-07-24) for what was wrong and what remains.

### 2.2 File-by-file reference

All files live at the **repo root**. There is no `lvfc_bot/` directory, despite what README.md
and DEPLOYMENT_GUIDE.md say.

| File | Role |
|---|---|
| `bot_engine.py` | `InstagramBot` — login/session, discovery, filtering, download, publish. Factory `create_bot(config)` |
| `bot_worker.py` | Headless Railway loop: login, discover every `SCAN_INTERVAL_HOURS`, optional auto-publish |
| `dashboard.py` | Streamlit UI: Discovery, Content Queue, Creators, History, Settings pages |
| `database_models.py` | SQLAlchemy models + `init_database()` + `get_or_create_creator()` |
| `video_utils.py` | `VideoProcessor` — FFmpeg 9:16 scale + `drawtext` credit box; thumbnails; duration; cleanup. Plus a MoviePy alternative, `create_vertical_video()` |
| `main.py` | Entry point. `--cli` gives an interactive menu; bare invocation tries to launch Streamlit |
| `tests/` | pytest suite: API-surface pinning, discovery accounting, persistence |
| `Procfile`, `railway.json` | Railway deploy config |
| `config.example` | Template to copy to `.env` |

`bot_engine.py` ships 10 default hashtags (`lasvegasfood`, `vegaseats`, `lasvegasdining`,
`lasvegasrestaurants`, `vegasfoodie`, `vegasfood`, `lasvegaseats`, `vegasrestaurants`,
`lasvegasfoodie`, `vegasdining`) and 6 default locations (Las Vegas Strip, Downtown Las Vegas,
Las Vegas, Bellagio, MGM Grand, Caesars Palace). **The locations list is never used** — 
`discover_content()` accepts a `locations` argument and then only iterates hashtags.

Sessions persist to `{session_name}_session.json` (default `lasvegas_restaurants_session.json`)
so restarts reuse a login instead of re-authenticating.

### 2.3 Data model

SQLite via SQLAlchemy. Default path `lasvegas_restaurants.db`.

| Table | Key columns |
|---|---|
| `creators` | `username` (unique), `instagram_pk` (unique), follower/following/media counts, `avg_engagement`, `status` |
| `media_items` | `original_media_pk` (unique), `code`, `creator_id` FK, `media_type`, `file_path`, caption, like/comment/view counts, `status`, `date_discovered`, `date_published`, `error_message` |
| `app_settings` | `key`/`value` pairs |
| `post_logs` | `media_id`, `posted_at`, `story_id`, `success`, `error_message` — written on publish success and failure |

**Status enums:**

- `CreatorStatus`: `new`, `approved`, `blocked`
- `MediaStatus`: `discovered`, `pending_approval`, `processing`, `ready`, `published`, `failed`,
  `rejected`

Note `discovered` and `ready` are defined but never assigned — discovery writes rows straight to
`pending_approval`, and publish goes `processing` → `published`/`failed`.

### 2.4 Configuration

| Setting | Default | Read from |
|---|---|---|
| `INSTAGRAM_USERNAME` / `INSTAGRAM_PASSWORD` | — | env (worker); typed into the form (dashboard) |
| `HASHTAGS` | `lasvegasfood,vegaseats,lasvegasdining,vegasfoodie` | env (worker only) |
| `SCAN_INTERVAL_HOURS` | 6 | env (worker only) |
| `AUTO_APPROVE` | false | env (worker only) |
| `MIN_FOLLOWERS` | 1000 | `create_bot()` config dict / dashboard Settings |
| `MIN_ENGAGEMENT_RATE` | 2.0 (%) | `create_bot()` config dict / dashboard Settings |
| `MAX_RESULTS_PER_HASHTAG` | 20 | `create_bot()` config dict |
| `DAILY_ACTION_LIMIT` | 50 | `create_bot()` config dict / dashboard Settings |
| `RATE_LIMIT_DELAY` | 30s | attribute; dashboard Settings |

`DATABASE_URL` overrides everything and is **required in production** so the worker and dashboard
share one database. `DATABASE_PATH` is the SQLite fallback used only when `DATABASE_URL` is unset.
`DOWNLOADS_DIR` and `PROCESSED_DIR` are still listed in `config.example` but read by nothing —
those paths remain hardcoded defaults.

Between discovered items the engine sleeps `random.uniform(2, 5)` seconds. The `rate_limit_delay`
attribute (30s) is settable from the dashboard but never consumed.

### 2.5 Deployment as documented

Two components, per DEPLOYMENT_GUIDE.md:

0. **Postgres → Railway.** Provision it first and set the same `DATABASE_URL` on both components
   below. Without this they cannot see each other's data.
1. **Dashboard → Streamlit Cloud.** Main file path `dashboard.py`. Secrets as top-level TOML keys.
2. **Worker → Railway.** Root directory is the repo root. Env vars per §2.4.
   `railway.json` sets `startCommand: python bot_worker.py`.

Documented cost: Streamlit Cloud free + Railway Hobby ≈ **$5–10/month**.

### 2.6 Known issues — fixed 2026-07-24

Everything in this section was verified against **instagrapi 2.18.9** and fixed on branch
`claude/master-file-e6ofy0`. Kept here because the failure modes are worth recognising if they
recur.

#### Blocker A — dashboard and worker never shared a database *(fixed)*

`init_database()` opened a **local SQLite file**. The Railway worker and the Streamlit dashboard
run on **different hosts with ephemeral disks**, so each created its own
`lasvegas_restaurants.db`. The worker's discoveries were invisible to the dashboard, and a
redeploy wiped the file. The review-and-approve workflow could not work as deployed.

`init_database()` now honours **`DATABASE_URL`**, rewriting Railway/Heroku's `postgres://` to the
`postgresql://` scheme SQLAlchemy requires, and falls back to SQLite only when it is unset. No
model changes were needed. **Deployment now requires provisioning Postgres and setting the same
`DATABASE_URL` on both components** — DEPLOYMENT_GUIDE.md Step 3.2.

#### Blocker B — three instagrapi methods did not exist *(fixed)*

| Location | Was | Now |
|---|---|---|
| `bot_engine.py` discovery | `client.hashtag_medias(...)` | `client.hashtag_medias_recent(...)` |
| `bot_engine.py` download, `video_utils.py` | `client.media_download(pk, path)` | `client.video_download(pk, folder=...)` — takes a **folder** and returns the path written |
| `bot_engine.py` publish | `client.story_upload(...)` | `client.video_upload_to_story(...)` — returns a `Story`, so `story_id` now reads `story.pk` |

The hashtag one was the most damaging because of how it failed. `discover_content()` wraps each
hashtag in a broad `except Exception` that logs and continues, so **every scan raised
`AttributeError`, swallowed it, and returned 0 items.** Railway logs read "Discovered 0 new items"
and looked healthy while nothing had ever worked.

> That broad `except` is still there. It is load-bearing for network flakiness, but it will hide
> the next programming error just as effectively.

#### Blocker C — engagement filter could never pass *(fixed)*

`get_engagement_rate()` called `user_medias(username, ...)`, but the parameter is `user_id` (a
numeric pk). The call raised, the handler returned `0`, and every creator was then rejected by the
`min_engagement_rate >= 2.0` check. **Even with Blocker B fixed, discovery would still have
yielded nothing.**

It now takes an optional pre-fetched `user_info` and uses `user_info['pk']`. Discovery passes the
profile it already fetched, which also removes a redundant API call per candidate — worth having
where rate limiting is the binding constraint.

#### Other bugs *(fixed)*

| Was | Now |
|---|---|
| `','.join([m.tag for h in media.usertags])` — binds `h`, uses undefined `m` → `NameError` | `t.user.username for t in (media.usertags or [])`. `Usertag` exposes `.user`, never `.tag` |
| `hashtags` column written from `media.hashtags` | **`Media` has no `hashtags` field at all**, so `hasattr` was always False and the column was always empty. Now parsed from `caption_text` via `extract_hashtags()` |
| `st.run("dashboard.py")` in `main.py` — not a Streamlit function | `subprocess.run([sys.executable, "-m", "streamlit", "run", ...])` |
| `actions_today` in memory; `reset_daily_counter()` never called | Persisted in `app_settings` with a date stamp, so the 50/day cap survives restarts and rolls over on its own |
| `Query.get()` — legacy in SQLAlchemy 2.0 | `session.get(Model, id)` |
| `declarative_base` from `sqlalchemy.ext.declarative` — moved in 2.0 | imported from `sqlalchemy.orm` |
| `PostLog` created but never written | Written on both publish success and failure |

#### Documentation and deploy mismatches *(fixed)*

`lvfc_bot/` does not exist and never did — all files are at the repo root. Every `cd lvfc_bot`,
the README project-structure block, the Streamlit main-file path, and the Railway root directory
referenced it. All corrected.

Also fixed: the Streamlit secrets example used a `[secrets]` TOML header, which nests keys at
`st.secrets["secrets"]` where nothing looks for them. Keys are now top-level, and `dashboard.py`
actually reads them (it previously read neither secrets nor environment, so the documented
secrets did nothing and login was always manual). `Procfile` declared a `bot:` process type that
nothing starts; it is now `worker:`, with an explicit `startCommand` in `railway.json`.

#### Hardening added 2026-07-24

Three follow-ups, done after the fixes above.

**Failures are now visible.** The root problem was never the three wrong method
names — it was that a broken scan and an empty scan produced identical output.
`discover_content()` now re-raises `BUG_EXCEPTIONS` (`AttributeError`, `TypeError`,
`NameError`, `ImportError`, `IndexError`, `KeyError`) instead of logging them as
Instagram's fault, and swallows only genuine network and API errors. The same split
was applied to `get_user_info()` and `get_engagement_rate()`, which had the same
flaw. Every filter stage now counts its rejections, exposed on
`bot.last_discovery_stats` and rendered in the dashboard, so "0 accepted" always
comes with a reason. Two cases log a warning: zero candidates from any hashtag
(the alarming one), and candidates arriving but none passing (filters too tight).

**A test suite that pins the API.** `test_dashboard.cjs` was deleted — it hardcoded
`/workspace/lvfc_bot` and used ESM `import` in a `.cjs` file, so it had never run.
In its place, 48 pytest tests. The highest-value file is
`tests/test_api_surface.py`, which asserts every `client.X()` call resolves against
the installed instagrapi and that the three phantom methods stay gone. All the
tests were mutation-checked: reverting each fix was confirmed to turn the
corresponding test red.

**The Instagram session persists in the database.** It was written to
`{session_name}_session.json` in the working directory, which Railway discards on
every redeploy — so the bot logged in cold each deploy, and repeated fresh logins
from a datacenter IP invite a challenge. `save_session()`/`load_session()` now use
`app_settings`, falling back to a file when there is no database, and migrating an
existing file into the database on first load.

#### Still open

- `DEFAULT_LOCATIONS` and the `locations` parameter of `discover_content()` are accepted and
  ignored — only hashtags are scanned. Either implement location scanning or drop the parameter.
- `rate_limit_delay` (30s) is settable from the dashboard but never consumed; the real pacing is a
  hardcoded `random.uniform(2, 5)` between items.
- `MediaStatus.DISCOVERED` and `.READY` are defined but never assigned.
- `.docx` and `.pdf` copies of both guides are committed alongside the `.md` originals and still
  carry the old errors. They will keep drifting — treat the Markdown as authoritative, or drop
  the binaries.
- Nothing has been run against live Instagram credentials. The fixes are verified by 48 tests
  and by checking every call site against instagrapi, not by a real discovery run.
- `rate_limit_delay` is still unwired, and permission to repost is still not tracked as data —
  see §3 items 4 and 5.

## §3 Consolidated open items

Ordered by cost of leaving it broken.

1. **LVFC needs Postgres provisioned and a live run.** The code blockers are fixed and verified
   (§2.6), but nothing has been exercised against real Instagram credentials. Provision Railway
   Postgres, set `DATABASE_URL` on both components, then watch one discovery cycle. The tell that
   it is genuinely working is a non-zero "Discovered N new items" — the old failure mode reported
   zero while looking healthy.
2. **Advertisers: 8 ghost records** (§1.6). Needs an owner decision — unhide or purge — before
   they cause a num collision.
3. **Dashboard audit is unfinished** (§1.6). Remaining: runtime view-sweep in READ-ONLY preview
   across all views, targeting 0 console errors, then the improvement list.
4. **Badge Trading DNS** (§1.8) is blocked on the owner's Porkbun changes. Nothing ships until
   those records land.
5. **Torch Dating canonical URLs** (§1.9) — confirm whether torch.dating or torchdating.com was
   registered, then align canonical/OG/JSON-LD.
6. **Brandon's `GUEST10_NUMS` is empty** (§1.4), so he sees the first 10 restaurants by num. If
   he should see a curated 10, fill the array.
7. **This repo is public.** It holds Instagram automation code for a live account. Consider making
   it private — that would also let this master file carry real PINs and make it genuinely
   cold-start complete.
8. **Smaller LVFC cleanups** are listed at the end of §2.6 (unused `locations` parameter, unused
   `rate_limit_delay`, unassigned status enums, stale `.docx`/`.pdf` doc copies).
