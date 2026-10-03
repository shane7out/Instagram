# Key Technologies website — rules for anyone (human or Claude) working on this repo

Read this before changing anything. This file is the standing source of
truth for the project; it summarizes the full original handoff doc plus
decisions made since.

## What this is

The website for **Key Technologies** (brand name as of 2026-10-04 — see
"Brand name / domain" below for history), an AI consulting and
intelligent business systems company founded by Shane Christensen.
Domain (intended, not yet confirmed registered — see below): **keytechnologies.si**. Based in Manhattan Beach, CA and Las Vegas,
NV. A completely separate business and project from Shane's "LVR" (Las
Vegas Restaurants) properties — nothing here shares a database, a repo,
or infrastructure with that project. Don't mix the two.

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
Technologies."** As of right now the site's own content (this file
included) assumes that domain and name throughout, but **the domain
itself is not confirmed registered yet** — don't tell Shane or anyone
else that keytechnologies.si is live or owned until he's confirmed the
purchase actually went through. If he comes back having registered the
singular instead, or a different domain entirely, this whole pass needs
redoing — check with him before assuming either name/domain is final.

Current state: company name is **Key Technologies**, domain (intended,
not yet confirmed registered) is **keytechnologies.si**, logo wordmark is
**"KEY TECHNOLOGIES"** (same horizontal-key icon as before, just the
longer wordmark — see "Design system" below for the font-size adjustment
that made it fit the thin header). Every file in this repo reflects this
name/domain (`index.html`, `404.html`, `privacy.html`, `terms.html`,
`sitemap.xml`, this file, `README.md`).

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
firebase-leads-rtdb.rules.json   Security rules for Key Technologies' own
                  lead database (separate from LVR) — see "Lead
                  database" below.
```

If the project grows past a single page, the next step is the
`/assets/css/`, `/assets/js/`, `/assets/images/` split mentioned in the
original handoff — don't do that split preemptively while it's still one
page.

## Known open items (don't invent answers to these — ask Shane)

- **Domain**: name decided 2026-10-04 — `keytechnologies.si` — but
  **registration not yet confirmed**. See "Brand name / domain" above.
- **Lead database**: decided 2026-10-03 — Key Technologies gets its own, separate
  Firebase Realtime Database (not LVR's, and not the CRM/system Shane
  mentioned connecting "eventually" — that's a possible later upgrade,
  this is the simple thing that ships now). The form-submission code in
  `index.html` is already built and wired for this: it POSTs to
  `<KEY_LEADS_DB_URL>/leads.json`, and `firebase-leads-rtdb.rules.json`
  in this folder is the exact security rules to set. Those rules only
  allow *creating* a new lead — no client, including the one that just
  submitted, can read, overwrite, or delete any lead. That's the
  deliberate fix for the problem LVR's database has (it accepts
  unauthenticated reads AND writes to everything) — Key Technologies'
  database should never end up in that state.

  **One-time setup (needs Shane's Google login, so this is a Mac task):**
  1. Firebase console → new project (e.g. `key-leads`).
  2. Build → Realtime Database → Create Database.
  3. Rules tab → paste in `firebase-leads-rtdb.rules.json` from this
     folder → Publish.
  4. Copy the database's URL (looks like
     `https://key-leads-xxxxx-default-rtdb.firebaseio.com`).
  5. In `index.html`, find `var KEY_LEADS_DB_URL = "";` near the top of
     the `<script>` block and paste the URL in between the quotes.
  6. Submit a test lead through the live site, then check the Firebase
     console's Realtime Database data tab to confirm it landed under
     `/leads`.

  That's the whole setup — no Cloud Functions, no backend server, just
  the database and its rules. Reading the leads back out (a dashboard,
  CSV export, etc.) is a separate, later task once there's something to
  look at.
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
