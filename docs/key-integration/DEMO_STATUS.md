# KEY Platform: what is demo and what is live

Updated 2026-11-02. Branch `claude/master-file-e6ofy0`. Everything below lives under `sites/key-technologies/key-platform/`.

## Colors (2026-11-02)
Site-wide palette, in the style of a well-known streaming service's navy and bright blue (colors only: no third-party names, logos or marks):
- Page background `#0f171e` (dark blue-black), inputs `#121a22`
- Cards and surfaces `#232f3e` (navy), borders `#37475a`
- Main accent and primary buttons `#00a8e1` (bright blue; buttons use dark `#0f171e` text for contrast)
- Deeper blue for solid fills with white text `#146eb4`
- Text: white and a cool gray `#aab9ca`
Font: Lato (free, open license, via Google Fonts) with system sans-serif fallbacks, as the closest free match to Amazon's own typeface "Amazon Ember", which is proprietary and not licensed for general website use. To change the font site-wide, replace `Lato` in the font-family stacks and the Google Fonts link in every page, then re-copy the homepage stylesheet into `key-platform/site-base.css`.

Logo (changed 2026-11-03 at Shane's request; header size set to 37x16 so the ring is about the height of the capital letters): an elegant classic mirror-gold key (polished-metal look, chosen by Shane), a round double-ring head, shaft with two collars and a stepped end, drawn with a banded mirror-gold gradient and white highlight lines (header, footer, favicon, `key-platform/assets/key-logo.svg`) with a soft gold glow. The link-preview and home-screen images use the same key with a soft glow; the link preview also has a large key on the right; the Mac owner pages (CRM, leads, advertisers) carry the same key and the site palette. Gold is the one deliberate exception to the otherwise navy-and-bright-blue palette. To change it, search for `viewBox="0 4 116 50"` (inline logos; each has its own gradient `id="kg…"`), the favicon data URI in each page head, and re-render the images (`og-image.png`, `apple-touch-icon.png`, `icon-192.png`, `icon-512.png`); the glow color is in the `.logo svg` rule (also copied in `key-platform/site-base.css`).

Not changed on purpose: the LVR Points gold, green and red status colors, the page `marketplace-demo.html` (deal stuff), and the raster images (`og-image.png`, `apple-touch-icon.png`). The old light blue `#59b5ff` is gone.

## Book a call, SEO and install (2026-11-03)
- **`/book.html`** (built by `docs/key-integration/build_book_page.py`): the visitor picks a day and time (Mon to Fri, 9:00 to 17:00 Pacific, 30-minute steps, 24 hours notice, 14 days ahead, shown in the visitor's time zone), enters name, email and optional phone, and the request is saved to the leads list (`key_leads/leads`, source `book-a-call`, with the time in UTC and Pacific) plus the same email alert as the other forms. Nothing is booked until Shane replies to confirm. A "tentative" calendar file is offered after sending. Hours, days and blocked dates are at the top of the page script. Every "Book a Call" button on the site now goes there.
- **SEO:** the main structured data now lists the 23 services (`hasOfferCatalog`; the Sales Partner Network prototype is left out); `book.html` is in the sitemap; missing descriptions, canonical links and share images were added to the legal, menu and LVR pages; the owner page-views page is `noindex`.
- **Install:** `site.webmanifest` with 192 and 512 icons so the site can be added to a phone home screen.

## Demos on Google and AI (updated 2026-11-03)
Indexable (no `noindex`, canonical, share tags, Service + FAQ + breadcrumb structured data, sitemap entry, plus a short "how it works / before it goes live / common questions" block whose text matches the FAQ structured data): the demo hub `/key-platform/`, Voice, Email and every service demo (23 service demos) plus the LVR Rewards demo. Text lives in `docs/key-integration/apply_demo_seo.py` (first six) and `demo_seo_more.py` (the rest); `build_service_demos.py` runs it after every rebuild. Still `noindex` on purpose: the Sales Partner Network demo and partner interest page (commission claims, not open for enrollment, waiting on attorney review), the old `points.html` redirect stub, the legal pages, the owner page-views page and the account page.
For AI assistants and AI search: `llms.txt` (plain-language site map), `robots.txt` names the major AI and search crawlers and allows them (owner and account pages excluded), sitemap has `lastmod` for every page. Nobody can guarantee a ranking or an AI citation; Google and AI tools decide. What speeds it up: submit `sitemap.xml` in Google Search Console, claim a Google Business Profile, link to keytechnologies.si from your Instagram bios, and get real reviews.

## Layout (rebuilt 2026-11-02)
The demos no longer use the package's own app shell (sidebar, separate header). Every page now uses the Key Technologies site header, mobile menu, banner and footer, the homepage stylesheet (`site-base.css`, a verbatim copy of the homepage CSS) and `kp.css` (demo components in the same style). Sections of each demo are horizontal tabs. If the homepage styles change, re-copy them into `site-base.css`.

## Demo for every service (added 2026-11-02)
Every service card on the homepage has a demo link. Pages live in `/key-platform/demos/` and are built by `docs/key-integration/build_service_demos.py` from `key-platform/demo-widgets.js`, all on the site shell. The hub (`/key-platform/`) lists them all (section "A demo for every service").

| Service | Demo |
|---|---|
| 01 Digital Content Creators | content-creators |
| 02 AI/SI Strategy | ai-strategy |
| 03 Business Automation | business-automation |
| 04 AI/SI Agents | ai-agents |
| 05 Custom CRM & Lead Management | custom-crm |
| 06 Customer Experience | customer-experience |
| 07 Operations | operations |
| 08 Data & Knowledge Systems | data-knowledge |
| 09 Marketing | marketing |
| 10 Security & Technology | security-technology |
| 11 Custom AI/SI Systems | custom-ai-systems |
| 12 AI/SI Website Development | website-development |
| 13 Email Automation | email/ (Email Intelligence) |
| 14 Social Media Management | social-media |
| 15 Review & Reputation Management | reviews-reputation |
| 16 AI/SI Phone & Text Answering | voice/ (Voice Services) |
| 17 Booking & Scheduling Automation | booking-scheduling |
| 18 AI/SI Training & Custom Training Software | ai-training |
| 19 Custom Website Programming | custom-programming |
| 20 ADA & Accessibility Compliance | accessibility-ada |
| 21 PHP & WordPress Migration | php-wordpress-migration |
| 22 Private LLM Setup | private-llm |
| 23 Cybersecurity & Network Hardening | cybersecurity |
| 24 Sales Partner Network | sales/ |
| LVR Points | points |

All are DEMO: fictional data, in-browser only, nothing saved or sent. The LVR Points demo uses sample points at made-up restaurants and follows the program wording (points, not cash; food only; free spin comes and goes; monthly points share; use your points before the 1st).

## Finding demos
"Demos" is the first item in the Explore list of the menu (hamburger) on every page, and a link in the footer. It opens the demo library on the hub (`/key-platform/#library`). The library reads `/key-platform/demos/list.json`, which `build_service_demos.py` writes, so a new demo appears there after it is added to that script and the script is run. (The three older demos Email, Voice and Sales are appended to the list by the script.)

## Demo gallery and tap sound
The hub library is a gallery of numbered tiles (01 to 24, LVR) with group filters (Marketing & Content, AI Systems & Strategy, Operations & Sales, Customers & Communication, Websites & Security, Training & Points). Groups come from `CAT` in `build_service_demos.py`. Every demo page has "All demos" at the top and previous/next links at the bottom. `kp-sound.js` plays a soft tap (made in the browser, no audio files) when a demo link or button is pressed, with a "Sound: on/off" switch on the platform pages that is remembered in the browser.

## Tile previews, tour and follow-up (added 2026-11-02)
- **Previews:** each gallery tile shows a small picture of its demo, made by `docs/key-integration/make_demo_thumbs.js` into `key-platform/demos/thumbs/`. Re-run it after a demo changes look.
- **Tour:** "Start the tour" on the hub (`kp-tour.js`) walks through all 25 demos in order with a bar at the bottom (Back, Next, End tour, progress; arrow keys work). Tour state lives only in the browser tab.
- **Follow-up:** each demo ends with "Want this for your business?" (`kp-followup.js`): the visitor's email and optional name go to the site's existing leads list (`key_leads/leads`, source `demo-follow-up`, with the demo name) and the same email alert as the other site forms. Nothing is sent until the visitor presses the button. Tested only against a mock, so check one real submission.

## Imported from the handoff package
| Module | Page | Source | Changes made on import |
|---|---|---|---|
| Voice Services | `/key-platform/voice/` | package `voice/public` (v4) | rebuilt on the site shell and styles, official key logo, `noindex` |
| Email Intelligence | `/key-platform/email/` | package `email/public` (v1) | same, plus the "Integration plan" developer page removed |
| Sales Partner Network | `/key-platform/sales/` | package `sales/public` (v1) | same, plus the "Integration roadmap" developer page removed |
| Hub | `/key-platform/` | original | three demos, shared catalog with states, partner program summary |
| Shared catalog | `/key-platform/catalog.js` | original | one list (9 offerings, states draft/prototype/approved/available/retired) used by the hub and the Sales demo; all are draft or prototype today |
| Partner interest list | `/key-platform/partners.html` | original | free interest form, same lead path as the other site forms (`key_leads/leads`, source `partner-interest-list`); not an application, not a job offer |
| Homepage | `index.html` section `#platform` | original | KEY Platform section, three demo links, catalog and partner links |

Also removed from public pages: wording written for developers (references to the owner's coding project, "integrate into your repo" notes).

Not imported on purpose: the package `server.mjs` (a dev preview server), the package tests (they test the package folder layout, not this site), and the screenshot-derived logo PNGs (the official logo is used instead).

## Status list
| Capability | State |
|---|---|
| All screens, sample data, scripted conversations, calculators | DEMO (fictional data, runs in the browser) |
| Browser speech playback on the Voice demo | DEMO (browser feature, not a phone line) |
| Phone line, call answering, call recording | NOT CONNECTED |
| Mailbox connection, reading or sending email | NOT CONNECTED |
| Calendar booking | NOT CONNECTED |
| Quotes, billing, payments, payouts, commission payments | NOT CONNECTED (estimates only) |
| Sales partner accounts and sign-in | NOT BUILT (no logins exist) |
| Partner interest form | LIVE (saves name, email, city, notes to the leads list like the other site forms; tested against a mock only) |
| Links to the real CRM (`kt_crm`, `key_leads`) | NOT CONNECTED |
| Database tables for any module | NONE ADDED |

Demo state is kept only in the visitor's own browser (`localStorage` keys `key.voice.v3.*`, `key-sales-concept-v1`, `key_email_demo_v1`). Nothing is sent to any server.

## Rules kept
- Blue-only palette. A colour scan of every screen at phone, tablet and desktop widths found no brown, tan, beige, amber or green.
- No PIN, password or key in any file.
- Demo people, businesses, numbers and prices are fictional and labeled.
- No change to the existing CRM, rules, or the points program.

## Still needed before anything goes live (needs Shane's approval each time)
1. Backend decision (see INTEGRATION_MAP.md): the real site is static pages plus a shared Firebase database, not the server-and-tenant design the package assumes.
2. Real sign-in for partners and clients (the owner sign-in is built but not yet switched on).
3. Attorney review of the partner commission terms and the five tiers (worker classification, recurring commissions, disclosure rules).
4. Recording and AI-disclosure consent rules before any real call; read-only mailbox permission review before any real inbox.
5. Real pricing and costs: package prices are illustrative.

## Homepage speed and polish (2026-11-03)
- **Fonts are hosted on the site** (`/fonts/lato-*.woff2` plus `/fonts/lato.css`, Lato under the SIL Open Font License) instead of loaded from Google, so text no longer waits on a third party. The homepage inlines the font rules and preloads the two main weights. The demo pages used to ask Google for an unused font (Inter) and never loaded Lato; they now use the hosted Lato. Only the deal page (`marketplace-demo.html`) still loads Google fonts, on purpose.
- **Measured** on a simulated slow phone (slow 4G, processor at a quarter speed): first content visible about 0.5 s (was 0.6 to 1.5 s depending on the run), no layout shift, blocking time under 80 ms. The page is about 31 KB compressed.
- `kp-sound.js` loads with `defer`. Sections far below the first screen use `content-visibility:auto`, so the browser draws them only when scrolled near.
- **Background watermark key removed (Shane, 2026-11-03): too distracting.** The hero and closing banner now have no background key.
- **Small label keys** (beside "SERVICES", "KEY Platform", etc.) are the same mirror-gold key as the logo, with the label text staying blue. Every key on the site is gold.
- **Homepage additions:** a trust strip under the hero (25+ years, 23 services with demos, free review, locations), a "See it work" row with six demo previews linking to the live demos, a sticky "Book a Free Call" button on phones (appears after the first screen, hides over the two forms and when the menu is open), and soft fade-in motion as sections scroll into view (off for reduced-motion settings; the text is always in the page for search engines).
- **Testimonials:** there is deliberately no quote yet. A note in the page source ("TRUST STRIP") says where one goes. Use only a real quote with written permission.

## Guides (added 2026-11-03)
`/guides/` (hub) plus three guides, all built by `docs/key-integration/build_guides.py` on the site shell and added to `sitemap.xml` and `llms.txt` by that script: **PHP2Shell: what small-business website owners should do now** (facts checked against the PHP project's release notes on 2026-11-03: two critical flaws, fixed Oct 21, 2026 in PHP 8.5.12, 8.4.27, 8.3.36, 8.2.35), **How much does an AI receptionist cost?** (cost drivers and vendor questions only, no prices, because pricing is on hold), **AI for restaurants: 6 practical ways to save time** (each use links to its demo). Each page has Article, FAQ and breadcrumb structured data. Linked from the homepage menu, footer and a "Guides" row above the FAQ.
- **Keep fresh:** the PHP2Shell guide is time-sensitive. Re-check php.net before editing, then update the text and `DATE` in the script and re-run it.
- To add a guide, add an entry in `build_guides.py` and run it.
