# Christensen Coins — SEO-First Coin Marketplace

A fast, SEO-optimized marketplace for rare and collectible coins, built on the
**aggregate-and-mark-up** model: pull certified-coin listings from the world's
top dealers/auction houses, present them in one beautiful catalog at a markup,
and fulfill orders by sourcing the coin on demand and shipping it on.

Built with **Next.js 15 (App Router) + TypeScript + Tailwind CSS**. Every page
is statically prerendered for maximum speed and search ranking.

> **Brand lives in one file.** Everything brand-related is in
> [`src/lib/site.ts`](src/lib/site.ts) (`name`, `domain`, `url`, contact,
> socials). Change those (and the monogram in `src/components/Logo.tsx` /
> `src/app/icon.svg`) to rebrand the entire site.

---

## Quick start

```bash
cd coin-marketplace
npm install
npm run dev        # http://localhost:3000
```

Other commands:

```bash
npm run build      # production build (statically prerenders all pages)
npm run start      # serve the production build
npm run import     # run the coin importer (dry-run / fixtures by default)
npm run typecheck  # tsc --noEmit
```

---

## What's inside

### Pages (all SEO-optimized, statically generated)

| Route | Purpose |
| --- | --- |
| `/` | Premium homepage: hero, categories, featured, how-it-works, new arrivals |
| `/coins` | Full catalog with faceted filtering, search & sort |
| `/coins/[slug]` | Individual coin listing — the money page (Product schema, specs, buy panel) |
| `/category/[slug]` | Category landing pages (US Coins, Gold, Silver Dollars, Ancient, World, Type) |
| `/buy` + `/buy/[slug]` | **Programmatic SEO** landing pages (see below) |
| `/sell` | Sell-your-coins lead capture |
| `/how-it-works` | Trust/FAQ page (FAQ rich-result schema) |
| `/about` | About/brand story |
| `/sitemap.xml`, `/robots.txt`, `/manifest.webmanifest` | Auto-generated |

### The three pillars

**1. Markup pricing engine** — [`src/lib/pricing.ts`](src/lib/pricing.ts)
Turns a dealer's `sourcePrice` into our marketplace `price` with a **flat 35%
markup** — a coin the dealer lists at $100 sells here for exactly $135. The
percentage lives in one constant (`MARKUP_PERCENT`), so the whole catalog
re-prices by changing one number. Rounding is `exact` by default (honest, cent-
accurate); `dollar` and `charm` modes are available if you want retail endings.

**2. Pluggable scraper / importer** — [`src/lib/sources/`](src/lib/sources/)
- `types.ts` — the `SourceAdapter` contract every dealer integration implements.
- `base.ts` — shared HTTP + field parsers (year, mintmark, grade, metal, price).
- `moneymetals.ts` — **live adapter for Money Metals Exchange**: sweeps their
  category pages and extracts listings via schema.org JSON-LD (with a
  price/name heuristic fallback). Ships a grounded 20-coin snapshot as fixtures.
- `heritage.ts` — a second worked example adapter.
- `importer.ts` — pulls from all adapters, applies the 35% markup, maps
  categories (metal/country-aware), dedupes across sources (cheapest wins),
  emits marketplace `Coin`s + a margin report.
- Add a new dealer by dropping in one file that extends `BaseSourceAdapter` and
  registering it in `sources/index.ts`.

The catalog is seeded with **20 top-selling coins from Money Metals Exchange**
(see `src/data/moneymetals-listings.ts` → mapped to live coins in
`src/data/imported.ts`), each marked up 35%.

Run the pipeline end-to-end right now (no network needed — uses fixtures):

```bash
npm run import -- --source=moneymetals --limit=20
# ▶ Importing coins (dry-run / fixtures)
#   moneymetals   fetched 20  imported 20
#   source value: $24,947   list value: $33,678   margin: $8,731  (= +35%)
```

Refresh with a **live** pull on any machine with normal network access
(this build sandbox blocks outbound fetches):

```bash
npm run import -- --source=moneymetals --limit=20 --live --out=src/data/imported.json
```

**3. Programmatic SEO** — [`src/lib/landing.ts`](src/lib/landing.ts)
The "rank #1 for everything" engine. It derives a landing page for every
high-intent search phrase from live inventory:
- `…-for-sale` per series (e.g. `/buy/morgan-dollar-for-sale`)
- per metal (`/buy/gold-coins-for-sale`)
- per grading service (`/buy/pcgs-certified-coins`)
- per year+series long-tail (`/buy/1889-morgan-dollar-for-sale`)
- themed/intent pages (key dates, investment gold, coins under $500)

Each page is a real, useful, uniquely-worded filtered view — not thin doorway
spam — and is added to the sitemap automatically. Add inventory → new ranking
pages appear; sell out → the page stops generating.

### Technical SEO baked in
- **schema.org JSON-LD** everywhere: `Organization`, `WebSite` (+ Sitelinks
  search box), `Product` (price/availability/returns/shipping), `BreadcrumbList`,
  `ItemList`, `FAQPage`. See [`src/components/JsonLd.tsx`](src/components/JsonLd.tsx).
- Per-page `<title>`/meta/canonical/Open Graph via the Next.js Metadata API.
- Dynamic `sitemap.xml` + `robots.txt` (faceted URLs disallowed to avoid
  duplicate-content dilution; canonical money pages indexed).
- Deep, crawlable internal linking (footer, breadcrumbs, related coins,
  "related searches" hubs) to spread link equity to money pages.
- Fully static prerender = fast Core Web Vitals.

---

## Data model

`Coin` ([`src/lib/types.ts`](src/lib/types.ts)) is the normalized listing.
Sample inventory lives in [`src/data/inventory.ts`](src/data/inventory.ts) as
*source* prices; the markup engine computes the sale price at load, so there's a
single source of truth for pricing. The read model
([`src/lib/catalog.ts`](src/lib/catalog.ts)) is the only thing pages touch — swap
its backing store for a DB/CMS later without changing the UI.

Coin visuals are rendered as self-contained SVG **medallions**
([`src/components/CoinMedallion.tsx`](src/components/CoinMedallion.tsx)) derived
from each coin's metal/series/year — so the site looks finished with zero
external image dependencies. Real sourced photos drop into `coin.images` and
take over automatically.

---

## Going live — a checklist

1. **Rebrand**: edit `src/lib/site.ts` (name, domain, phone, email, socials).
2. **Real sources**: implement the live path in `heritage.ts` and add more
   adapters (GreatCollections, eBay, APMEX…). Respect each site's ToS,
   robots.txt, and rate limits.
3. **Persist imports**: point `npm run import -- --out=…` at
   `src/data/imported.json` and have the catalog read it; schedule the import
   (cron / GitHub Action) to keep inventory fresh.
4. **Checkout (Stripe — already built)**: create a Stripe account, then paste two
   keys into `.env.local` and real payments work immediately. See below.
5. **Leads**: point `SellForm` at your CRM/email/webhook.
6. **Deploy**: any Node host or Vercel. `npm run build && npm run start`.

### Stripe Checkout

Checkout is fully wired — you just add your keys:

- `POST /api/checkout` ([route](src/app/api/checkout/route.ts)) creates a Stripe
  Checkout Session. The **price is looked up server-side from the catalog** (the
  browser only sends the coin slug), so it can't be tampered with. Collects US
  shipping address + phone for fulfillment.
- `BuyPanel` redirects the buyer to Stripe's hosted, PCI-compliant page. If no
  key is set, it gracefully falls back to the reserve/call flow — so the site
  works today and becomes a real store the moment you add keys.
- `/checkout/success` confirms the order; `POST /api/webhook`
  ([route](src/app/api/webhook/route.ts)) verifies Stripe's signature and fires
  on `checkout.session.completed` — the hook where you place the source-dealer
  buy and kick off fulfillment (the session metadata carries the coin id, source
  dealer, source price, and sale price).

**Setup (~10 min):**
1. Create an account at [stripe.com](https://stripe.com) and finish activation
   (business details + bank account for payouts).
2. Copy your secret key from [dashboard.stripe.com/apikeys](https://dashboard.stripe.com/apikeys)
   into `STRIPE_SECRET_KEY` (use `sk_test_…` to test, `sk_live_…` to go live).
3. Add a webhook at [dashboard.stripe.com/webhooks](https://dashboard.stripe.com/webhooks)
   pointing to `https://YOUR-DOMAIN/api/webhook` for the
   `checkout.session.completed` event, and put its signing secret in
   `STRIPE_WEBHOOK_SECRET`.

---

## Business model note

Coin images shown for sample inventory are illustrative renderings. When wiring
real sources, only aggregate data you're permitted to use, keep source URLs and
dealer names internal (never shown to buyers), and confirm you can fulfill each
order before advertising it as in stock.
