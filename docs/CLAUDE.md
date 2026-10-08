# Key Technologies website — rules for anyone (human or Claude) working on this repo

Read this before changing anything. This file is the standing source of
truth for the project; it summarizes the full original handoff doc plus
decisions made since.

## What this is

The website for **Key Technologies** (brand name as of 2026-10-04 — see
"Brand name / domain" below for history), an AI consulting and
intelligent business systems company founded by Shane Christensen.
Domain: **keytechnologies.si** (registered 2026-10-03 via Dynadot, confirmed
active). Based in Manhattan Beach, CA and Las Vegas,
NV. A completely separate business from Shane's "LVR" (Las Vegas
Restaurants) properties — separate repo, separate site, separate brand.
**Exception, decided 2026-10-08:** lead storage does share LVR's existing
Firebase Realtime Database (see "Lead database" below) — that was Shane's
explicit, informed choice over paying for/setting up a second database.
Everything else (repo, site code, hosting) stays fully separate.

## Brand name / domain — read this before touching branding again

The company was originally specced as just "KEY," with an explicit rule
against using "SI" anywhere in the brand (an earlier prototype briefly
used `keysi.com`, then deliberately dropped it — both the domain and the
letters "SI" — before this project started). **On 2026-10-04, Shane said
he was registering `keytechnology.si` and asked to rebrand everything to
it** — the first exception to the no-SI rule, exactly as it always said
it could ("unless Shane explicitly asks for it later").

**Then, still on 2026-10-04, before that domain was actually paid for,
Shane decided on the plural instead: `keytechnologies.si` / "Key
Technologies."** He registered it via Dynadot on 2026-10-03 (confirmed
active, 364 days remaining as of the registration screenshot) — this is
now the real, owned, final domain, not a placeholder.

Current state: company name is **Key Technologies**, domain is
**keytechnologies.si** (registered, owned, on Dynadot), logo wordmark is
**"KEY TECHNOLOGIES"** (same horizontal-key icon as before, just the
longer wordmark — see "Design system" below for the font-size adjustment
that made it fit the thin header). Every file in this repo reflects this
name/domain (`index.html`, `404.html`, `privacy.html`, `terms.html`,
`sitemap.xml`, `CNAME`, this file, `README.md`).

**Don't revert any of this without Shane explicitly saying to** — same
standard as any other branding change.

## Hard rules — do not violate these
- **No invented content, ever**: no testimonials, no customer names, no
  case studies, no revenue numbers, no performance statistics, no
  certifications, no awards. If it isn't real and verified, it doesn't
  go on the site.
- **No stock photos.** No photo of Shane unless he specifically asks for
  one.
- **Don't fake form submissions.** The lead forms currently have no
  backend. They validate and show an honest "not connected yet" message
  (see the JS in `index.html`) — never a fake "submitted successfully."
  Don't change that until a real backend/API actually exists.
- **Never commit secrets.** No database passwords, API keys, or CRM
  credentials in this repo, ever — use environment variables and a real
  backend once one exists.
- **Don't redesign the whole site without Shane's approval.** Small
  fixes and additions are fine; a visual overhaul is not a judgment call
  to make alone.
- **Don't change founder facts.** Shane's background (25+ years in
  computers/security/networking/databases/software/websites/business
  tech/digital marketing/social media; ~10 years building restaurant
  social brands: LasVegas_Restaurants, OrangeCounty_Restaurants,
  SanDiego_Restaurants, and more) is real and specific — don't embellish
  it or add anything not already established.

## Design system (established — match this, don't drift from it)

```
Background:    #07111f
Secondary BG:  #091728
Card:          #0c1a2b
Lines/Borders: #20364e
Primary Text:  #f6f8fb
Muted Text:    #aab9ca
KEY Light Blue:#59b5ff
KEY Blue:      #168fff
White:         #ffffff

Font: Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Arial, sans-serif
```

The logo is an inline SVG (not a PNG/JPG) — a horizontal key symbol
followed by the separate wordmark "KEY TECHNOLOGIES". Keep the key symbol
perfectly straight, and keep the symbol and the wordmark visually separate
(don't merge them into one mark). Same logo treatment in header and footer.
The wordmark is set smaller than the original "KEY"-only version
(`.logo-word` is 16px, 13.5px under 420px) specifically so the longer
text still fits the thin header — don't bump that size back up without
checking it still fits at phone width.

## Layout rules

- Header stays thin — don't let it grow and eat vertical space.
- Mobile nav is a **two-line** hamburger icon, not three lines. It must
  actually open/close a working dropdown menu.
- Keep sections tight. No large empty gaps after headings, names, or
  paragraphs — the page should read like it wants you to keep scrolling,
  not like dead space between slides.
- Large, readable text; strong contrast; short paragraphs; big tap
  targets. This needs to be easy to read for an older, non-technical
  visitor, not just a developer.

## Current repo structure

```
index.html       Everything lives here today — CSS and JS are embedded
                  inline, not split into separate files (matches the
                  site's existing architecture).
404.html
privacy.html      Placeholder content — needs Shane's real policy once
terms.html        the backend and business structure are finalized.
robots.txt
sitemap.xml       Points at https://keytechnologies.si/ (set 2026-10-04).
CLAUDE.md         This file.
README.md
firebase-leads-rtdb.rules.json   Unused as of 2026-10-08 — rules for the
                  separate-DB plan that was reversed. Kept as reference
                  only. See "Lead database" below.
```

If the project grows past a single page, the next step is the
`/assets/css/`, `/assets/js/`, `/assets/images/` split mentioned in the
original handoff — don't do that split preemptively while it's still one
page.

## Known open items (don't invent answers to these — ask Shane)

- **Domain**: `keytechnologies.si` — registered and confirmed active
  (Dynadot, 2026-10-03). Not yet hosting the site — DNS needs to be
  pointed at GitHub Pages. See "Deploy" in `README.md`.
- **Lead database**: decided 2026-10-03, **reversed 2026-10-08** — Shane
  said he didn't want a second Firebase project and wanted everything
  running through LVR's existing database instead. He was told the real
  tradeoff first and chose this anyway: **LVR's database currently has no
  security rules at all** (open, unauthenticated reads AND writes to
  everything, and its URL is already public in the LVR repo's own commit
  history) — so unlike the original plan, Key Technologies' leads are
  *not* protected. Anyone with the database URL can read every lead's
  name/email/phone, or write/delete data. `firebase-leads-rtdb.rules.json`
  in this folder is now unused — it was the ruleset for the separate-DB
  plan that didn't happen; it's kept only as a reference for what "do this
  properly" would look like if the LVR database is ever locked down (see
  the LVR repo's own status doc for that open issue).

  **Current, live setup:** `index.html`'s `KEY_LEADS_DB_URL` points at
  `https://lvr-data-a60c1-default-rtdb.firebaseio.com/key_leads` — a
  dedicated `/key_leads` node inside LVR's database, kept separate from
  LVR's own restaurant/advertiser data by path, not by any real access
  control. Leads land at `/key_leads/leads/<auto-id>`. No further setup
  needed — this is already wired and live, unlike the old separate-DB
  plan which was never actually set up.

  **If this ever needs revisiting** (e.g. if LVR's database gets locked
  down with real rules, or Shane changes his mind): either add Firebase
  security rules scoped to `/key_leads` specifically — note this only
  restores integrity (who can write), not confidentiality, since a
  database-wide open `.read` rule cascades to every child path regardless
  of a deeper rule — or go back to the original separate-project plan
  using `firebase-leads-rtdb.rules.json` as-is.
- **Lead alert email**: built 2026-10-04, off by default. `index.html`
  has a second, additive config line, `var KEY_FORMSPREE_URL = "";`,
  right under `KEY_LEADS_DB_URL`. When set, every successful form
  submission also POSTs to that Formspree endpoint, which emails
  whoever set up the Formspree form — the database write is still the
  real save either way; the email is just a "know about it right now"
  side channel, and its failure never changes what the visitor sees.

  **One-time setup (no Mac needed, just a web signup):**
  1. Go to formspree.io, sign up free, create a new form.
  2. Set its notification email to whichever inbox should get lead
     alerts.
  3. Copy the form's endpoint (looks like
     `https://formspree.io/f/xxxxxxxx`).
  4. Paste it into `KEY_FORMSPREE_URL` in `index.html`.

- **Post-submit booking link**: built 2026-10-04, off by default.
  `index.html` has `var KEY_CALENDLY_URL = "";`. When set, a successful
  submission shows a "Book a time now" button pointing at it, instead of
  just a thank-you line with no next step. Empty = no button is shown at
  all (never a broken placeholder link). Paste in a real Calendly (or
  equivalent) scheduling link once one exists.
- **Analytics**: not installed yet — don't add any analytics platform
  until Shane picks one.
- **Contact email/phone**: not yet provided — currently absent from the
  site rather than invented. Add them when given.

## SEO architecture (future, not today)

Dedicated pages like `/ai-consulting/`, `/ai-automation/`,
`/ai-agents/`, `/business-automation/`, `/ai-for-small-business/`,
`/database-ai/`, city-specific consulting pages, `/about/`, `/contact/`,
`/insights/` are planned for later, each with substantial original
content — not thin, duplicate, or keyword-stuffed pages. Don't build a
pile of these preemptively; the single homepage is the current scope.

## Testing checklist before shipping any change

- Mobile (iPhone-width) and desktop layouts
- The two-line hamburger actually opens/closes, and its dropdown links work
- Both lead forms: validation, and the honest "not connected yet" status
  message (not a fake success)
- Every internal anchor link (`#services`, `#method`, etc.) actually
  scrolls to the right section
- Footer links (Privacy, Terms) resolve
- `prefers-reduced-motion` is respected (the whole site should have very
  little motion to begin with)
