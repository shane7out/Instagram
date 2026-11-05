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
- `kp-sound.js` loads with `defer`. (`content-visibility:auto` was tried and removed: it made menu links such as Free Website Audit land in the wrong place.)
- **Background watermark key removed (Shane, 2026-11-03): too distracting.** The hero and closing banner now have no background key.
- **Small label keys** (beside "SERVICES", "KEY Platform", etc.) are the same mirror-gold key as the logo, with the label text staying blue. Every key on the site is gold.
- **Homepage additions:** a trust strip under the hero (25+ years, 23 services with demos, free review, locations), a "See it work" row with six demo previews linking to the live demos, a sticky "Book a Free Call" button on phones (appears after the first screen, hides over the two forms and when the menu is open), and soft fade-in motion as sections scroll into view (off for reduced-motion settings; the text is always in the page for search engines).
- **Testimonials:** there is deliberately no quote yet. A note in the page source ("TRUST STRIP") says where one goes. Use only a real quote with written permission.

## Guides (added 2026-11-03)
`/guides/` (hub) plus three guides, all built by `docs/key-integration/build_guides.py` on the site shell and added to `sitemap.xml` and `llms.txt` by that script: **PHP2Shell: what small-business website owners should do now** (facts checked against the PHP project's release notes on 2026-11-03: two critical flaws, fixed Oct 21, 2026 in PHP 8.5.12, 8.4.27, 8.3.36, 8.2.35), **How much does an AI receptionist cost?** (cost drivers and vendor questions only, no prices, because pricing is on hold), **AI for restaurants: 6 practical ways to save time** (each use links to its demo). Each page has Article, FAQ and breadcrumb structured data. Linked from the homepage menu, footer and a "Guides" row above the FAQ.
- **Keep fresh:** the PHP2Shell guide is time-sensitive. Re-check php.net before editing, then update the text and `DATE` in the script and re-run it.
- To add a guide, add an entry in `build_guides.py` and run it.

## Founder photo (added 2026-11-03)
Shane's photo is in the About section (`images/shane-christensen.jpg` 528x600 and `-320.jpg`), lazy-loaded with a small and a full size, and set as the founder's `image` in the page's structured data. To swap it, replace those two files (keep the names) or edit the `<figure class="about-photo">` block.

## City pages (added 2026-11-03)
`/las-vegas.html`, built by `docs/key-integration/build_city_pages.py` (shared styles in `key-platform/site-extra.css`). Uses only facts already on the site (no invented clients, statistics or rankings): hero with a "what you get in a free call" card, trust strip, why Las Vegas, six demo previews, industries (restaurants guide, medical, law, real estate, e-commerce), Shane's restaurant background with photo, how it works, guides, six FAQs with structured data, and a closing call to action; sticky Book a Free Call on phones. Linked from the homepage Locations card, phone menu and footer, and listed in the sitemap and `llms.txt`. `/manhattan-beach.html` and `/los-angeles.html` use the same design and only facts already on the site (Manhattan Beach, the South Bay, Los Angeles and Southern California are served; in person around home markets, online anywhere); they have a "Meet Shane" section instead of the Las Vegas restaurant section and an "Other locations" row linking the three pages. To add another city, add an entry to `CITIES` (use `ca_city(...)` for a California city) with true local details and run the script. Sticky Book a Free Call on phones is a compact centered pill (set in `site-extra.css` and the homepage styles).

## Testimonials (set up 2026-11-03, nothing shown yet)
Testimonials are their own category: a dedicated page (`/testimonials.html`, meant to rank on its own) plus a three-quote block on the homepage with a "See all" link; they are deliberately NOT on the city pages. Built by `docs/key-integration/build_testimonials.py` from `sites/key-technologies/testimonials.json` (a list; the file is `[]` now). **Only entries with `"permission": true` are ever shown.** With no permitted entries the page, the homepage block, the footer link and the sitemap/llms.txt entries do not exist. To add one: put a real quote with the client's written permission in `testimonials.json` (see `testimonials.example.json` for the format; `"featured": true` picks the three for the homepage) and run the script. No star-rating markup is added. Keep the written permission on file, and disclose any payment, discount or other connection to the client (the FTC treats that as a disclosure item).

## Worldwide and any language (2026-11-03)
Footer fine print everywhere now reads "Manhattan Beach, California · Las Vegas, Nevada · Remote worldwide · Any language" (it used to say "Remote nationwide"; the link-preview image was remade too). "No language barrier" is pushed on the homepage: a line under the hero buttons, the fourth trust card ("Worldwide, any language"), a dedicated section (`#languages`) with greetings in 16 languages, a FAQ ("Can you work with me in my language?", also in the FAQ structured data), the page's search description, `llms.txt`, a FAQ on each city page, and an optional "Preferred language" box on the Book a Call form (saved with the request as `language`). Wording is deliberately "virtually any language, in writing and by voice" plus a note that legal or medical documents should also get a certified human translator, so the claim stays defensible.

## Home link everywhere (2026-11-03)
Shane found that on Book a Call and in the KEY Platform tabs there was no obvious way back to the homepage. Now every inner page has a plain **Home** link:
- first chip in the KEY Platform tab row (Home, Overview, Voice, Email, Sales, Partner list),
- first item in the desktop header menu,
- first item in the phone menu (above Demos).
It is added by `docs/key-integration/add_home_link.py`, which is idempotent and skips the homepage. **Run it last**, after the other generators (`build_book_page.py`, `build_service_demos.py`, `build_guides.py`, `build_city_pages.py`, `build_testimonials.py`), because those rebuild pages from templates that do not contain the Home link. The desktop menus also get slightly tighter spacing between 861 and 1100 px so the extra item never wraps.

### Always-visible Home button (same day)
Shane asked to be able to go to the homepage "anytime", so the top bar of every inner page now also shows a **Home** button (house icon) next to the menu button whenever the menu button is shown. On phones (480 px and narrower) it is icon-only so nothing is pushed off the screen; below 340 px it is hidden (the logo is still a Home link and the menu still lists Home). On the Rewards app pages (My Account, Menu) it is a plain Home button. `add_home_link.py` adds all of it; the CSS lives in `key-platform/site-base.css` and the inline CSS of the homepage, industry, rewards and join-restaurant pages. Checked at 320, 360, 390, 430, 768, 1000 and 1200 px: nothing overflows or overlaps.

### Home on every page, including the homepage, and the pop-up Home pill (same day)
Shane: "I need it even on the home page. When I start scrolling a little bit I want the home button up top to pop up. Across all pages."
- The **homepage** now has the Home button in its top bar too (house icon, plus Home in the desktop menu and the phone menu). On the homepage it scrolls smoothly to the top instead of reloading.
- The Home button is **never hidden any more**: it fits at 320 px (smaller wordmark and buttons) instead of disappearing on tiny screens.
- Pages whose top bar scrolls away (Privacy, Terms, Rewards terms/privacy, Spin terms, Rewards Menu, deal page) load `key-platform/home-pop.js`: a "Home" pill that pops in at the top right after about 60 px of scrolling, with a short slide (no slide if the visitor prefers reduced motion). Every other page keeps its sticky top bar with the Home button in view all the time.
- The three legal-page generators (`.github/db-task/gen-points-terms.js`, `gen-points-privacy.js`, `gen-spin-terms.js`) now add the pill's script tag, so regenerating keeps it.
- Verified: scrolling every page at 390 px and 1280 px always leaves a visible way home; the top bar fits at 320/360/390/430/768/1000/1200 px; accessibility check clean on the changed pages.

## Lead sending hardened (2026-11-03, found in a code inspection)
Problem found: every form saved the lead to the database first and only sent the email alert (Formspree) after that save worked. If the database was down, locked or over quota, the visitor saw an error AND Shane got no alert, so the lead was simply lost. The alert email also contained a meaningless `createdAt: {".sv":"timestamp"}` line (a database-only placeholder).
Fix: new shared helper `key-platform/lead-send.js` (`KTLead.send(dbUrl, formspreeUrl, data[, extra])`). It tries both at the same time, shows the visitor success if EITHER worked, and an error only if BOTH failed. The email copy drops the placeholder and gets a readable `submittedAt` instead. Used by: the homepage short/full lead forms and the Free Website Audit log, the four industry pages (law, medical-dental, ecommerce, real-estate), Book a Call (`build_book_page.py` generator updated), Join Restaurant, the Rewards waitlist, the partner interest list and the demo follow-up form (`kp-followup.js`, script tag added to all 25 demo/platform pages and to `build_service_demos.py`). Not changed on purpose: the LVR Rewards account sign-up flow (its alert already runs independently of the account save).
Tested with simulated services in three situations each (all fine / database down / all down): success message, honest error with the button re-enabled, and the clean alert email.
Alert emails now get a readable subject automatically (`New lead: <name> (<source>)`, for example "New lead: Maria Lopez (book a call)"); Join Restaurant keeps its own subject.


## Owner PIN removed from the public site (2026-11-03)
`key-pageviews.html` no longer has a PIN or any code that checks one: it opens only for the signed-in owner (same sign-in box as the Mac owner tools). Until Shane runs `owner-login.sh` (owner sign-in not set up yet) the page shows the "Owner sign-in" screen and cannot be opened. The homepage comment about "PIN-gated" was updated. `grep -rn 137900 sites/` finds nothing. Full plan and order of steps: see "KEY TECHNOLOGIES OWNER LOGIN, PHASE 2" in `.github/db-task/LVR-PROJECT-STATUS.md`.

## Language wall moved, city links trimmed, wording fix (2026-11-05, Shane: "take out all those languages ... put it in the drop down ... get rid of Los Angeles / Manhattan Beach ... looks funny")
- The homepage "No language barrier" section (16 greeting chips) is gone, and so are the hero line "Worldwide, in any language", the "any language" wording in the trust strip, the homepage meta description and the footer line ("... Remote worldwide · Any language" is now "... Remote worldwide"). The city pages' "in any language" stat line is gone too (`build_city_pages.py`).
- The same information (same copy, nothing new claimed) now lives on **/languages.html**, built by `docs/key-integration/build_languages_page.py` (also adds it to `sitemap.xml` and `llms.txt`). It is linked from the **phone menu** (right after Guides) and the **footer**, not from the desktop top menu. Its CSS is in `key-platform/site-extra.css`.
- Kept on purpose: the FAQ "Can you work with me in my language?" (HTML and its FAQPage JSON-LD), and the llms.txt sentence (AI search).
- Booking form: "Preferred language" is now a **dropdown** (English, Español, 中文, 한국어, 日本語, Tiếng Việt, Filipino, Français, Português, Italiano, Deutsch, Русский, العربية, हिन्दी, Türkçe, Ελληνικά, Another language). It is still saved as `language`, so the lead and the alert email carry it. Source: `build_book_page.py`.
- **Los Angeles and Manhattan Beach** were removed from the phone menu and footer lists on every page (Las Vegas stays). The two city pages stay online and in the sitemap; only the menu/footer links are gone. Laguna Beach was never linked anywhere. The homepage "Locations" cards and the cross-links between city pages still point to them.
- The desktop header button that said "Contact" now says **Book a Call** (goes to the booking page); book.html keeps "Contact". The desktop menu spacing rule now covers 861 to 1280 px so the longer button never makes a label wrap.
- Mistake found and fixed: the earlier points-to-rewards rename had changed ordinary wording in the Operations service card ("the specific points where automation ... would help" had become "rewards"), on the page and in its search-engine copy. Fixed in `index.html`.
- All of the nav changes are done by `docs/key-integration/tidy_nav.py`, so **run it last**, after `add_home_link.py`, after the other generators. Full order: build_book_page, build_service_demos, apply_demo_seo, build_guides, build_city_pages, build_testimonials, build_languages_page, add_home_link, tidy_nav.

### Floating "Book a Call" button removed (2026-11-05, Shane: "to have it right there on the bottom, always staring at me, I don't think I want that")
The phone-only floating "Book a Free Call" bar (`#stickyCta`) is gone from the homepage, the three city pages and the Languages page: markup, CSS (`index.html`, `key-platform/site-extra.css`), its script and the extra bottom page padding it needed. It is also removed from the page generator (`build_city_pages.py`), so rebuilding will not bring it back. People can still book through: the **Book a Call** item at the top of the phone menu, the header **Book a Call** button on desktop, the small "Book a Call" link in the footer, and the on-page contact forms (the homepage forms, and each industry page's own form). Nothing in the page's scripts depended on it.

### Founder card in the top section (2026-11-05, Shane: "my face needs to be near the top")
A small card sits right under the two main buttons in the homepage top section: round photo (`images/shane-christensen-320.jpg`, 64 px), "Shane Christensen" and "Founder of Key Technologies · meet Shane →", linking to the About section (`#about`). It is above the first screen on phones and on computers; CSS is `.founder-chip` in `index.html`. No new claims (the "42+ years" line stays in the trust strip below it). Speed unchanged (first content about 0.6 s, no layout shift); accessibility check clean.

### Manhattan Beach and Los Angeles pages taken offline; "Book a Call" lives in the Contact section (2026-11-05, Shane)
- **City pages retired quietly.** `manhattan-beach.html` and `los-angeles.html` are now tiny redirect pages (noindex, send visitors to the homepage Locations section); their content, sitemap entries and llms.txt lines are gone; the homepage Locations card no longer links to them; the Las Vegas page no longer shows an "Other locations" row. `build_city_pages.py` now only builds Las Vegas and rewrites the two redirect pages (`RETIRED` list) on every run, so a rebuild cannot bring the pages back. To bring one back later: add its `ca_city(...)` entry to `CITIES` again and remove it from `RETIRED`.
- **Kept on purpose** (statements about where the business is based, not the pages): the footer line "Manhattan Beach, California · Las Vegas, Nevada · Remote worldwide", the homepage Locations card text, the industry-page copy and the `areaServed` / address data in the search-engine profile.
- **Book a Call placement.** The floating bar is gone for good. In its place the Contact section ("Tell us about your business") now opens with a "Prefer to talk? Pick a time for a free call. No obligation." strip and a Book a Free Call button (reuses `.demo-strip`; `.demo-strip a.btn-primary` keeps the button text readable).

- Founder card (homepage hero) made about half size: a small 36 px square face crop (own files images/shane-christensen-face-72.jpg and -108.jpg, cropped tight on the face from the original, resized with a light sharpen only, no retouching). Click-through test: 291 clicks, 0 errors.
- Business-count wording: Shane confirmed he keeps an eye on about 10,000 restaurants; homepage now says 'about 10,000 restaurants, mainly in Las Vegas and Orange County'; the 4 industry pages say 'about 10,000 restaurants'. Footer 'Manhattan Beach, California · Las Vegas, Nevada' stays (Shane's decision).
