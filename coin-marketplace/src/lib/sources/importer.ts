import type { Coin } from '@/lib/types';
import type { NormalizedListing, SourceAdapter, FetchOptions } from './types';
import { adapters } from './index';
import { computePrice, computeCompareAt, computeMargin } from '@/lib/pricing';
import { BaseSourceAdapter } from './base';

/**
 * The importer is the one place that turns normalized source listings into
 * marketplace-ready `Coin` records. It:
 *   1. pulls listings from each registered source adapter,
 *   2. applies the markup engine to set our price,
 *   3. maps source category hints onto our taxonomy,
 *   4. dedupes across sources (same coin, cheapest source wins),
 *   5. returns coins + an internal margin report.
 *
 * Keeping markup + persistence here (not in adapters) means adding a new source
 * never touches pricing logic.
 */

export interface ImportResult {
  coins: Coin[];
  report: ImportReport;
}

export interface ImportReport {
  bySource: Record<string, { fetched: number; imported: number }>;
  totalFetched: number;
  totalImported: number;
  duplicatesDropped: number;
  totalSourceValue: number;
  totalListValue: number;
  projectedGrossMargin: number;
}

/** Map a source's free-text category hint to one of our category slugs. */
function mapCategory(listing: NormalizedListing): string {
  // An explicit category hint from the adapter always wins.
  const known = new Set([
    'us-coins',
    'silver-dollars',
    'gold-coins',
    'ancient-coins',
    'world-coins',
    'type-coins',
  ]);
  if (listing.categoryHint && known.has(listing.categoryHint)) return listing.categoryHint;

  const hint = `${listing.series ?? ''} ${listing.title}`.toLowerCase();
  const country = (listing.country ?? '').toLowerCase();
  const isUS = !country || country === 'united states' || country === 'usa' || country === 'us';

  if (/ancient|denarius|tetradrachm|follis|aureus|solidus|sestertius/.test(hint)) return 'ancient-coins';
  if (/morgan|peace|silver dollar/.test(hint)) return 'silver-dollars';
  // Metal is the strongest signal for bullion (avoids "silver eagle" → gold).
  if (listing.metal === 'Gold') return 'gold-coins';
  if (!isUS) return 'world-coins';
  if (/sovereign|panda|reales|maple|britannia|philharmonic|krugerrand|kangaroo/.test(hint))
    return 'world-coins';
  if (/dime|nickel|quarter|half dollar|cent|type/.test(hint)) return 'type-coins';
  return 'us-coins';
}

/** A dedupe key that identifies "the same coin" across different sources. */
function dedupeKey(listing: NormalizedListing): string {
  // A cert number uniquely identifies a certified coin on its own.
  if (listing.certNumber) return `cert:${listing.certNumber}`;
  return [
    listing.year ?? '',
    listing.mintMark ?? '',
    (listing.series ?? '').toLowerCase(),
    // Denomination distinguishes sizes of the same series (1 oz vs 1/10 oz Eagle).
    (listing.denomination ?? '').toLowerCase(),
    (listing.grade ?? '').toLowerCase(),
  ]
    .join('|')
    .trim();
}

function toCoin(listing: NormalizedListing, adapter: SourceAdapter): Coin {
  const price = computePrice(listing.sourcePrice);
  const categorySlug = mapCategory(listing);
  const slug = BaseSourceAdapter.slugify(listing.title);
  return {
    id: `${adapter.id}:${listing.sourceListingId}`,
    slug,
    title: listing.title,
    categorySlug,
    year: listing.year ?? null,
    mintMark: listing.mintMark ?? null,
    mint: null,
    denomination: listing.denomination ?? '',
    series: listing.series ?? '',
    country: listing.country ?? 'United States',
    metal: listing.metal ?? 'Silver',
    composition: '',
    weightGrams: null,
    diameterMm: null,
    gradingService: listing.gradingService ?? 'Raw',
    grade: listing.grade ?? 'Ungraded',
    gradeNumeric: listing.gradeNumeric ?? null,
    condition: 'Mint State',
    certNumber: listing.certNumber ?? null,
    sourcePrice: listing.sourcePrice,
    price,
    compareAtPrice: computeCompareAt(price),
    images: (listing.imageUrls ?? []).map((url) => ({ url, alt: listing.title })),
    description: listing.description ?? '',
    highlights: [],
    source: { id: adapter.id, name: adapter.name, url: listing.sourceUrl },
    quantityAvailable: listing.quantityAvailable ?? 1,
    inStock: (listing.quantityAvailable ?? 1) > 0,
    lastSyncedAt: new Date().toISOString(),
  };
}

export async function runImport(
  opts: FetchOptions & { sources?: string[] } = {},
): Promise<ImportResult> {
  const selected = opts.sources?.length
    ? adapters.filter((a) => opts.sources!.includes(a.id))
    : adapters;

  const bySource: ImportReport['bySource'] = {};
  const seen = new Map<string, Coin>(); // dedupeKey -> cheapest-source coin
  let totalFetched = 0;
  let duplicatesDropped = 0;

  for (const adapter of selected) {
    let listings: NormalizedListing[] = [];
    try {
      listings = await adapter.fetchListings(opts);
    } catch (err) {
      console.error(`[import] ${adapter.id} failed:`, (err as Error).message);
    }
    bySource[adapter.id] = { fetched: listings.length, imported: 0 };
    totalFetched += listings.length;

    for (const listing of listings) {
      if (!listing.sourcePrice || listing.sourcePrice <= 0) continue;
      const key = dedupeKey(listing);
      const coin = toCoin(listing, adapter);
      const existing = key ? seen.get(key) : undefined;
      if (existing && key) {
        duplicatesDropped++;
        // Prefer the cheaper source (better margin for us).
        if (coin.sourcePrice < existing.sourcePrice) {
          seen.set(key, coin);
          bySource[adapter.id].imported++;
        }
      } else {
        seen.set(key || coin.id, coin);
        bySource[adapter.id].imported++;
      }
    }
  }

  const coins = Array.from(seen.values());
  const totalSourceValue = coins.reduce((s, c) => s + c.sourcePrice, 0);
  const totalListValue = coins.reduce((s, c) => s + c.price, 0);
  const projectedGrossMargin = coins.reduce(
    (s, c) => s + computeMargin(c.sourcePrice, c.price).usd,
    0,
  );

  return {
    coins,
    report: {
      bySource,
      totalFetched,
      totalImported: coins.length,
      duplicatesDropped,
      totalSourceValue,
      totalListValue,
      projectedGrossMargin,
    },
  };
}
