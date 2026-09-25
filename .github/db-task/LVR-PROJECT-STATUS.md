# LVR Project Status — hand this to Claude if you start a new session

Repo: `shane7out/Instagram` (public — never commit real PINs/card numbers)
Working branch: `claude/master-file-e6ofy0`
Last updated: 2026-09-25

This file exists so a brand-new Claude session can pick up exactly where things
stand without re-discovering everything from scratch. Paste this whole file in
first if you're starting fresh.

---

## 1. How this whole system works

There is no local machine access. Everything that touches the live database or
the live sites goes through one of two paths:

**A. Firebase reads/writes (adding to the database, checking data, running
diagnostics)** — done by editing `.github/db-task/task.sh` in this repo and
pushing to `claude/master-file-e6ofy0`. A GitHub Actions workflow
(`db-task.yml`) fires automatically whenever that file changes, runs it on a
GitHub-hosted runner (which *can* reach Firebase and the open internet, unlike
this session), and the result shows up in the Actions log. This is how every
database add in this conversation happened.

**B. Anything that requires deploying a *site*** (the dashboard, the Deals
site, the dating site) **must be run on the Mac** — Firebase Hosting deploys
need the owner's Google login, which only exists there. The pattern is always
the same: a `patch-*.js` script makes marker-fenced, idempotent edits to the
live HTML file; a `deploy-*.sh` script downloads the patcher(s) from this
repo's raw GitHub URL, runs them, syntax-checks every inline `<script>` block,
deploys, verifies against the live site, and restores a backup + refuses to
deploy if anything failed. Every one of these has already been written,
tested against a local copy of the real live file, and pushed — see the
action items below for the exact one-line commands.

---

## 2. Live sites

| Site | URL | What it is |
|---|---|---|
| Owner dashboard | `lvr-data-a60c1.web.app` | PIN-gated master CRM/outreach dashboard |
| Deals | `classiccarsforsale-co.web.app` | Craigslist deal finder (cars, land, houses, RVs) |
| Dating (Torch clone) | `lvr-data-a60c1.web.app/dating.html` | Demo dating-app swipe interface |
| Credit cards | `lvr-cc.web.app` | Encrypted card/debt tracker |
| Badges | `lvr-data-a60c1.web.app/badges.html` | Badge trading |
| Firebase RTDB | `https://lvr-data-a60c1-default-rtdb.firebaseio.com` | The database behind all of the above |

---

## 3. ⚠️ ACTION ITEMS — Mac commands not yet run

These are real, tested fixes sitting in the repo, waiting on you to run them.
Nothing below has shipped to the live sites yet.

### Dashboard — four patches, one command
Fixes 23 CRM bugs (data-loss on import, dead buttons from a string/number id
bug, missing export columns, stale "lapsed" counting), brings back the
Outreach/Staging tab row (restaurant staging queue — the seeded 487 were all
already worked through; this makes the queue fillable again), and adds the
"suggested Instagram handle" review strip to Bad IG cards (25 handles are
already sitting in the queue, found this session — see §5).

```
curl -sL -o /tmp/dash.sh https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/deploy-dashboard-patches.sh && bash /tmp/dash.sh
```

### Dating site — skip sign-up, land on swipe instantly
When there's no saved profile (new browser/phone/private mode), the site now
silently creates a default one and goes straight to Discover instead of
showing the sign-up form. Verified against the site's own filtering logic in
a Node harness before shipping.

```
curl -sL -o /tmp/date.sh https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/deploy-dating-instant-swipe.sh && bash /tmp/date.sh
```

### Deals site — the big one: it's been stale for 75 days
`cars.json` has 669 entries and **every single one is stamped `added:
2026-07-07`** — nothing has been scraped since. The GitHub Action that runs
every few hours only sweeps the *existing* page for dead links (that's why
the clock in the corner always looks current) — it does not re-scrape
Craigslist. The real scrape (`gen.js` + `rest-deploy.js`) runs on the Mac via
a LaunchAgent that's supposed to auto-cycle every 6 hours, and it's stopped
(most likely: the Mac hasn't been on/logged-in enough). This reinstalls the
agent and forces one full scrape+deploy immediately:

```
curl -sL -o /tmp/setup.sh https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/setup-deals-auto.sh && bash /tmp/setup.sh
```

If after running this the listings still come back stamped with today's date
but there are way fewer of them than before, Craigslist may be blocking the
scraper — that's a follow-up debugging conversation, not something the script
above can fix on its own.

### Also still pending from earlier (lower priority)
- `deploy-sites-pill.sh` — adds an "All Sites" pill to the dashboard. Never run.
- `deploy-st-ritas-pill.sh` — **do not run.** St Rita's Retreat was cancelled:
  the retreat center said they don't want the site built. It's parked, not
  deleted, in case that changes.

---

## 4. Database snapshot (as of this session)

Main nodes in the Firebase RTDB, all under the root:

| Node | What it holds | Approx. count |
|---|---|---|
| `dashboard_crec` | Restaurants/bars/cafes | 818 |
| `dashboard/customrecords` | Mirror/array form of the same restaurant records | ~1,249 |
| `dashboard_exp_crec` | Experiences — nightclubs, shows, hotels, attractions, comedy clubs | 29 |
| `dashboard_adv_crec` | Advertisers (non-food businesses) | 541 |
| `dashboard_infl_crec` | Influencers | 74 |
| `dashboard/badig` | Records flagged as having a bad/missing Instagram handle | 235 |
| `dashboard/igsuggest` | **New this session** — suggested handle fixes for Bad IG records, waiting for the dashboard patch above to become visible/actionable | 25 |
| `dashboard/deleted` | Tombstoned record numbers (soft-deletes) | 816 |
| `dashboard_rest_stg_crec` | **New this session** — Firebase-backed restaurant staging queue (empty until you push something in) | 0 |

**Categorization rule** (for anything added from a screenshot going forward):
restaurants/bars/cafes → `dashboard_crec`; nightclubs/shows/hotels/attractions
→ `dashboard_exp_crec`; non-food businesses → `dashboard_adv_crec`;
influencers → `dashboard_infl_crec`.

**Standing rule for the Yelp/IG migration:** if a business isn't in the
database, add it. IG-profile screenshots get the handle attached directly (no
Bad IG flag). Duplicates across categories are fine — "just ignore them."

---

## 5. What got fixed/found this session (all verified, not just claimed)

- **5 real duplicate database records found and deleted** (via
  `dashboard/deleted`, the app's own soft-delete — not a raw rewrite). An
  earlier "707 duplicates" estimate was wrong — it was double-counting the
  same record stored in two mirrored nodes. The real number, collapsed
  correctly, was 5: Area 15, Shook Shakery, CC Speakeasy, Oodle Noodle, VIVA!.
- **Restaurant staging queue misunderstanding corrected**: it is NOT sitting
  on 487 ready restaurants — those 487 seeded ones were all already worked
  through and dismissed. The queue is genuinely empty right now; the fix
  above makes it fillable again going forward.
- **25 Instagram handle corrections found and queued** for Bad IG records —
  mostly one-character typos (`@korehouselv` → `@koreahouselv`, doubled
  letters, missing suffixes) found via web search and cross-checked against
  each business's own site or Yelp listing. ~11 of the 142 flagged records
  turned out to already have the *correct* handle — the flag itself was
  stale.
- **Deals site diagnosed**: not broken, just fed nothing new since July 7 (see
  §3). The 30-day auto-hide rule you asked for earlier is working exactly as
  designed — there's just nothing left within 30 days to show.
- **Dating site's forced sign-up screen fixed** (pending Mac deploy, see §3).
- **New businesses added to the database this session** (all confirmed live):
  Santa Fe Station, Sofra Taverna, Maiz Mama, @_beasley_02 (influencer),
  Mom's Basement Theatre, The Irish Spot, Liquid Diet. (Taps & Barrels
  Beerhouse was already in the database from before — found, not re-added.)

---

## 6. Parked / cancelled

- **St Rita's Retreat website** — fully built (light palette, Catholic
  branding, real photos and videos sourced from their own site), but the
  retreat center told the owner they don't want it built. Do not revive
  without the owner explicitly saying to.

---

## 7. Key file locations in the repo

- `.github/db-task/task.sh` — the "remote hands" script; edit + push to run
  something against Firebase or fetch/diagnose something live.
- `.github/db-task/mac/*.sh` — one-shot deploy scripts, run manually on the Mac.
- `.github/db-task/mac/patch-*.js` — the idempotent, marker-fenced patchers
  each deploy script applies.
- `.github/db-task/fetched/` — snapshots pulled down during diagnosis (live
  HTML copies, JSON dumps) — useful for re-reading what was actually checked.
- `.github/db-task/backups/` — timestamped Firebase node backups taken before
  any destructive-looking operation (e.g. the duplicate cleanup).

---

## 8. ⚠️ OPEN SECURITY ITEM — logged 2026-09-25, deliberately not fixed yet

The LVR Firebase RTDB (`lvr-data-a60c1-default-rtdb.firebaseio.com`) has **no
authentication on its security rules.** Confirmed directly: a raw unauthenticated
`PUT` to a scratch key from the GitHub Actions runner returned HTTP 200. Anyone
who has the database URL — which sits in plain text in the dashboard's own page
source — can read, write, or delete every node in this database with no PIN,
no login, nothing. The dashboard's PIN screen only gates the app's UI, not the
data behind it.

The owner has explicitly said: this is a real, live problem with everything
already sitting in the LVR database today, not just a reason to keep other
projects away from it — and he wants it scoped and fixed as its own dedicated
session, not folded into whatever else is happening. **Do not attempt to fix
this opportunistically inside an unrelated task.**

Whoever picks this up should know going in: every existing automation in this
repo (`task.sh`, every `mac/deploy-*.sh` script) currently works specifically
*because* there's no auth — they all do raw unauthenticated REST calls from a
GitHub Actions runner or a browser session. Locking down the rules will break
all of them until they're updated to authenticate (e.g. a service account for
the GitHub Actions side, the owner's existing Google login for the dashboard
side). That redesign is the actual scope of the fix, not just flipping the
rules.

---

## 9. Sibling project: The Table — separate from LVR entirely

The owner is building a second, unrelated product: **The Table**, a ticketed
communal-dining business (one table, one restaurant, strangers book individual
seats, phones away, family-style meal). Full spec was handed off 2026-09-25 as
`HANDOFF.md`.

**This is explicitly and permanently separate from everything above:**
its own Firebase project, its own GitHub repo, its own database. Nothing about
it touches `shane7out/Instagram`, the LVR RTDB, or any of the sites in §2 — the
only thing the two projects share is the brand name in a footer. Do not reuse
LVR's Firebase project, credentials, or database for any part of The Table, and
do not treat item §8 above as blocking it — they're unrelated by design.

Status as of 2026-09-25: static front end (HTML/CSS/vanilla JS, no build step,
Leaflet vendored) is built and working, being sent over as a zip. Backend
(Firestore, Cloud Functions, Stripe Checkout) not started. Build order per the
handoff: Firestore schema + security rules → wire front end read-only →
`holdSeat` + Stripe test mode, don't proceed past the double-booking race-
condition test → `stripeWebhook` → scheduled functions → transfers → waitlist
→ admin page. The dietary-notes field is safety-critical (family-style
service, guests never order for themselves) and must never be dropped,
truncated, or buried — surfaced prominently in the 72-hour pre-event email.

---

*If you're a new Claude session reading this cold: read this whole file, then
ask the owner what they want to work on next rather than re-diagnosing
everything above from zero — it's all still accurate as of the date at the
top unless they tell you otherwise.*
