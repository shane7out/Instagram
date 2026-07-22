import type { Coin, Source } from '@/lib/types';
import { computePrice } from '@/lib/pricing';
import { moneyMetalsListings, type DealerListing } from '@/data/moneymetals-listings';

/**
 * The 20 coins imported from Money Metals Exchange, mapped into marketplace
 * `Coin` records with our flat 35% markup applied (see src/lib/pricing.ts).
 *
 * This is the *output* of the import pipeline. In production you'd generate an
 * equivalent file with a live run of the Money Metals adapter
 * (`npm run import -- --source=moneymetals --live --out=...`); here we build it
 * from the grounded price snapshot in moneymetals-listings.ts so the site is
 * populated immediately.
 */

const MONEY_METALS: Source = {
  id: 'moneymetals',
  name: 'Money Metals Exchange',
  url: 'https://www.moneymetals.com',
};

// The snapshot's "as of" time. Kept static so builds are reproducible.
const SYNCED_AT = '2026-07-22T00:00:00.000Z';

function slugify(s: string): string {
  return s
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '')
    .slice(0, 90);
}

function toCoin(listing: DealerListing, index: number): Coin {
  const price = computePrice(listing.sourcePrice); // × 1.35
  const bullion = listing.gradingService === 'Raw';
  return {
    id: `moneymetals:${listing.id}`,
    slug: slugify(listing.title),
    title: listing.title,
    categorySlug: listing.categorySlug,
    extraCategorySlugs: listing.extraCategorySlugs,
    year: listing.year,
    mintMark: null,
    mint: null,
    denomination: listing.denomination,
    series: listing.series,
    country: listing.country,
    metal: listing.metal,
    composition: listing.composition,
    weightGrams: listing.weightGrams,
    diameterMm: listing.diameterMm,
    gradingService: listing.gradingService,
    grade: listing.grade,
    gradeNumeric: null,
    condition: /circulat/i.test(listing.grade) ? 'Very Fine' : 'Mint State',
    certNumber: null,
    sourcePrice: listing.sourcePrice,
    price,
    compareAtPrice: undefined,
    images: [],
    description: listing.description,
    highlights: listing.highlights,
    source: MONEY_METALS,
    quantityAvailable: 25, // bullion is sold in quantity, not one-of-a-kind
    inStock: true,
    lastSyncedAt: SYNCED_AT,
    // Feature the first few imported coins so they surface on the homepage.
    featured: index < 3,
    isNew: true,
  };
}

export const importedCoins: Coin[] = moneyMetalsListings.map(toCoin);
