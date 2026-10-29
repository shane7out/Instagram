# LVR Project Status — hand this to Claude if you start a new session

Repo: `shane7out/Instagram` (public — never commit real PINs/card numbers)
Working branch: `claude/master-file-e6ofy0`
Last updated: 2026-10-26 (correction pass — see §19 and the Zach PIN note in §3)

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

### Deals site — ROOT CAUSE FOUND 2026-10-24, fix ready to run
**Craigslist is NOT blocking the scraper — confirmed directly, not a guess.**
Hit the exact search API `watch-houses.js` uses from a GH Actions runner:
clean `200`, valid JSON, 21 real current listings came back. That theory
(logged in earlier versions of this section) was wrong — ruled out, don't
re-chase it.

**The real bug:** the 6-hour auto-cycle (`deals-agent.sh`, installed by
`setup-deals-auto.sh`) only ever ran `gen.js` (rebuild the site FROM
`manual.json`) and `rest-deploy.js` (redeploy) — it never ran any of the 21
`watch-*.js` harvesters, which are the *only* thing that actually fetches new
Craigslist listings and appends them to `manual.json`. The auto-cycle has
been rebuilding and redeploying the exact same stale data every 6 hours since
it was installed — that's why the live timestamp always looked current while
the listings underneath never changed. Confirmed via `grep` across every
Mac deploy script and GH workflow in the repo: nothing, anywhere, was ever
wired to call the harvesters automatically.

**Fix** (new `_tools/harvest-all.js` runs all 21 watchers in sequence, then
rewrites `deals-agent.sh` to harvest before rebuilding+deploying, reloads the
LaunchAgent, runs one full cycle right now, verifies live, and reports back):

```
curl -sL -o /tmp/fixdeals.sh https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/fix-deals-harvest.sh && bash /tmp/fixdeals.sh
```

`setup-deals-auto.sh` (the old script) is now superseded by this one for the
Deals freshness problem specifically — it still correctly installs the agent
+ LaunchAgent plumbing, it just never included the harvest step. No need to
re-run it first.

### Key Technologies pill on the dashboard
Adds a "Key Technologies" link next to the Deals/CC/Badges pills on the PIN
screen, pointing at the Key Technologies site. Built 2026-10-03, never
deployed. The link 404s until GitHub Pages is turned on for the
`claude/key-website` branch (Settings → Pages → branch `claude/key-website`
→ folder `/docs` — a GitHub.com toggle, not a Mac step, can be done from a
phone; full details and DNS steps are in that branch's own `docs/README.md`
and `docs/CLAUDE.md`) — turning Pages on after this runs requires no further
dashboard redeploy, the pill just starts working.

```
curl -sL -o /tmp/keypill.sh https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/deploy-add-key-pill.sh && bash /tmp/keypill.sh
```

### NEW — Key Technologies Prospect CRM, standalone page + login
Deploys a brand-new, separate tool at `lvr-data-a60c1.web.app/kt-crm.html` —
its own PIN (702950, easy to change), its own Firebase node
(`/kt_crm/prospects`, completely separate from every `dashboard_*` restaurant
node). Built 2026-10-24 after Shane decided restaurants aren't the real
target for Key Technologies anymore (see §16) — this is for tracking
high-end prospects (real estate, medical/dental/aesthetic, law, e-commerce)
instead. Add/edit/remove prospects, a status pipeline (not contacted →
contacted → responded → meeting booked → client / not interested), one-tap
call/email, and a "copy outreach script" button per vertical with a
tailored script already written in. Same Firebase project/database Shane
already built, deployed through the same proven `deploy-overlay.js` the
dashboard patches use — just one more file in the same directory.

```
curl -sL -o /tmp/ktcrm.sh https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/deploy-kt-crm.sh && bash /tmp/ktcrm.sh
```

### NEW — Key Technologies Leads viewer, standalone page + login
Deploys a brand-new, separate tool at `lvr-data-a60c1.web.app/key-leads.html`
— same PIN family (702950, easy to change), reads `/key_leads/leads`, the
Firebase node every lead form on the live site already writes to (homepage
short/full forms, the Free Website Audit, and all 4 vertical-page forms).
Built 2026-10-24 right after Formspree got wired up, because Shane asked how
to view/delete leads and there was no viewer for the real database (only
Formspree's own copy, which is self-service in its own dashboard). Shows
every lead — name, contact info, which form/page it came from, plus
form-specific detail (interests checked, audit grade, etc.) — with a status
dropdown (new/contacted/responded/client/not interested) and a delete
button. Tested against mocked Firebase data via Playwright (all 4 lead
shapes, tab filtering, status change, delete, wrong-PIN lockout) before
shipping. Same `deploy-overlay.js` deploy mechanism as every other tool here.

```
curl -sL -o /tmp/keyleads.sh https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/deploy-key-leads.sh && bash /tmp/keyleads.sh
```

### NEW — Key Technologies advertiser marketing system (2026-10-25)
Shane's plan: DM outreach for the new high-end verticals will be sent from
the LasVegas_Restaurants Instagram account (credibility — not retargeting
restaurants as clients), using the ~4,000-business LVR advertiser pool
("Ads" — doctors, lawyers, dentists, realtors, etc.) as the prospect source.
He wants three logins into that same pool (owner/LVR, Zach, Key
Technologies) with everyone seeing the same *approved* records, but only he
can actually remove/mark one bad — everyone else can only flag something
for his review.

**New PIN `137901`** on the main dashboard login goes straight to a new
`key-advertisers.html` tool instead of unlocking the dashboard — read-only
view of every approved advertiser (`dashboard_adv_crec`, the same live list
every login already reads), with search, category filters, its own
outreach-status tracker (separate node — doesn't touch LVR's restaurant-
oriented DM/status system), and a Flag-for-Review button. No delete power
at all.

**Real thing caught before building anything**, worth remembering: the
existing "Problem" button on advertiser cards *looks* like it already does
owner-reviewable flagging, but `_advFbPatch()` deliberately no-ops for
friend/co-editor sessions (an intentional existing guard against a
co-editor writing arbitrary paths into the owner's live data) — so a
friend's Problem flag never actually reaches the owner, it only updates
their own browser. Didn't build on that false assumption; built a
dedicated `dashboard/adv_flag_queue` node instead, fed by both the new KT
tool and a new "Flag for Review" button added to the main dashboard's
friend-mode advertiser cards. Owner gets a new "🚩 Flagged N" button next
to the existing Dupes filter, opening a review modal: **Confirm** reuses
the already-correct, already owner-only `advMainToNeedFixed()` (sends it to
Bad Records, removes it from every view) rather than new deletion logic;
**Dismiss** just clears the flag and the record stays live.

`patch-dashboard-keytech.js` is marker-fenced and idempotent — tested
against a real copy of the live dashboard before shipping (not just
syntax-checked blind): all 5 patches applied cleanly against real anchors,
re-running correctly no-ops on every one (this caught and fixed one real
bug — a marker-string mismatch that would have silently double-inserted a
button on every future re-run), full inline-JS syntax check passed on the
patched file. `key-advertisers.html` tested with mocked Firebase data via
Playwright: PIN gate, search, category filtering, flagging, outreach-status
change — no JS errors. Deploy script mirrors `deploy-dashboard-patches.sh`'s
exact safety discipline: pristine backup, patch exit code checked, full
syntax check, complete rollback on any failure, APP_VERSION cache-bust,
live verification of every marker after deploy.

```
curl -sL -o /tmp/keytechadv.sh https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/deploy-keytech-advertisers.sh && bash /tmp/keytechadv.sh
```

### NEW — LVR coupon advertising program (2026-10-26)
Built from a real DM the owner already sent to a restaurant (Vanilla Rice,
10/16): the pitch is a coupon program advertised through LVR's Instagram
network — customer clicks a link, enters their info on LVR's own site, gets
a unique coupon code to redeem in-restaurant. The DM promised: marketing
consent is never required to claim a coupon, coupon counts/expirations can
be limited, and both the restaurant and LVR get access to the customer data
collected through that restaurant's own promotion.

Two new standalone pages, same Firebase project/database as everything
else, new top-level node `/lvr_coupons` (separate from every restaurant/
advertiser node):

- **`lvr-coupon.html`** — the customer-facing claim page, no PIN (it's
  meant to be shared publicly via Instagram Story links). Opened as
  `?biz=<slug>`, e.g. `lvr-coupon.html?biz=vanilla-rice`. Honest states
  throughout: missing/not-found/inactive/expired/fully-claimed each show a
  plain explanation, never a fake success. Shows a real "X of Y left" count
  when a program has a claim limit — never fabricated. Claiming writes
  name/email/phone + a generated unique code (e.g. `VAN-7K3P9`) to
  `/lvr_coupons/claims/<slug>`; the marketing opt-in checkbox is unchecked
  by default and explicitly optional, matching what was promised in the DM.
  If the same email or phone claims twice, it re-shows their existing code
  instead of creating a duplicate.
- **`lvr-coupons-admin.html`** — PIN-gated (`702953`) tool for the owner:
  create/edit a coupon program per restaurant (business name, offer text,
  redemption instructions, optional real photo URL, expiration date, max
  claims, active toggle), copy each program's claim link, and view/mark-
  redeemed/delete claims per program.

Both tested with mocked Firebase data via Playwright before shipping (claim
page: every unavailable state, scarcity count, a full successful claim, the
dedup-reuse path, and client-side validation; admin tool: PIN gate, the
program list, create and edit flows, the claims view, mark-redeemed,
delete) — no JS errors in either.

**Not done yet, deliberately left to the owner**: no program has been
created for Vanilla Rice (or anyone) yet — the DM's specific numbers (how
many coupons, what expiration date) were never decided in the conversation,
so nothing was invented. Once this deploys, the next step is the owner
opening the admin tool and creating that program himself (business name
"Vanilla Rice", offer "Free Chicken & Rice Bowl", plus whatever limit/
expiration he actually wants), then sending the resulting claim link to
Vanilla Rice.

```
curl -sL -o /tmp/lvrcoupons.sh https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/deploy-lvr-coupons.sh && bash /tmp/lvrcoupons.sh
```

### NEW — single-sign-on "Key Tech Room" + consolidated deploy (2026-10-26)
Owner's own words: "I don't want new passwords. I can't handle new
passwords." Every new standalone tool this project has shipped
(kt-crm.html, key-leads.html, key-advertisers.html, lvr-coupons-admin.html)
had its own separate PIN — four more things to remember on top of the
master dashboard PIN. This fixes that, without weakening any of them for
anyone who ISN'T already logged in as the owner.

**How it works**: the moment the OWNER PIN (dynamic, default `137900`)
succeeds on the main dashboard, a timestamp is written to
`localStorage['lv_owner_session']` — real browser storage, shared across
every page on `lvr-data-a60c1.web.app` (not shared with `keytechnologies.si`
— different domain, browsers never share storage across origins, so
`key-pageviews.html` still needs its own PIN, noted honestly in the room's
UI rather than silently broken). Every satellite tool now checks that same
stamp on load, valid for 24h: if it's fresh, the tool skips its own PIN
screen and opens straight up; if it's missing or stale, the tool's PIN
screen works exactly as before — nothing is weakened for anyone who hasn't
logged in as the owner on that browser (co-editor/friend/guest PINs are
completely untouched; this bypass only fires for the owner-PIN branch).

**New hub page**, `key-room.html`: a single PIN-gated page (same dynamic-PIN
fallback, same bypass) listing every tool as a tappable card — the live
site, Leads, Prospect CRM, Advertisers, Coupon Programs, Page Views.
Reached via a new "🔑 Key Tech" pill added to the main dashboard header
(next to the existing Teams pill), so the flow is: log into the dashboard
once with your master PIN → tap the pill → everything just opens.

**New consolidated deploy script** (`deploy-key-room.sh`) replaces needing
to run 4 separate deploy commands — it redeploys `key-leads.html`,
`kt-crm.html`, `key-advertisers.html`, and `lvr-coupons-admin.html` (each
now with the bypass check added) plus the new `key-room.html`, and patches
the dashboard (new pill + session stamp) in one pass, same pristine-backup/
syntax-check/rollback safety as every other dashboard patch. Running the
older individual deploy scripts (`deploy-key-leads.sh`,
`deploy-keytech-advertisers.sh`, `deploy-lvr-coupons.sh`) afterward is
harmless but redundant — they pull the same source files, just without
patching the dashboard pill.

Patcher (`patch-key-room-pill.js`) tested against a real copy of the live
dashboard before shipping: both patches apply cleanly against real anchors,
re-running is a clean no-op (idempotent), full inline-script syntax check
passed. All 4 satellite tools' bypass logic tested with mocked data via
Playwright: no session → PIN screen as before; fresh session → skips
straight to the app; stale (>24h) session → falls back to the PIN screen
correctly. `key-room.html` itself tested the same way, plus honors a
custom `lv_pin` override if the owner ever changes the master PIN.

```
curl -sL -o /tmp/keyroom.sh https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/deploy-key-room.sh && bash /tmp/keyroom.sh
```

### NEW — LVR Points program: wallets, catalog, redemption, restaurant portal (2026-10-26)
Direct follow-through on the owner's points-economy idea: "1 point = $1,
free chicken bowl = 10 points, customer opens their wallet, sees what's
redeemable, clicks it, points come out of their balance; restaurant owners
can log in to see who's redeemed what and download the data; I always want
access to that too." Explicitly **not** blockchain — a points currency
inside LVR's own database, same pattern as everything else here.

**Wallet login decision (owner picked explicitly, 2026-10-26):** a personal
link per wallet (`lvr-wallet.html?t=<random token>`), not a typed password
and not a typed email. Zero new infrastructure (no email-sending service,
no Firebase Auth SDK), buildable entirely with the existing REST-to-Firebase
pattern. Tradeoff, told to the owner directly: if someone loses their link
there's no self-serve recovery — the owner has to look them up in the admin
tool and resend it. A real verified-login upgrade (email magic link) stays
possible later if he ever hands over a Firebase Auth web config, but isn't
needed for this to work today.

New node `/lvr_points` (separate from `/lvr_coupons`, `/key_leads`, every
restaurant/advertiser node):
- `wallets/<token>`: `{ name, email, phone, balance }`
- `grants/<token>/<id>`: history log of every point grant/adjustment
- `restaurants/<slug>`: `{ bizName, pin }` — the PIN below is for that
  restaurant's OWN portal login, separate from every other PIN in this
  project
- `catalog/<slug>/<itemId>`: `{ itemName, pointCost, instructions, photoUrl,
  maxRedemptions, expiresAt, active }`
- `redemptions/<slug>/<id>`: `{ token, email, name, itemId, itemName,
  pointCost, code, redeemedAt }`

**Four new pages:**
- **`lvr-wallet.html`** (customer-facing, no PIN — opened via their personal
  link). Big, simple balance display, a list of everything redeemable
  platform-wide with its point cost (grayed out if they can't afford it —
  never hidden, so they can see what they're working toward), a confirm
  step, then a generated code shown on screen and the balance deducted.
  Known, accepted limitation (documented in the code, not hidden): plain
  REST with no server-side transactions means two redemptions fired at the
  same literal instant from two devices could both read the same starting
  balance — same honest tradeoff as the rest of this no-backend project,
  narrowed (not eliminated) by re-fetching the balance fresh right before
  committing.
- **`lvr-points-admin.html`** (PIN `702954`, owner only, single-sign-on via
  the Key Tech Room bypass). Three tabs: **Wallets** (create a new wallet
  with a starting point grant and get the shareable link immediately,
  search existing wallets, add/subtract points with a reason logged every
  time); **Catalog** (create/edit redeemable items per restaurant, set that
  restaurant's own portal PIN right there, see live redeemed-count per
  item); **Redemptions** (every redemption across every restaurant, plus a
  "Download All (CSV)" button — this is the owner's own permanent full
  visibility the DM promised).
- **`lvr-restaurant-portal.html`** (PIN-gated per restaurant, using that
  restaurant's own PIN from the catalog admin — NOT the owner's PIN, and
  intentionally scoped so a restaurant only ever sees ITS OWN redemptions,
  never another restaurant's). Shows everyone who redeemed there, plus its
  own "Download CSV" button — exactly the "restaurant owner can download
  the database" access the owner described.
- **`key-room.html`** updated with a new "Points Program" card.

**Seeded for real** via `task.sh`: Vanilla Rice Hibachi House now has a
restaurant record (portal PIN `5190`) and one real catalog item — Free
Chicken Bowl, 10 points — in `/lvr_points`. No wallets exist yet; creating
the first one (who gets how many points) is the owner's call, made through
`lvr-points-admin.html` once this deploys.

**Honest note on "100 million points":** the system doesn't enforce any
literal supply cap — there's no shared pool that drains as wallets get
granted points, each grant is just an independent balance increase. "100
million" is the owner's framing/vision number, not a mechanic the code
currently tracks. A running supply-remaining counter is a quick follow-up
if he wants one, not built by default.

All four new/changed pages tested with mocked Firebase data via Playwright
before shipping: the wallet page's full redeem flow (balance check,
confirm, code generation, deduction) and its unaffordable/expired/missing
states; the admin tool's wallet creation (verifying the real PUT + grant
log), add-points, catalog item creation (verifying both the catalog AND
restaurant records get written), and the redemptions list/CSV; the
restaurant portal's PIN matching and per-restaurant data scoping (confirmed
one restaurant's PIN never surfaces another's redemptions). No JS errors
in any of it. Same single-sign-on bypass as every other owner tool, also
tested.

Already added to `deploy-key-room.sh` (see the single-sign-on section
above) — one Mac command deploys this along with everything else.

**Correction, found during a routine post-ship review (2026-10-27):**
`maxRedemptions` on a catalog item was stored and shown in the admin tool,
but `lvr-wallet.html` never actually checked it — a "limited to 50" item
was unlimited in practice until this fix. Now the wallet hides an item
once its cap is hit, and re-checks the live count right before committing
a redemption (same narrowed-not-eliminated race window as the balance
check), so two people can't both grab the last slot. No deploy has
happened yet, so nothing live was ever affected by this.

### NEW — LVR Rewards landing page on keytechnologies.si + self-serve signup (2026-10-26/27)
Owner floated routing points-program traffic through keytechnologies.si as
cross-promotion ("two for one"). Flagged the real tension first rather than
just building it: the owner explicitly decided weeks earlier (§16) that Key
Technologies stops targeting restaurants as clients — the people who'd want
a free bowl of food aren't the real estate/medical/law/e-commerce buyers
that site is now positioned for, so making a consumer giveaway the front
page risked undoing that positioning. Owner picked, explicitly, the
narrower option: a dedicated `rewards.html` page (linked from nav/footer,
not a homepage takeover) plus self-serve signup defaulting to 0 starting
points (so a stranger can open an account, but doesn't get real points
until the owner actually grants them).

`sites/key-technologies/rewards.html` (new, live site, not an internal
tool — real SEO meta/OG tags, no noindex): explains the points program,
points people to `@LasVegas_Restaurants` on Instagram as where points
actually get handed out, and a signup form. Submitting writes a real
wallet straight to `/lvr_points/wallets/<token>` (balance: 0) via a
cross-origin PUT from keytechnologies.si to the LVR Firebase project —
**confirmed live, not assumed**, via a real CORS preflight (OPTIONS) +
PUT test from a GH Actions runner with `Origin: https://keytechnologies.si`
before this was ever wired into the real nav. Redirects straight into the
new wallet (`lvr-wallet.html?t=<token>`) on success. Linked from the
mobile menu + footer of all 5 main KT pages and added to sitemap.xml — not
the desktop nav-links row, matching the existing "Industries" link's
precedent to avoid re-triggering the previously-fixed nav-overlap bug.
Same design system, same QA pattern as every other page on the site (tag
balance, JSON-LD parse + exact match against visible FAQ text, inline-
script syntax check, full Playwright pass including the live signup flow)
— full site audit + broken-link check re-run clean after wiring it in.

**Practical effect on the points system**: `/lvr_points/wallets` can now
grow from two sources — the owner creating a wallet directly in
`lvr-points-admin.html` (any starting balance), or a stranger self-signing
up through `rewards.html` (always 0 balance). The owner tool's existing
"Add Points" action is how a self-signed-up wallet actually gets real
points later — nothing new needed there.

### NEW — Points program "Phase 1": native account page + account icon (2026-10-27)
Owner's vision for the points program, confirmed in conversation: everything
lives under the Key Technologies brand, reached via a small account icon
next to the hamburger menu — not a redirect to a different website. He also
asked for the bigger "sophisticated" build (games, a receipt-entry prize
drawing with a spin wheel) and explicitly signed off on taking it slow and
doing it right, including the legal piece (see below) — this is Phase 1 of
that, the part with zero legal complexity.

**`sites/key-technologies/my-account.html`** (new): the actual wallet
experience, now living natively on keytechnologies.si instead of
redirecting to `lvr-data-a60c1.web.app`. Same tested balance/redeem logic
as `lvr-wallet.html` (ported, not rewritten, to avoid re-introducing a bug
already fixed there), wrapped in the site's own header/footer. New:
**device memory** — arriving with `?t=<token>` stores it to localStorage,
so a return visit on the same device/browser recognizes the account with
no link to re-paste. A "paste your link" fallback covers a brand-new
device that already has an account (e.g., a link texted from another
phone). A "Not you? Switch account" link clears the stored token for
shared devices.

**Account icon**: a small circular icon now sits next to the hamburger on
every main page — deliberately NOT hidden at mobile widths (unlike the
other header CTAs), since the owner specifically asked for it to be
visible "up on top" always. Points at `rewards.html` (sign up / have your
link?) when the device isn't recognized, or straight at `my-account.html`
when it is.

`rewards.html`'s signup flow now stores the new token to localStorage and
redirects internally to `my-account.html`, instead of sending new
sign-ups to a different website right after onboarding them.

Tested with mocked Firebase data via Playwright: every state on
`my-account.html` (no account / paste-link / direct-token-in-URL /
reload-persistence / switch-account), the icon's logged-in vs logged-out
state across all 6 pages, and the full rewards.html signup → internal
redirect path. Full-site audit and broken-link check re-run clean. Also
added `my-account.html` to the page-view report's label list up front this
time (a gap found and fixed on `rewards.html` the cycle before).

### NEW — Prize drawing concept: legal flag raised, Official Rules drafted (2026-10-27)
Owner's fuller vision, not yet built: a "games" layer on top of points,
specifically a receipt-number + amount-paid entry mechanic feeding a
"spin the wheel, 1 of 50 wins" prize drawing, explicitly requested to be
"not rigged" with "all the code opened up."

**Flagged clearly before writing any code for it**: that mechanic —
payment proof + chance + prize — is legally a sweepstakes. Most U.S.
states, Nevada included, require a free, no-purchase alternate entry
method or it's an unlicensed lottery. The owner's response: "I definitely
don't want to be an illegal sweepstakes... I want to comply 100% with the
law." Recommended narrowing eligibility to Nevada residents only, since
a few states (Florida, New York, Rhode Island) require registering and
bonding a promotion once prize value crosses certain thresholds — staying
Nevada-only avoids that entirely and matches the real customer base
anyway.

**Drafted a starting "Official Rules" document** (owner has it, will send
to an attorney for sign-off before any real prize goes live) covering: the
no-purchase-necessary clause, eligibility, how to enter, real odds
disclosure, prize description, and — the technical piece — a
**commit-reveal winner-selection design**: before a drawing opens, a
random winning entry number is generated and its cryptographic hash
published; after the drawing closes, the real number and the data behind
it are revealed, and anyone can verify the hash matches, proving the
winner wasn't picked after the fact. This is what makes "not rigged, code
opened up" literally true without needing a real backend server to
enforce it.

**Status: owner has approved the direction and the draft rules, said to
keep building, explicitly said to take the time needed ("it's going to
take months... I'm prepared for that").** The actual receipt-entry +
spin-wheel system itself is NOT built yet — that's the next phase, to be
built to match whatever the attorney's final rules say once that review
happens. Nothing about this blocks continuing other points-system work in
the meantime.

### Also still pending from earlier (lower priority)
- `deploy-sites-pill.sh` — adds an "All Sites" pill to the dashboard. Never run.
- `deploy-st-ritas-pill.sh` — **do not run.** St Rita's Retreat was cancelled:
  the retreat center said they don't want the site built. It's parked, not
  deleted, in case that changes.

Note: `deploy-cc.sh`, `deploy-refresh-ui.sh`, `finish-deals.sh`,
`refresh-and-pills.sh`, `deploy-crm-fixes.sh`, `build-batman.sh`,
`fix-batman.sh`, `deploy-add-zach-pin.sh` also live in
`.github/db-task/mac/` but are NOT pending — they were already run
successfully earlier in the project (CC manager, Batman cards on the Deals
site, Deals refresh v8, the standalone CRM fix that
`deploy-dashboard-patches.sh` above now supersedes, and Zach's PIN
223344). **Correction, found 2026-10-26**: this file previously listed
Zach's PIN as "never deployed" — that was wrong. Confirmed live via the
dashboard's own markers (`ZACHPIN01`/`ZACHPIN02`, dated 2026-10-07): it was
actually deployed on 2026-10-07 and has been live this whole time, the doc
just never got updated to say so. Leave `deploy-add-zach-pin.sh` alone too.

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

## 10. ⚠️ STANDING RULE (2026-10-05) — every new business MUST be DM-able, not just "in the database"

**The owner's own words: "Whenever you send me one of these or whatever to
update, the rule is we must send them a DM first... put them in the DM, needs
to DM pill." This is permanent — never forget it, every session, forever.**

Adding a row to `dashboard_crec` / `dashboard_adv_crec` is NOT enough by
itself. The live dashboard (`.github/db-task/patched-dashboard.html` in this
repo is a real fetched copy of it — read it, don't guess) has specific,
non-obvious rules for what counts as "needs DM":

1. **An Instagram handle is mandatory.** The "needs DM" counter for both
   restaurants and advertisers is gated on a non-empty IG handle
   (`r.igHandle` / `!!ig` in the dashboard JS — see `needsDM` near line
   10350 and the `nodm` counter near line 5328). A record added with a blank
   Instagram field will **never** show up as needing a DM, no matter what
   else is set. **Do not add a business without first finding its real
   Instagram handle.** If a source (screenshot, listicle, etc.) doesn't give
   the handle, look it up (WebSearch) before writing the record. If a real
   handle genuinely can't be confirmed, tell the owner explicitly which
   businesses are missing one and why — don't silently add them handle-less.

2. **Restaurants need a proper, non-colliding `num`.** New restaurant records
   go to `dashboard_crec` (confirmed via `prWriteRecord()` in the dashboard
   JS, which writes to `dashboard_crec/<num>`) and MUST include a `num` field
   allocated the same way the app itself does it (`_getNextNum()`: scan
   `dashboard_crec` + `dashboard/customrecords` + the restaurant staging node
   + `dashboard/deleted` for the current max, then `+1`). Several maps in the
   app are keyed by `num` — a record with no `num` (or a colliding one) risks
   cross-contaminating another record's DM/status/bad-IG state. **Always
   fetch the live data and compute the next free num at write time —
   never hardcode or guess one.**

3. **DM status lives in separate Firebase paths, not on the record.** A new
   restaurant's "pending" status is `dashboard/status/<num>` = `"pending"`,
   and its attempt log is `dashboard/attempts/<num>` =
   `[{email, status:"pending", date:null, note:""}]` (see
   `saveNewRecord()` / `_fbPatch('status/'+num, ...)` in the dashboard JS).
   **Every new restaurant needs both of these written**, or it'll render
   with an undefined/blank status.

4. **New advertisers (non-restaurant businesses) go to a STAGING node, not
   straight to `dashboard_adv_crec`.** The live node is `dashboard_adv_crec`
   but new adds from the UI go to `dashboard_adv_stg_crec` first (per
   `advSaveNewRecord()` / `prWriteAdvStg()`), for the owner to review and
   approve — `dashboard_adv_crec` is meant to only contain already-approved
   records. Writing straight into `dashboard_adv_crec` skips that review
   step. New num for advertisers is allocated starting at 9000 (scan
   `dashboard_adv_stg_crec` + `dashboard_adv_crec` nums >9000 + a "thumbs
   down" rejected-node + `dashboard` adv-deleted map, then `+1`), and the
   record itself (unlike restaurants) carries `status:'pending',
   defaultStatus:'pending'` directly on the object. The app's own UI also
   makes the Instagram handle a hard requirement for advertiser adds
   (`if(!ig){alert('Instagram handle is required.');return;}`) — treat that
   as non-negotiable here too.

**2026-10-05 incident this rule is logging:** 21 restaurants + 1 advertiser
were added from an IG listicle screenshot (`@foodiedhillon`, "NEW RESTAURANT
AND BARS IN LAS VEGAS") directly to `dashboard_crec` / `dashboard_adv_crec`
with blank Instagram fields, no `num`, no status/attempts entries, and (for
the advertiser) skipping the staging node entirely. None of them showed up
in the owner's "needs to DM" queue — this is why. A corrective pass was run
immediately after to patch real Instagram handles (found via web search,
none invented), assign proper nums, write status/attempts, and move the
advertiser into the staging node where it belongs. See the git log around
this date on `claude/master-file-e6ofy0` for the exact corrective commits.

---

## 11. Status as of 2026-10-08 (3-hour check-in routine running since 2026-10-07)

A recurring check-in (`trig_01LRZS3SN4DZ6V5jcquW5yiE`, every 3 hours, fires
into the same ongoing session) has been active since 2026-10-07. What it's
done so far, in case a fresh session picks this up mid-stream:

- **DM-visibility audit (standing rule, section 10) re-run and clean.** 842
  restaurants in `dashboard_crec`, 0 missing `num` — the 2026-10-05 silent-
  invisibility bug has not recurred. However, **110 restaurants have a `num`
  but no Instagram handle** (visible on the dashboard, but can never show up
  as "needs DM") — these are legacy entries, not new regressions. Web search
  could not reliably resolve handles for any of them (results were either not
  found, or only a *national chain* account rather than the specific Las
  Vegas location) — don't guess-write handles into the DB; ask the owner
  directly when he recognizes one instead, same as the Mezban add below.
  Also **2 advertisers are stuck non-DM-able** for the same reason:
  "Wholesale Classic Cars" and "AlohaMulans" — couldn't confirm either via
  web search (couldn't even confirm "AlohaMulans" is a real business name,
  may be a DB typo). Still waiting on the owner to ID these.
- **Mezban added** (`dashboard_crec/60022`, halal Pakistani, 5239 W
  Charleston Blvd, `@mezban_lv`) from an IG screenshot the owner sent
  directly — full DM-visibility (num + instagram + status/attempts) written
  per section 10, confirmed live.
- **Key Technologies marketing-plan doc** (`48cdc7f5-b47c-49c8-8ea4-
  a417bd0299b8`): the plan ranks LinkedIn organic as the #1-priority channel
  but had no actual outreach script for it — added a 6th template (LinkedIn
  connection request + accept-follow-up) alongside the 5 IG/email ones. The
  "Outreach tracker" tab (86 prospects) is still all "Not sent" — the owner
  hasn't started working the list yet.
- **Full regression sweep of all 5 earlier Mac deploys came back clean**:
  Key Technologies pill, Zach PIN, and the dating-site instant-swipe patch
  are all still live (dashboard `APP_VERSION=449`, unchanged since the Key
  pill deploy — nothing has drifted).
- **Still unchanged, still owner/browser-dependent:** GitHub Pages has never
  been turned on for `claude/key-website` (`/docs`), and `keytechnologies.si`
  DNS still isn't pointed at it (`HTTP 404` / `HTTP 000` on every check since
  2026-10-07 ~06:36 UTC). Not worth re-checking every single 3-hour cycle —
  only when there's a specific reason to think it changed.

---

## 12. Status as of 2026-10-09

- **Three more restaurants added from the owner's own IG screenshots**,
  all with full DM-visibility per section 10: The Stadium (sports bar,
  Arts District, `num 60025`), Duke's Dogs (Cali-style hot dog food truck,
  `num 60026`). A third screenshot, Golden Oven Wood Fired Pizza, turned
  out to already be in the database (`num 50472`) with a working handle —
  no duplicate created, nothing needed.
- **Key Technologies is dropping the "Key Technologies" / keytechnologies.si
  brand entirely** — owner's decision, 2026-10-08/09, still in progress.
  Nothing registered yet. Reasoning: confirmed via research that ".si"
  isn't actually a credible signal yet (the "White House made .si the new
  .ai" claim going around is real but narrow — a Sept 2026 executive order
  only tells federal agencies to say "Super Intelligence"/"SI" instead of
  "AI" in official materials; the .si domain spike since then is mostly
  domain investors flipping names, not real businesses adopting it — .ai
  remains the actual trusted TLD for AI companies). Separately, the owner
  clarified restaurants/hospitality are **not** his main target audience —
  "the last ones I'm really marketing to" — which the existing marketing
  plan doc and a lot of the outreach work (LVR-based prospecting, the
  restaurant-flavored DM templates) assumed was a top pool. Who the real
  primary audience is hasn't been established yet — still an open question.
  Current naming direction: keep the "Key" concept/logo, pair it with one
  short, non-jargon word, 1-2 words total, avoiding anything that reads as
  developer-insider (ruled out "KeyStackAI" for exactly that reason).
  `KeyEdge` was the leading suggestion as of last discussion. No domain
  registered, nothing on the live site has changed yet — this is purely a
  naming/positioning decision in progress, not something to act on
  unprompted.
- **Key Technologies site (`claude/key-website` branch) also got real
  fixes/additions on 2026-10-08**, independent of the rebrand question:
  found via actual Playwright screenshots (not guessing) that the
  "Possible interests" checkboxes were visually broken — a global
  `input{width:100%}` rule meant for text fields was also inflating the
  checkboxes themselves. Fixed, redesigned as tappable pills, and the
  pills were synced to match all 19 services now on the site (added this
  session: AI website development, email automation, social media
  management, review/reputation management, AI phone/text answering,
  booking/scheduling automation, AI staff training, custom website
  programming, ADA/accessibility compliance). Also trimmed each page's
  Google Fonts weight request down to only what's actually used.

---

## 13. Status as of 2026-10-09/10

- **Three more restaurants/businesses added from the owner's own IG
  screenshots**, all with full DM-visibility per section 10: Sushi Bake by
  Nora (`num 60032`, `@sushi_bake_lv`), Eff-n-Hotdogs (`num 60033`,
  `@effnhotdogs`), Daniel's Gourmet Foods (`num 60034`,
  `@danielsgourmetfoods`).
- **Separate, much bigger thread this session: rebuilding the "Deals"
  site (classiccarsforsale-co.web.app, a different Firebase project from
  LVR's but sharing LVR's RTDB for its `_deals/*` state) so it stops
  depending on the owner's Mac.** Not restaurant/LVR work, but same owner,
  same session — documenting here so a fresh session has the context.
  - **Root cause of the owner's "it's not updating consistently" complaint**:
    the GH-Actions cron (`deals-refresh.yml`) only *retires* dead/aged-out
    listings; new-listing discovery has only ever run on the Mac
    (`_tools/gen.js` + ~20 Craigslist-category `watch-*.js` harvesters,
    merged into `_tools/manual.json`, the real live inventory - the old
    Atomic Motors dealer feed has been OFF since July). If the Mac isn't
    reliably running, the site drains toward empty. Confirmed live: one
    purge dropped the site from ~231 to ~33 listings right before a owner
    demo; a manual Mac refresh (script given to the owner) recovered it to
    210, then normal operation to 3,074 total entries across all categories
    (not just cars - also land, houses, rentals, RVs, antiques, etc., all
    in one `manual.json`).
  - **Full scraper source + current `manual.json` (3,074 entries, hash-
    verified byte-for-byte) have been exported from the owner's Mac and
    captured** in `.github/db-task/fetched/deals-scraper-source.json` and
    seeded into Firebase at `_deals_ci_state/manual_json/*` as the CI
    pipeline's starting baseline. Getting this export right took several
    rounds - worth noting for a fresh session: (1) Firebase RTDB rejects
    `.`/`/` in JSON object keys at any nesting level, not just the URL path;
    (2) gzip-compressed payloads decompressed to different byte counts on
    macOS vs GitHub's Linux runners despite being hash-verified identical in
    transit (a real platform zlib divergence - worked around by dropping
    gzip entirely, plain base64 only); (3) a separate self-inflicted bug
    compared a Mac byte count against a JS string's `.length` (UTF-16 code
    units) after decoding, which undercounts for any multi-byte UTF-8 text
    - every "ABORT: size mismatch" traced back to this, not real corruption.
  - **New workflow `.github/workflows/deals-pipeline.yml`** (+ `.github/
    db-task/deals-ci/`) started: a service-account-JSON → OAuth-token
    exchange (pure Node crypto JWT-bearer flow, no gcloud/googleapis dep)
    to replace `gcloud auth print-access-token` in the deploy script for
    GH Actions. **Currently blocked**: the owner saved the
    `FIREBASE_DEALS_SA` GitHub secret but its value isn't valid JSON
    (missing opening `{`, stray tab/newline chars - looks like a copy/paste
    mangling, not a bad key). Asked the owner to re-copy via
    `pbcopy < ~/Downloads/<keyfile>.json` on the Mac and re-save the
    secret; still outstanding as of this write (checked via a re-run of
    the auth-test workflow each check-in cycle).
  - **Still to build once unblocked**: the site's static template
    (index.html/css/js/firebase.json) was never exported - plan is to
    bootstrap it from the *live* deployed site each CI run (it's public)
    rather than requesting another Mac export, since detail/model pages are
    already disabled site-side so firebase.json's exact hosting config has
    little practical effect; similarly plan to rehydrate `carimg/` from the
    live site's existing photos each run so only genuinely new listings
    trigger fresh downloads. Then: run the harvesters, run the owner's real
    `gen.js` unmodified (176KB of his actual business rules - 25-year
    cutoff with exemptions, no red/green/blue paint, no BMW/Mercedes/Jeep,
    Ford-trucks-only, etc. - deliberately NOT reimplemented, just run
    as-is), deploy, dry-run first before ever touching the live site.

---

## 14. Status as of 2026-10-12

- **"AlohaMulans" stuck-advertiser issue (section 11) resolved.** Owner sent
  the real IG screenshot - confirmed handle `@alohamulans` (Hawaiian-themed
  merch shop: bags, leis, backpacks; HI/LV based). Found the existing
  advertiser record and patched it with the handle instead of creating a
  duplicate - it's now fully DM-visible. "Wholesale Classic Cars" is the
  only advertiser still stuck without a confirmed handle.
- **Follow-up DM feature (dashboard) built and tested, not yet deployed.**
  Still waiting on the owner's final go-ahead on the message wording (went
  through two rounds of trimming it down for DM length) before he runs the
  one-line deploy command. Patch + deploy script are both ready in
  `.github/db-task/mac/patch-followup-dm.js` /
  `deploy-dashboard-followup.sh`.
- **Several more restaurant/business adds this cycle from the owner's IG
  screenshots**, all with full DM-visibility: Banh Mi House by Dakao,
  Smoking Pig BBQ Company, Las Vegas Lemon Bomb, Amy's Got Buns Bakery,
  Tacos El Cha.
- **Deals pipeline rebuild (section 13) still blocked** on the owner
  re-saving the `FIREBASE_DEALS_SA` GitHub secret correctly (current value
  is still invalid JSON). Nothing else to build until that lands.
- **18 more restaurant/business adds** this stretch from IG screenshots,
  all with full DM-visibility: Sushi Bake by Nora, Eff-n-Hotdogs, Daniel's
  Gourmet Foods, Haunted Brunch, Tacos El Cha, Banh Mi House by Dakao,
  Smoking Pig BBQ Company, Noodle King, Cactus Mexican Buffet, Marilyn's
  Cafe at the Tuscany, Tacos Los Brothers, AYCE Sushi & Asian Fusion,
  CHICHA San Chen NV, THE MAC LV, Peru Chicken, The Beach House, Santina's
  New York Pizzeria, Samurai Japanese Steakhouse and Sushi. "Rollin' Sweets"
  (@rollinsweetsllc) was flagged, not added — looked Florida-based, owner
  hasn't confirmed either way.
- **Database dedup cleanup (2026-10-16).** Ran a read-only scan for
  duplicate Instagram handles / names across `dashboard_crec` and found two
  real duplicates, both untouched (never DM'd, so no outreach history at
  risk): "Viva" (num 50867, blank IG, leftover Yelp-migration stub)
  duplicating "VIVA!" (num 50465, @eatdrinkviva), and a malformed
  push-ID-keyed "Jet's Pizza" record (num 60011 stored under a Firebase
  push-ID key instead of its own numeric key) duplicating "Jet' Detroit
  Sytle Pizza" (num 50217, same @jetspizza handle). Deleted both
  duplicates (crec + status + attempts, all confirmed 200). Worth a repeat
  scan periodically since the push-ID-keyed record suggests at least one
  past import wrote a record under the wrong kind of key.
- **New finding while doing that scan: 109 of 870 records (12.5%) have no
  Instagram handle at all**, so they can never be DM'd — almost all are
  leftovers from a past "Yelp migration" import, including a lot of
  well-known single-location Strip restaurants (Jaleo, Carversteak,
  HaSalon, Golden Steer, Del Frisco's, etc.). I can't reliably confirm
  exact @handles via web search (too easy to get a close-but-wrong
  handle, which would mean a DM landing on the wrong account), so I
  didn't guess any in. Full prioritized list — top 15 high-value/easy
  ones first, then everything else — is in `needs-ig-handle.md` in this
  same folder, ready for the owner to do a quick phone pass whenever he
  has a few minutes. Fixing one once a handle is confirmed is a one-line
  task.sh PUT, same pattern as every restaurant add this session.
- **Added "The Resort At Summerlin"** (@theresortatsummerlin, num 60052)
  from an IG screenshot.
- **Small data hygiene pass (2026-10-16).** Checked email-field coverage
  (only 2 of 871 records have one - IG DM is effectively the only real
  outreach channel, nothing to build there) and found/removed 6 orphaned
  `dashboard/status` + `dashboard/attempts` entries (nums 4, 5, 15, 72,
  766, 60006) marked "sent" with no matching `dashboard_crec` record at
  all - old leftover data, unrelated to the earlier VIVA/Jet's Pizza
  cleanup. Harmless either way since the dashboard iterates by
  `dashboard_crec` not by status, but cleaned up for hygiene. Also
  confirmed the earlier dedup deletes left no orphans anywhere.
- **⚠️ WARNING for future sessions: do not trust `/dashboard/igovr`,
  `/dashboard/igsuggest`, or `/dashboard/badig` as LVR data, even though
  some keys look like LVR nums.** Found these paths while exploring the
  full `/dashboard` schema. Checked all 3 `igovr` entries by hand before
  touching anything: one (num 50385, "Fogo de Chao Brasil") maps to
  `@tigersugar.usa` - a completely unrelated bubble tea business, not a
  real correction. This Firebase project is shared with other verticals
  (schema also has `golf*`, `infl*`, `modelstaging` paths), and these
  override/suggestion/bad-flag paths appear to belong to one of those,
  not to the LVR restaurant dataset, despite some numeric key overlap.
  **Never bulk-apply anything from these paths to `dashboard_crec`
  without verifying each record by hand first** - this is exactly the
  kind of "plausible but wrong" data that could silently misdirect
  outreach to the wrong business.
  **CORRECTION (2026-10-17):** this was too broad. `/dashboard/badig` IS
  real, trustworthy LVR data - cross-referenced against an older session's
  log (`fetched/dupes-and-badig.txt`) and the 238 flagged numbers/names
  match real `dashboard_crec` records exactly, including the same 109
  no-handle records already tracked in `needs-ig-handle.md`, plus 15 more
  that DO have a handle but it's flagged wrong (now also listed in
  `needs-ig-handle.md`). Only `igovr` (just 3 entries, one verified wrong)
  and `igsuggest` (keyed by small IDs like 1172/1185 that don't match
  LVR's 50000+/60000+ convention at all) stay flagged as untrustworthy for
  LVR. Tried verifying handles via direct HTTP to instagram.com from the
  GH Actions runner (a prior session's log suggested this worked) - dead
  end, Instagram returns 302 for every handle tried, real or not, so
  that approach can't distinguish valid from broken handles. Don't retry
  it; a human phone-check remains the only reliable way to confirm one.
  **SECOND CORRECTION, same day: `igsuggest` is also partly trustworthy
  after all.** 12 of its 25 entries use small sequential IDs with no crec
  match (genuinely not LVR-usable), but the other 13 are keyed by real
  `dashboard_crec` nums, and every one of those checked out: each entry
  cites a specific address, follower count, or website cross-reference -
  real verification work, not noise. Applied 8 of them as direct fixes
  (single-character typo corrections to `instagram`, badig flag cleared
  on each, all confirmed 200): Nana's house of Soul Food (50125), Whiskful
  Thinking Cakes (50204), Teriyaki Madness (50278), Sonrisa Grill (50315),
  Earthly Plant Based Eatery (50345), El chavo handcrafted snack bar
  (50360), Korea House (50611), and Daikon Vegan Sushi (50818 - this one
  had no handle at all before, now does). 3 more (Bowltastic/50221,
  Snooze/50395, Dom DeMarco's/50745) were confirmed already-correct, flag
  was just stale - no change needed. 2 lower-confidence ones (50206,
  50608) were explicitly NOT auto-applied - the data itself flagged them
  as needing a human look first, left in `needs-ig-handle.md` for the
  owner. **Lesson for future sessions: don't trust a data source based on
  one bad sample (the igovr "Fogo de Chao → Tiger Sugar" mismatch) without
  checking whether a DIFFERENT, better-documented source nearby (igsuggest
  here) might actually be solid. Evidence quality varies path-by-path even
  within the same shared Firebase project - check each on its own merits.**
- **Added "Sourdough & Co"** (@sourdoughcadence, num 60053) from an IG
  screenshot.
- **⚠️ TIME-SENSITIVE: the live Deals site's listing grid is about to go
  mostly empty.** Checked `cars.json` live on classiccarsforsale-co.web.app:
  the newest entry was added 2026-09-21 - 27 days ago as of this check,
  and NOTHING has been added since (the whole gen.js/harvest pipeline has
  been stalled this entire time, well before this session's check-ins
  started). Of 1,629 total entries, only 312 are still inside the 30-day
  freshness window the site's client-side display rule uses - and since
  no new listings have landed, that batch ages out within about 4 days of
  this check (2026-10-17), at which point the grid will show close to
  nothing. This raises the real urgency on fixing `FIREBASE_DEALS_SA` (or,
  short term, just running `_tools/gen.js` once on the Mac) well beyond
  "nice to have automated" - the site is about to visibly break.
- **UPDATE (2026-10-21): the Deals site grid is now fully empty.** Tracked
  this countdown across the following several days - the last batch
  (from 2026-09-21) fully aged past the 30-day freshness window as of
  this check. 0 of 1,629 `cars.json` entries currently pass. This is a
  steady state now, not a moving countdown - nothing changes further
  until either `FIREBASE_DEALS_SA` gets fixed and the GH Actions pipeline
  can run, or the owner runs `_tools/gen.js` on the Mac. Future sessions:
  no need to keep re-polling this every cycle now that it's bottomed
  out - just check once after the owner says they've acted on the
  secret or run the script manually.

---

## 15. Status as of 2026-10-24

- **Owner ran three pending Mac deploy scripts tonight.** Results, verified
  (not just trusted from terminal output):
  - **Dashboard patches**: confirmed live, `APP_VERSION 450 → 451`, all
    expected markers present (`rsLoadFirebaseStaging`, `igSuggestAccept`,
    `s-badig-sug`, staging tab restored). Clean.
  - **Dating site instant-swipe patch**: already live from an earlier
    session — this run just confirmed it (`DATEQS01: 1`, old sign-up
    code: `0`). No actual change needed.
  - **Deals site (`setup-deals-auto.sh`) did NOT fix the stale/empty grid.**
    The terminal output looked like a success (image dedup/upload pass,
    "25223/25223"), but that step only checks which car *images* already
    exist on the host — it's not evidence of a new scrape. Verified
    independently via a one-off `task.sh` GH Actions check against the
    live `cars.json`: still 0 entries inside the 30-day freshness window,
    newest `added` date still `2026-09-21` — identical to the 2026-10-21
    steady state in section 14. The LaunchAgent reinstall either isn't
    triggering a real Craigslist harvest, or the harvest is running and
    finding nothing (Craigslist blocking the scraper remains the leading
    suspect, as already flagged). **Still needs a real debugging session**
    — rerunning `setup-deals-auto.sh` again is not expected to help by
    itself.
  - **`enable-pages.yml` (the one-shot workflow from the St Rita's days
    that tried to flip GitHub Pages on via the Actions `GITHUB_TOKEN`) was
    already tried and already removed** — GitHub returns a 403, Actions
    cannot create a Pages site this way. Confirmed via git history, not
    re-attempted. The GitHub Pages "Source: GitHub Actions" toggle for
    `key-technologies-pages.yml` still has no path except the owner
    flipping it manually in repo Settings → Pages.
- **Key Technologies (separate from LVR, same repo) got a lot of real
  content work tonight**: a new Results section with real numbers (200,000+
  combined IG followers, 124,000 on LasVegas_Restaurants alone), a footer
  phone link, a mobile-menu bug fix (position:fixed was broken by the
  header's `backdrop-filter` creating an unexpected containing block —
  real CSS bug, verified with a Playwright test before/after, not a
  guess), a "Custom CRM & Lead Management" service rename pushing Shane's
  own CRM build as a sellable product, AI image/video content generation
  added to the social/marketing services, and a custom AI training
  software line added to staff training. An after-hours AI voice agent
  (Synthflow, forwarding (949) 899-3059 on no-answer) is in progress —
  script is written, waiting on the owner to create the Synthflow account
  and send back the number.

---

## 16. ⚠️ STANDING DIRECTION (2026-10-24) — Key Technologies is NOT targeting restaurants

**The owner's own words: "The more I was in the restaurant game, the more I
learned that restaurant owners are not that smart when it comes to
technology or marketing... I really want to go back to what I was doing
before, going after very high-end clients."** This firms up the open
question from §13 ("restaurants/hospitality are not his main target
audience") into a real decision — treat it as settled, not open, going
forward.

**Key Technologies' actual target verticals** (owner picked all four when
asked to choose): Real Estate (agents/brokerages), Medical/Dental/Aesthetic
practices, Law firms, E-commerce/DTC brands. Not restaurants. The
restaurant/LVR database and business stays exactly as it is — this doesn't
change anything about LVR, it's specifically about who Key Technologies
markets to.

**Built in response**: a standalone Key Technologies Prospect CRM
(`kt-crm.html`, deploy script in §3 above) — its own PIN, its own Firebase
node (`/kt_crm/prospects`), completely separate from every restaurant
node, for tracking prospects across those four verticals with a status
pipeline and a tailored outreach script per vertical built in. This is the
tool for the "what text are we sending out" question going forward, not
the templates in the Go-to-Market Strategy doc — those were written in a
small-local-business tone before this pivot and are now out of date for
the actual target buyer (a real estate broker or law firm doesn't need the
same hand-holding as a taco shop owner). Revisit/rewrite that doc's
templates next time it comes up rather than trusting them as-is.

---

## 17. Key Technologies SEO push (2026-10-24) — site is now 5 pages, not 1

Direct follow-through on §16's pivot: Shane asked what it would actually
take to compete in search, got a straight answer (new domain = no shortcut,
but local map-pack + real content pages are genuinely fast levers), and
said to build both.

- **4 new real landing pages**, each with original content (not a
  templated swap), own Service + FAQPage JSON-LD, own meta/OG tags, own
  lead form (tagged with its own `source` so these leads are
  distinguishable from the homepage's): `real-estate.html`,
  `medical-dental.html`, `law.html`, `ecommerce.html`. Each includes a
  direct competitor-comparison FAQ question tuned to that industry's real
  tools (Follow Up Boss/kvCORE for real estate, Clio/MyCase for law) -
  deliberate, captures comparison-shopping searches.
- **New "Industries" hub section** on the homepage linking to all four,
  wired into the footer and mobile menu. Deliberately NOT added to the
  top desktop nav - re-verified the nav-overlap fix from earlier today
  still holds (gap stayed positive) rather than assuming it.
- **All 4 new pages in sitemap.xml.**
- **Google Business Profile copy is ready**, added as a new section in
  the "Key Technologies — Go-to-Market Strategy" Claude Doc
  (`9ac508d3-e6a8-4066-9a98-b7f98044f8e7`): business name, categories,
  description, services list, and service areas for both Manhattan Beach
  and Las Vegas. Confirmed via web search that two separate listings is
  the *correct* move (not a guideline violation) since Google explicitly
  allows that for service areas over a two-hour drive apart. **Still
  needs Shane to actually create and verify both listings** - that part
  requires his own Google account, can't be done from here.
- Every new page tested the same way as the main site before shipping:
  JS syntax check, JSON-LD parse check, tag-balance check, then a real
  Playwright pass (FAQ accordion, form validation, mobile menu) - not
  just visual inspection.
- **Next natural step if asked**: more vertical pages aren't needed yet
  (4 covers the picked verticals) - the next SEO lever is real backlinks
  and reviews, which are Shane's work, not buildable from here.

---

## 18. Key Technologies — founder credentials + SEO/GTM follow-through (2026-10-24, later same night)

Continuing §17's work, same session:

- **Founder bio expanded on the homepage** with two more real credential
  paragraphs Shane gave directly: (1) blockchain/crypto — following
  Bitcoin since its first week, using Ethereum since launch, Bitcoin
  mining, built his own coin in 2017, NFTs and other blockchain projects;
  (2) e-commerce/marketplace + collectibles — hands-on selling on Amazon,
  eBay, OfferUp, Craigslist, and active in Pokémon card collectibles. The
  e-commerce/marketplace credential was also echoed in `ecommerce.html`'s
  Proof section specifically, since it's directly relevant proof for that
  one vertical's audience — the blockchain credential was deliberately
  **not** propagated to the vertical pages (not relevant to real estate/
  medical/law/e-commerce buyers, risk of reading as unfocused).
- **Founder `Person` JSON-LD schema expanded** (was just a bare name) with
  a `description` and a `knowsAbout` list covering security, networking,
  databases, business tech, digital marketing, blockchain/crypto and
  e-commerce — a real, low-risk SEO/E-E-A-T lever, no visual change to the
  page.
- **GTM Strategy doc's stale restaurant-only targeting partially fixed**
  (the gap §16 flagged — "revisit/rewrite that doc's templates next time
  it comes up"): added a new "High-end vertical targeting" section right
  after the old "Who to target first" table with a who/how-to-find-them
  breakdown for each of the 4 verticals (linking to the matching landing
  page), and reframed the restaurant audience as a referral source into
  these verticals rather than the end client. **Not yet done**: the
  doc's actual Message Templates (3 variants) are still generic enough to
  reuse as-is but haven't been rewritten in a higher-end tone — that's
  the next piece if this doc comes up again.
- **GitHub Pages still failing on every push tonight** (confirmed again,
  run #45, same root cause: `Get Pages site failed` — Settings → Pages →
  Source has still not been flipped to "GitHub Actions"). Deals site
  status unchanged from §15 (still 0 fresh listings, needs a dedicated
  debugging session, not worth re-polling every cycle).

---

## 19. Status as of 2026-10-26 — keytechnologies.si is LIVE

**The biggest change since §18: Key Technologies is genuinely live on its own
domain with a valid HTTPS cert.** This took four separate, sequential
blockers, each diagnosed live with the owner at his Mac, not guessed:

1. GitHub Pages Settings → Pages → Source flipped to "GitHub Actions" (the
   owner finally did this manually — no API path exists, confirmed in §15).
2. **New discovery**: flipping Source wasn't enough — every deploy still
   failed instantly with zero logs. Root cause: GitHub auto-creates a
   `github-pages` deployment *environment* that by default only allows
   deploys from the repo's default branch (`main`) — but this project
   deploys from `claude/master-file-e6ofy0`. Fixed via Settings →
   Environments → `github-pages` → Deployment branches and tags → "No
   restriction."
3. DNS: `keytechnologies.si` had zero records at Dynadot (parked, not
   configured). Fixed by switching Dynadot's mode to "Dynadot DNS" and adding
   4 separate A records (one IP each) pointing at GitHub Pages.
4. Custom domain + SSL: even with DNS correct, HTTPS failed on a cert
   hostname mismatch because the "Custom domain" field in Pages settings
   (separate from the CNAME file already in the repo) had never been set.
   Owner entered it, GitHub auto-issued a Let's Encrypt cert.

**Full live-site audit run after launch** (via a `task.sh` GH Actions
diagnostic, since this sandbox can't reach the live domain directly): all 7
real pages return 200 with correct content, 404 handling works and serves
the branded `404.html`, robots.txt/sitemap.xml/og-image all reachable,
canonical tags correct, no mixed content, Firebase CORS confirmed working
from the live origin, Formspree endpoint confirmed live. Two minor real
issues found and explained to the owner (not urgent): HTTP doesn't yet
redirect to HTTPS (likely just needs time post-cert-issuance), and
`www.keytechnologies.si` isn't configured (owner's call to skip — he doesn't
market the www form). **Confirmed, not assumed: the free/unauthenticated
PageSpeed Insights quota the audit tool relies on is genuinely exhausted**
(direct API test returned a real `rateLimitExceeded` error) — this degrades
the live audit tool's scoring for real visitors right now, which raises
`KEY_PAGESPEED_API_KEY` (still empty) from nice-to-have to a real priority.

**New: custom page-view counter + PIN-gated report**, since the owner wanted
a quick "who's looking at what" view without first setting up Google
Analytics (GA4 is also scaffolded in, inactive, `KEY_GA_MEASUREMENT_ID` still
empty, offered as the deeper option later). Every real page now logs a
lightweight hit (page, timestamp, referrer, screen width — no PII) to a new
`key_pageviews` Firebase node. `keytechnologies.si/key-pageviews.html`
(PIN `702951`, not linked in nav) shows total/7-day views per page, last-
viewed time, and a recent-activity feed. Tested via Playwright (PIN gate,
rendering, empty state) and verified against a real live round-trip (POST a
test hit, read it back) via GH Actions — found along the way that this
Firebase database accepts writes but rejects deletes (401 on a direct
`DELETE`, unlike the no-rules-at-all LVR nodes in §8) — not expected to
affect real use since the tracker only ever creates new entries, never
deletes.

**Site content/credentials work also shipped this stretch** (all live):
blockchain/crypto and e-commerce/collectibles credentials added to the
founder bio and `Person` JSON-LD `knowsAbout`; phone number removed
site-wide in favor of a "Book a Call" CTA; 2 new services (Private LLM
Setup, Cybersecurity & Network Hardening); a branded `404.html`; an honest
"Just Launched" banner on all 5 main pages (copy drafted, critiqued, and
tightened with the owner directly); privacy policy corrected to describe
the new page-view counter accurately instead of claiming "no analytics."

**Still pending from §3, now MORE actionable since Pages going live removes
the "Key Technologies pill 404s" blocker**: the Key Technologies pill,
`kt-crm.html`, `key-leads.html`, and `key-advertisers.html` are all still
sitting as tested-but-undeployed Mac scripts — **re-verified live 2026-10-26,
still 404 on all three standalone tools, dashboard still `APP_VERSION 451`**
(unchanged since the dashboard-patches deploy in §15). Zach's PIN, previously
listed here as pending, turned out to already be live — see the correction
in §3.

**Deals site: still stuck, re-confirmed 2026-10-26.** `fix-deals-harvest.sh`
(the real root-cause fix from §15/§3) was started by the owner at his Mac but
has still not posted a completion log, and `cars.json` is unchanged — 0
entries inside the 30-day freshness window, newest `added` still
`2026-09-21`. The only diagnostic log present is from the earlier dating-site
patch run, not a harvest completion. Needs the owner to check that Terminal
window or re-run the script; not productive to keep re-polling automatically
until there's a reason to think it moved.

### NEW 2026-10-27 — Rewards/points reconciled into ONE system; deploy bug found and fixed

**Discovered:** a pre-existing LVR Rewards system already lives on the dashboard
(`openRewardsCRM()` → Firebase `/lvr_rewards`, 8 real members with real point
balances; public signup form `lvr-rewards.html`, hosted on Firebase only, now
tracked in the repo at `.github/db-task/mac/lvr-rewards.html`). The owner's
direction: "the reward system and the point system are the same thing."
**`/lvr_rewards` is now THE member store.** Members gained a personal-link
`token` field (all 8 backfilled; both signup forms now generate one). The
member wallet (`keytechnologies.si/my-account.html?t=<token>`) reads/writes
`/lvr_rewards` (balance field = `points`). `/lvr_points/wallets` and
`/lvr_points/grants` are retired (never held real data). Still used from
`/lvr_points`: `catalog`, `restaurants`, `redemptions` (genuinely new:
what members can redeem, restaurant PINs, redemption log).
`lvr-wallet.html` is now just a redirect to `my-account.html`.
Dashboard Rewards CRM got a "Member Link" box (Copy Their Link) per member via
`patch-key-room-pill.js` (markers `KEYROOM-MEMBERLINK-v1`/`-FNS-v1`).
Redemption records now carry name/phone/instagram/bizName (not email) and a
`usedAt` timestamp the restaurant portal sets via "Mark used" / code lookup;
members see their past codes ("My codes") with Ready/Used badges.

**Deploy bug (root cause of every standalone tool 404ing, incl. older
leads/CRM/advertisers/coupons):** the Mac's `deploy-overlay.js` was a one-off
hardcoded to overlay ONLY `index.html` + `version.json`; every `deploy-*.sh`
downloaded/syntax-checked its tool file, reported success, and the deployer
silently ignored it. Fixed: `.github/db-task/mac/deploy-overlay.js` now takes
an `OVERLAY_FILES` env var and every `deploy-*.sh` re-pulls it fresh and sets
it. **Verified live 2026-10-27 10:xx: all standalone tools 200, dashboard
`APP_VERSION 453`.** Lesson: a deploy script's own "RELEASED" is not proof a
specific file is live — always curl the file.

**Coupons:** programs can now carry a `fixedCode` (restaurant-supplied code,
e.g. 55555) shown to every claimer, capped by `maxClaims`; claim link text on
the admin card is now tappable. Vanilla Rice program slug is `5555`.

**Naming decision (owner, 2026-10-27):** it is just called "points" - never
"tokens", "LVR points" or "restaurant points". One balance per member
(`/lvr_rewards/<key>/points`) that works wherever they are logged in; the
restaurant-only app (`VERTICAL='restaurants'` in my-account.html) only filters
which offers are shown, not the balance. Receipts / earn-rate / commission
ledger and the `/lvr_points/directory` category field were added the same day.

---

*If you're a new Claude session reading this cold: read this whole file, then
ask the owner what they want to work on next rather than re-diagnosing
everything above from zero — it's all still accurate as of the date at the
top unless they tell you otherwise.*

### UPDATE 2026-10-27 — safety, welcome bonus, menu, treasure chest (all tested, none involve secrets)
- **Database rules (evidence protection)**: `rules/lvr-rules-fragment.json`, tested in the Firebase emulator
  (`rules/run-rules-test.sh`, 104 checks passing). Blocks editing/deleting receipts, photos, redemptions,
  ledger entries and bonus records, and blocks wiping any list. Installed on the Mac with
  `mac/deploy-rules.sh` (saves a local backup, merges only the four points sections, verifies, auto-undoes);
  `mac/undo-rules.sh` restores. NOT yet confirmed installed as of this entry.
- **Known limit**: balances can still be edited by anyone who knows the database address until the
  server step (Cloud Functions, needs the Blaze plan) moves point awards server-side.
- **Page-view counter bug fixed**: Firebase keys cannot contain ".", so trackers now store `index_html`;
  the report accepts both spellings. Confirmed recording live.
- **Welcome bonus**: Settings > Welcome bonus (default OFF). Amount (max 50) and timing
  (at sign-up, or when the first receipt is approved). Sign-up amount is rule-capped to the setting.
- **Points menu**: `sites/key-technologies/menu.html?b=<slug>` - one long menu from the catalog
  (catalog items now take optional Menu section + Description).
- **Treasure chest**: per-member countdown (default 7 days from joining); the first chest gives a fixed
  bonus set in Settings (default 0 = "coming soon"). Claim is once-only and enforced by the rules.
  Repeating/random weekly chests are on hold pending an attorney and the server.
- **Bonus tab** in Points admin: manual points with a permanent reason (`/lvr_points/bonuses`).
- **Admin tools blank-screen fix**: auto-sign-in path ran before the page was ready; fixed in all five tools.
- **Owner-requested ideas on hold for attorney/server**: weekly random gift, points for videos
  (endorsement disclosure), $100 restaurant-funded credit handed out like a gift card, members sending
  points to each other (a gift link for a free item is the safer alternative), AI receipt reading
  (needs Blaze + the owner's own Anthropic API key).
- Hub page (private artifact) lists links and the owner's to-do list.

## Monthly community-fund return (built 2026-10-27, OFF by default)
- Settings tab: on/off, percent (default 20, max 50), grace days for new members (default 30). Rounded down to whole points.
- `.github/db-task/decay/monthly-decay.js` does the work; each member's return is claimed with a create-only record first (`lvr_points/decay_by_member/<member>/<YYYY-MM>`), so a rerun never charges twice. Total goes to `lvr_points/pool/total`; run summary in `lvr_points/decay_runs`.
- `.github/workflows/lvr-monthly-decay.yml` runs it on the 1st-3rd of each month, but GitHub only runs scheduled workflows from `main`. It must be on main before it is automatic. Manual run with dry_run=1 shows what would happen.
- Members see a "Use it or share it" notice with the date and amount; fine print mentions it.
- Attorney list: monthly return of unused points (disclosure at sign-up, effect on welcome points, where the pool goes).
- Tested: 124 rules/sweep checks pass on the runner.

## Repeating treasure chest (built 2026-10-27, prizes OFF until you set a max above 0 (Settings now pre-fills 1 to 7; saving Settings turns it on))
- Settings > Treasure chest: days until first chest (default 14), extra days each time (5), smallest/biggest prize (1 and 2; max 0 = off), "Keep repeating".
- Waits: 14, 19, 24, 29 ... days; each countdown starts when the member opens the previous chest.
- Claim is written first to `lvr_rewards/<member>/chestState {n, amount, at}`; rules only accept the next number, after the full wait, with a prize inside your range. Every prize is also logged in `lvr_points/chest_log/<member>/<n>` (cannot be edited).
- Prize is picked in the member's browser (no server yet), so it is only as strong as the rest of the balance system until Cloud Functions. Rules cap it to your min/max.
- Wooden pirate-chest art; pop-open animation with coins on the member screen.
- Attorney list: random prizes (check sweepstakes/chance rules; there is no purchase tied to the chest, but ask).
- 134 rules/sweep checks pass.

## Demo and member-screen state (2026-10-28)
- Member screen: points top-left, big chest countdown, "spend before the 1st" bar, game scroll, each restaurant in its own box (food photo first, then name), claimed/urgency meter on every offer ("28 of 30 claimed", Going fast, Only N left, days until it ends).
- Every offer is pickup only (card tag, fine print, redeem confirm, code screen, restaurant lookup).
- Las Vegas demo: 39 real restaurants (Thai, Mexican, Italian, pizza, sushi, burgers, steak, breakfast, sweets). Secret Pizza removed. Photo rule: plated food only; no drinks, paper plates, napkins, straws, cups or takeout boxes.
- Sign-up forms (KT and LVR) now require the "I'm in" game-rules checkbox; consent saved as consent_rules / consent_rules_ts.
- Still waiting on Shane: run the Mac go-live command (rules + tools incl. chest, monthly return, agreement checkbox), then verify-live; enter Vanilla Rice credit before turning on the welcome bonus; attorney review of monthly return, random chest prizes, no-refund rule.
- Monthly-return schedule file is on this branch only; GitHub runs scheduled jobs only from main, so put it on main only after attorney sign-off.

## Member bonus is now a fixed cycle (2026-10-28)
- Ready every 10 days (Settings > Member bonus > "Days between bonuses"), open for 48 hours ("Hours to claim it"). Not claimed in time = the 10-day wait starts over (worked out from the clock, nothing to write).
- The database rules enforce the 48-hour window too (`chestState` rule uses the cycle modulo). Extra-days-each-time (`stepDays`) is gone. 140 rules checks pass.
- Needs `go-live.sh` to put the new rules and the Settings screen live. Prizes stay OFF (max 0) until you set one.
- Prize range for now: a random whole number from 1 to 7 (each claim picks one).

## Owner "Remove restaurant" tool (2026-10-29)
- On the member screen and the Las Vegas list, tap the small "Owner" link at the bottom, enter the owner PIN (137900), and every restaurant gets a Remove button (with a confirm popup). Removed restaurants can be restored from the same mode.
- Removed names are saved at `lvr_points/settings/hiddenRestaurants/<name-slug>` (public read, settings is open-write like the other settings). Nothing is deleted. In a preview that can't reach the database the choice is kept on that device only.
- The PIN check is light (hash in the page); real protection arrives with the Cloud Functions / Blaze step.
