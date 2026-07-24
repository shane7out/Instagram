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
  - [2.6 Known issues — verified](#26-known-issues--verified)
- [§3 Consolidated open items](#3-consolidated-open-items)

---

## §0 The operation at a glance

One owner, one Mac, several small tools. Two entirely separate technology stacks:

| Stack | Tech | Hosting | Data store | Covered in |
|---|---|---|---|---|
| Web properties | Single-file HTML apps | Firebase Hosting | Shared Firebase RTDB | §1 |
| Instagram automation (LVFC) | Python | Streamlit Cloud + Railway | Local SQLite | §2 |

The two stacks do not talk to each other today. That matters — see
[§3 item 1](#3-consolidated-open-items), because the RTDB in §1 is a ready-made fix for the
database problem in §2.

### 0.1 Properties

| Property | URL | Status |
|---|---|---|
| LVR Dashboard | lvr-data-a60c1.web.app | Live, v438 |
| ALS (containers) | the-atl.web.app | Live |
| Badge Trading | badge-trading.web.app | Live; custom domain pending DNS |
| Torch Dating | lvr-data-a60c1.web.app/dating.html | Live, SPARK_V=53 |
| LVFC Instagram bot | this repo | Deployed, but see §2.6 |

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

**This flow does not currently work end to end.** See [§2.6](#26-known-issues--verified).

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
| `test_dashboard.cjs` | Node smoke test for the dashboard |
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
| `post_logs` | `media_id`, `posted_at`, `story_id`, `success`, `error_message` — **table is created but never written to** |

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

`config.example` also lists `DATABASE_PATH`, `DOWNLOADS_DIR`, `PROCESSED_DIR` — **none of these
three are actually read by any code.** Paths are hardcoded defaults.

Between discovered items the engine sleeps `random.uniform(2, 5)` seconds. The `rate_limit_delay`
attribute (30s) is settable from the dashboard but never consumed.

### 2.5 Deployment as documented

Two components, per DEPLOYMENT_GUIDE.md:

1. **Dashboard → Streamlit Cloud.** Main file path should be `dashboard.py` (the guide says
   `lvfc_bot/dashboard.py`, which is wrong).
2. **Worker → Railway.** Root directory should be the repo root (the guide says `lvfc_bot`).
   Env vars per §2.4. `Procfile` declares `bot: python bot_worker.py`.

Documented cost: Streamlit Cloud free + Railway Hobby ≈ **$5–10/month**.

### 2.6 Known issues — verified

Everything below was verified against **instagrapi 2.18.9** and by reading the source on
2026-07-24. Line numbers are from the current `claude/master-file-e6ofy0` tree.

#### Blocker A — the dashboard and the worker never share a database

`init_database()` opens a **local SQLite file**. The Railway worker and the Streamlit Cloud
dashboard run on **different hosts with ephemeral disks**, each creating its own
`lasvegas_restaurants.db`. The worker's discoveries are therefore invisible to the dashboard, and
a Railway redeploy wipes the file.

The review-and-approve workflow described in DEPLOYMENT_GUIDE.md **cannot work** in the deployed
topology, regardless of the API bugs below. Fixing this requires a shared store — Postgres on
Railway, or the Firebase RTDB the owner already operates (see §1.2).

#### Blocker B — three instagrapi methods do not exist

| Location | Call | Reality | Fix |
|---|---|---|---|
| `bot_engine.py:237` | `client.hashtag_medias(hashtag, amount=...)` | No such method | `hashtag_medias_recent(name, amount)` or `hashtag_medias_top(name, amount)` |
| `bot_engine.py:331`, `video_utils.py:30` | `client.media_download(pk, output_path)` | No such method | `video_download(media_pk: int, folder: Path)` — note it takes a **folder** and returns the written path, not a file path in |
| `bot_engine.py:365` | `client.story_upload(path, caption=...)` | No such method | `video_upload_to_story(path, caption=...)` — returns a `Story` object, not a bare id, so `publish_media()` currently stores the wrong thing in `story_id` |

The hashtag one is the most damaging because of how it fails. `discover_content()` wraps each
hashtag in a broad `except Exception` (`bot_engine.py:312`) that logs and continues, so **every
scan raises `AttributeError` per hashtag, swallows it, and returns 0 items.** Railway logs look
healthy — "Discovered 0 new items" — while nothing has ever worked.

#### Blocker C — engagement filter can never pass

`bot_engine.py:177` calls `client.user_medias(username, amount=10)`, but the parameter is
`user_id` (a numeric pk), not a username. The call raises, the `except` at line 203 returns `0`,
and every creator is then rejected by the `min_engagement_rate >= 2.0` check at line 272.

**Even with Blocker B fixed, discovery would still yield nothing.** Resolve the username to
`user_info['pk']` (already fetched) and pass that.

#### Other bugs

| Location | Issue |
|---|---|
| `bot_engine.py:298` | `','.join([m.tag for h in media.usertags])` — loop binds `h`, expression uses undefined `m` → `NameError`. Also `usertags` items are `UserTag` objects exposing `.user`, not `.tag` |
| `main.py:35` | `st.run("dashboard.py")` — Streamlit has no `run()`. Bare `python main.py` prints instructions then crashes |
| `bot_engine.py:76`, `472` | `actions_today` is in-memory only. `reset_daily_counter()` is never called by any scheduler, and a worker restart zeroes it — the 50/day cap is **not** enforced across restarts |
| `bot_engine.py:404`, `410`, `429` | `Query.get()` is legacy in SQLAlchemy 2.0 (which `requirements.txt` pins). Use `session.get(Model, id)` |
| `database_models.py:96` | `PostLog` is created but never written; `publish_media()` doesn't log to it |
| `bot_engine.py:54` | `DEFAULT_LOCATIONS` and the `locations` parameter are accepted and ignored |

#### Documentation and deploy mismatches

| Where | Says | Should say |
|---|---|---|
| README.md — Project Structure, and every `cd lvfc_bot` | Files live under `lvfc_bot/` | Files are at the repo root |
| DEPLOYMENT_GUIDE.md §2.2 | Main file path `lvfc_bot/dashboard.py` | `dashboard.py` |
| DEPLOYMENT_GUIDE.md §3.3 | Root directory `lvfc_bot` | Repo root |
| DEPLOYMENT_GUIDE.md §2.3 | Secrets under a `[secrets]` TOML header | Top-level keys — a header nests them at `st.secrets["secrets"]`. Moot regardless: **`dashboard.py` never reads `st.secrets` or env vars at all**, so Streamlit secrets are unused and login is always manual |
| `Procfile` | `bot: python bot_worker.py` | A `bot:` process type is not auto-started; Railway needs `web:` or an explicit start command. `railway.json` sets no `startCommand` |

`.docx` and `.pdf` copies of README and DEPLOYMENT_GUIDE are committed alongside the `.md`
originals. They carry the same errors and will drift — treat the Markdown as authoritative.

---

## §3 Consolidated open items

Ordered by cost of leaving it broken.

1. **LVFC is non-functional in production.** Blockers A, B, and C in §2.6 each independently
   prevent the pipeline from working. Fixing B and C is a small patch; A is an architecture
   decision. Cheapest path given what's already running: point LVFC at the shared Firebase RTDB
   from §1.2 instead of SQLite.
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
