# KEY Platform: what is demo and what is live

Updated 2026-11-02. Branch `claude/master-file-e6ofy0`. Everything below lives under `sites/key-technologies/key-platform/`.

## Imported from the handoff package
| Module | Page | Source | Changes made on import |
|---|---|---|---|
| Voice Services | `/key-platform/voice/` | package `voice/public` (v4) | official key logo (SVG), `noindex`, back-link to the main site |
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
