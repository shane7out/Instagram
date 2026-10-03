# KEY website — rules for anyone (human or Claude) working on this repo

Read this before changing anything. This file is the standing source of
truth for the project; it summarizes the full original handoff doc.

## What this is

The website for KEY, an AI consulting and intelligent business systems
company founded by Shane Christensen. Based in Manhattan Beach, CA and Las
Vegas, NV. A completely separate business and project from Shane's "LVR"
(Las Vegas Restaurants) properties — nothing here shares a database, a
repo, or infrastructure with that project. Don't mix the two.

## Hard rules — do not violate these

- **No "SI" or "Super Intelligence" anywhere**, unless Shane explicitly
  asks for it later. The brand was already pulled back from this once.
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

The KEY logo is an inline SVG (not a PNG/JPG) — a horizontal key symbol
followed by the separate wordmark "KEY". Keep the key symbol perfectly
straight, and keep the symbol and the wordmark visually separate (don't
merge them into one mark). Same logo treatment in header and footer.

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
sitemap.xml       Domain is TBD — every absolute URL in here, and in
                  index.html's <meta> tags, has a REPLACE-WITH-DOMAIN /
                  TBD marker. Update ALL of them together once a domain
                  is chosen, not piecemeal.
CLAUDE.md         This file.
README.md
```

If the project grows past a single page, the next step is the
`/assets/css/`, `/assets/js/`, `/assets/images/` split mentioned in the
original handoff — don't do that split preemptively while it's still one
page.

## Known open items (don't invent answers to these — ask Shane)

- **Domain**: not selected. An earlier prototype referenced `keysi.com` —
  do not use it; it's both already registered and contains "SI", which
  is off-brand now.
- **Backend / CRM**: Shane has an existing database/system this will
  eventually connect to. Don't guess at its schema. When it's available:
  inspect it first, understand it, then build a secure API — validate
  inputs server-side, add spam protection and duplicate handling, track
  `source`/`landing_page`/`campaign`, and return real success/error
  states to the form.
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
