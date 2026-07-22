import type { Coin } from '@/lib/types';

/**
 * Source adapter contract.
 *
 * Each external site we aggregate from (Heritage, GreatCollections, eBay, APMEX,
 * ...) gets an adapter implementing `SourceAdapter`. An adapter's job is narrow:
 * fetch raw listings from that site and normalize them into `NormalizedListing`
 * objects. The importer then applies the markup engine and writes marketplace
 * `Coin` records — so pricing and persistence live in one place, not scattered
 * across every scraper.
 *
 * This keeps sources hot-swappable: add a new dealer by dropping in one file
 * that implements this interface and registering it.
 */

/** A listing as it exists on the source site, before markup/persistence. */
export interface NormalizedListing {
  /** The source's own id for this listing (used to dedupe across syncs). */
  sourceListingId: string;
  title: string;
  /** Dealer's asking price in USD. The markup engine turns this into our price. */
  sourcePrice: number;
  /** Canonical URL of the listing on the source site (internal use only). */
  sourceUrl: string;

  // Best-effort parsed numismatic attributes. Unknown fields may be null;
  // the normalizer/enricher fills gaps where it can.
  year?: number | null;
  mintMark?: string | null;
  denomination?: string;
  series?: string;
  country?: string;
  metal?: Coin['metal'];
  gradingService?: Coin['gradingService'];
  grade?: string;
  gradeNumeric?: number | null;
  certNumber?: string | null;
  imageUrls?: string[];
  description?: string;
  /** Category slug hint; the importer can re-map to our taxonomy. */
  categoryHint?: string;
  quantityAvailable?: number;
}

export interface FetchOptions {
  /** Max listings to pull this run. */
  limit?: number;
  /** Only pull listings updated after this ISO timestamp (incremental sync). */
  since?: string;
  /** Restrict to a source-specific search query or category. */
  query?: string;
  /** When true, adapters should use fixtures instead of live network calls. */
  dryRun?: boolean;
}

export interface SourceAdapter {
  /** Machine id, e.g. "heritage". Must be unique. */
  readonly id: string;
  /** Human-readable name shown nowhere to buyers, only in internal tooling. */
  readonly name: string;
  /** Base site URL. */
  readonly baseUrl: string;
  /**
   * Fetch and normalize listings from the source. Implementations should be
   * polite (respect robots.txt / rate limits / ToS) and resilient to markup
   * changes. Returns normalized listings ready for the importer.
   */
  fetchListings(opts?: FetchOptions): Promise<NormalizedListing[]>;
}
