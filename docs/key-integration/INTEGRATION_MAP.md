# KEY Technologies.si: integration map for the Voice / Email / Sales modules

Status: **inventory and plan only (2026-11-02). Nothing imported, nothing deployed.** Written against the real repository
(`shane7out/Instagram`, branch `claude/master-file-e6ofy0`), not against assumptions.

## 0. Blockers before any import

1. **The package is not here.** `voice/`, `email/`, `sales/`, `reference/website_homepage.png`, `reference/two_page_portrait_concept.png` and the three
   `CLAUDE_CODE_HANDOFF.md` files are not in the repository or in this session's uploads (searched `/`, the repo and the upload folder). I only have the master
   handoff text. Please re-send the package (zip, or attach the folders) before Phase 1.
2. **Architecture mismatch (decision needed).** The handoff assumes a framework with routes, roles, tenant-scoped schema, server-side authorization, webhooks,
   OAuth and payments. The real KEY stack is different (section 1). Voice, Email and Sales all need **server code** the current stack does not have.
3. **Branch rule.** This session is tied to `claude/master-file-e6ofy0` and may not push other branches without your OK. The handoff asks for a feature branch.
   Until you say otherwise, new work goes under `key-platform/` on this branch, behind feature flags, and is never deployed by the existing Pages workflow
   (the workflow publishes `sites/key-technologies/` only).

## 1. Repo inventory (what actually exists)

| Area | Reality today |
|---|---|
| Public site | `sites/key-technologies/`: static single-file HTML pages, GitHub Pages + custom domain keytechnologies.si, deployed by `.github/workflows/key-technologies-pages.yml` on push. No framework, no build step, no routes layer. |
| Services content | `index.html` section `#services`: 23 static cards (01 Digital Content Creators ... 23). Includes **AI/SI phone & text answering**, **Email automation**, **Social media management**, **Custom CRM & lead management**, **Review & reputation management**. No data-driven catalog and no draft/prototype/approved/available states. |
| Lead capture | Forms on `index.html`, `rewards.html`, `join-restaurant.html`, audit tool write to Firebase RTDB `key_leads/leads` (+ Formspree email). |
| Master data store | One Firebase Realtime Database (`lvr-data-a60c1`), shared by every property. Free (Spark) plan: **no Cloud Functions, no server**. Rules are being tightened (LVR sections only; other nodes still permissive). |
| CRM | `kt_crm/prospects` (`kt-crm.html`), `key_leads` (`key-leads.html`), `key_advertisers` (`key-advertisers.html`), plus the LVR dashboard's own restaurant/advertiser/influencer nodes (`dashboard_*`). These are separate stores today, not one contact/company model. |
| Owner console | `key-room.html` and the dashboard on Firebase Hosting (`lvr-data-a60c1.web.app`), deployed from the owner's Mac by the scripts in `.github/db-task/mac/`. |
| Auth / roles | **Client-side PINs** (owner, co-editors, a limited guest). The owner PIN hash is in page source; sessions are browser storage. There is no server-enforced role model and no tenant concept. A Firebase Auth owner login is in progress (`owner-auth`, `owner-setup.sh`): it is blocked on the free plan until Email/Password is enabled in the console, and it only helps the LVR sections' rules. |
| Python | Repo root (`dashboard.py`, `bot_worker.py`, `database_models.py`, Railway/Streamlit): the separate Instagram-automation product (Postgres). Not connected to the web properties. |
| Other product line | LVR Points (`lvr_rewards`, `lvr_points`, `my-account.html`, `rewards.html`): a separate program with its own referral rules. **Do not merge it with the Sales Partner Network or its commissions.** |
| Logo | Inline SVG blue key in each page header (`#168fff`), plus `apple-touch-icon.png` / `og-image.png`. There is no standalone official vector file in the repo; locate the owner's original before using any screenshot-derived icon. |
| Design tokens | `index.html` already uses the near-black navy / blue palette the handoff describes. LVR Points pages additionally use **gold/yellow/red** accents (wheel, tags, pills). |

## 2. Overlaps and route/entity map

| Handoff item | Existing overlap | Proposed mapping |
|---|---|---|
| Voice Services (AI receptionist) | Service card "AI/SI phone & text answering"; checkbox in the lead form | Demo page `key-platform/voice/` (clearly fictional); card links to it. Real phone handling needs a server + telephony provider. |
| Email Intelligence | Service card "Email automation" | Demo page `key-platform/email/`. Real mailbox sync needs OAuth and a server. |
| Sales Partner Network | None (no rep portal). LVR referral bonus is separate. | New `key-platform/sales/` demo; real rep portal needs auth + server. |
| Services catalog with states | Static cards only | New additive node `catalog/services/{id}` with `state: draft/prototype/approved/available/retired`; the page renders only approved/available as "live". Cards 01-23 become the seed (all `prototype` or `planned`). |
| Contact / company / deal / quote / subscription | `kt_crm/prospects`, `key_leads/leads`, `key_advertisers` | One reviewed mapping table first (no data copied): prospects -> contact+company, leads -> lead, advertisers -> company+subscription. Add only additive nodes; no second customer database. |
| Roles (owner, admin, rep, team lead, client) and tenants | PINs, no tenant | Cannot be done honestly without server-side auth. See section 3. |
| Commission ledger | None | Model-only ledger (`estimated/held/earned/paid/reversed`, idempotent, immutable refs), no payouts. |

## 3. Decisions I need from you (the plan depends on them)

1. **Backend.** Voice (webhooks, call handling), Email (OAuth, read sync, audited send), Sales (roles, commission ledger, billing) all need server-side code.
   Options: (a) Firebase Blaze + Cloud Functions (you declined Blaze earlier, tell me if that still holds), (b) a small Python/Node service on Railway
   (you already run one), with its own authenticated API in front of the existing database, (c) stay front-end-only and build **demos only**.
   My recommendation: (c) now for Phase 1, then (a) or (b) before any real data, because roles and tenant isolation cannot be enforced in static pages.
2. **Design rule scope.** "No brown/tan/beige/sepia/amber-brown, blue-only accents" for the three new KEY modules only, or for the whole keytechnologies.si
   domain (which would mean removing the gold/yellow/red from LVR Points pages)? I will treat it as **new KEY modules only** unless you say otherwise.
3. **Feature branch.** Allow a `feature/key-platform` branch, or keep everything on the current branch under `key-platform/`?
4. **Official logo.** Where is the original standalone blue key logo file?

## 4. Phased plan (maps to the handoff, adjusted to reality)

**Phase 0 (now, safe):** this inventory; seed the services catalog data model (docs only); decide section 3. No code touching production.

**Phase 1: demos only.** Import the three UIs as static, branded pages under `key-platform/{voice,email,sales}/` with a visible "Demo, fictional data" banner,
mobile-first, blue-only palette, shared header/footer matching `index.html`, feature flag off by default and excluded from the sitemap until approved. Add a
shared `services catalog` JSON rendered by the existing services section. Tests: responsive (360/390/768), axe, no-brown colour scan, no console errors.

**Phase 2: CRM mapping + rep workflow (needs backend decision).** Entity map migration (additive), authenticated rep portal, permissioned pipeline, proposal
builder from approved catalog only, attribution, commission *estimates* (no payouts), owner reporting. Tests: authorization, tenant isolation, commission math
(refund/cancel/chargeback reversals, idempotency).

**Phase 3: Email.** Provider OAuth, read-only sync, normalization, grounded draft replies, human approval, audited manual send after policy review.

**Phase 4: Voice.** Sandbox number, verified webhooks (replay protection), consent and recording rules, human fallback, usage budget; no real bookings until
calendar confirmation.

**Phase 5: Billing and launch.** Payment processor, invoicing, reconciliation, commission eligibility, supervised pilot, backups, observability, rollback.

## 5. Compensation model (for the sales module; not executed)

Modelled only: 50% of defined commissionable collected revenue on a rep's own attributed customers (net of approved direct variable costs and refunds),
five proposed tiers (partner, senior, team leader, regional director, national director), no reward for recruitment alone, no earnings guarantees.
**Needs an attorney before any real rep is onboarded:** worker classification by state, the contractual definition of commissionable revenue, any
team-leadership bonus (multi-level compensation rules), and tax reporting.

## 6. Security and demo-data rules carried over

No personal PIN/password in source, docs, browser or tests (note: the existing owner PIN hash and PIN-style access in the dashboard predate this rule and
should be replaced by real sign-in); voice/email inbound treated as untrusted; no live sending, booking, telephony, charges or payouts until separately
reviewed; demo data labelled fictional and never written to the production database.

## 7. Environment variable reference (names only, none set)

`TELEPHONY_ACCOUNT_ID`, `TELEPHONY_AUTH_TOKEN`, `TELEPHONY_WEBHOOK_SECRET`, `EMAIL_OAUTH_CLIENT_ID`, `EMAIL_OAUTH_CLIENT_SECRET`, `EMAIL_OAUTH_REDIRECT_URI`,
`PAYMENT_PROCESSOR_KEY`, `PAYMENT_WEBHOOK_SECRET`, `CALENDAR_OAUTH_CLIENT_ID`, `CALENDAR_OAUTH_CLIENT_SECRET`, `DATABASE_URL`, `OWNER_AUTH_ISSUER`,
`FEATURE_KEY_VOICE`, `FEATURE_KEY_EMAIL`, `FEATURE_KEY_SALES`. These do not exist yet; they become real only with a backend.

## 8. What is demo-only vs connected today

Connected today: static site, lead forms to the shared database, LVR Points (separate product). **Everything in Voice, Email and Sales is not built and not
connected.** The delivered demos, once received, will be demo-only.
