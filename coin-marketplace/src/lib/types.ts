/**
 * Core domain model for the coin marketplace.
 *
 * A `Coin` is the normalized, marketplace-ready representation of a listing.
 * Raw data pulled from external dealer sites (see src/lib/sources) is mapped
 * into this shape by the importer, and the markup engine sets `price` from the
 * dealer's `sourcePrice`.
 */

export type GradingService = 'PCGS' | 'NGC' | 'ANACS' | 'ICG' | 'Raw' | 'Uncertified';

export type Metal = 'Gold' | 'Silver' | 'Platinum' | 'Copper' | 'Nickel' | 'Bronze' | 'Bimetallic';

export type CoinCondition =
  | 'Proof'
  | 'Mint State'
  | 'About Uncirculated'
  | 'Extremely Fine'
  | 'Very Fine'
  | 'Fine'
  | 'Very Good'
  | 'Good';

export interface CoinImage {
  url: string;
  alt: string;
}

/** A source dealer we aggregate from. */
export interface Source {
  /** Machine id, e.g. "heritage" */
  id: string;
  /** Human name, e.g. "Heritage Auctions" */
  name: string;
  /** Where the listing lives on the source site (never shown to buyers). */
  url: string;
}

export interface Coin {
  /** Stable unique id (derived from source + source listing id). */
  id: string;
  /** URL slug, e.g. "1921-morgan-silver-dollar-pcgs-ms65". */
  slug: string;
  /** Full display title. */
  title: string;

  // Taxonomy
  categorySlug: string; // primary category, e.g. "silver-dollars"
  /** Additional category slugs this coin also belongs to (for cross-listing). */
  extraCategorySlugs?: string[];

  // Numismatic attributes
  year: number | null;
  /** Mint mark, e.g. "S", "CC", "D", or null for Philadelphia/none. */
  mintMark: string | null;
  mint: string | null; // human readable, e.g. "Carson City"
  denomination: string; // e.g. "Silver Dollar", "Double Eagle ($20)"
  series: string; // e.g. "Morgan Dollar", "Saint-Gaudens"
  country: string; // e.g. "United States"
  metal: Metal;
  composition: string; // e.g. "90% Silver, 10% Copper"
  weightGrams: number | null;
  diameterMm: number | null;

  // Grade
  gradingService: GradingService;
  grade: string; // e.g. "MS-65", "PR-69 DCAM", "VF-30"
  gradeNumeric: number | null; // 65, 69, 30 ...
  condition: CoinCondition;
  certNumber: string | null; // grading cert number if known

  // Pricing (all USD)
  /** Dealer's asking price we pull from the source. */
  sourcePrice: number;
  /** Our marked-up sale price (set by the markup engine). */
  price: number;
  /** Optional strike-through / "compare at" price for merchandising. */
  compareAtPrice?: number;

  // Merchandising
  images: CoinImage[];
  description: string;
  highlights: string[];
  /** Populations / rarity notes (great for SEO + buyer trust). */
  rarityNote?: string;

  // Sourcing metadata (internal — powers the buy-on-sale workflow)
  source: Source;
  /** Number in stock at the source (usually 1 for certified coins). */
  quantityAvailable: number;
  inStock: boolean;
  /** When we last synced this listing from the source. ISO string. */
  lastSyncedAt: string;

  // Flags for merchandising
  featured?: boolean;
  isNew?: boolean;
}

export interface Category {
  slug: string;
  name: string;
  /** Short label for nav / breadcrumbs. */
  shortName?: string;
  /** SEO H1 / hero heading. */
  heading: string;
  /** SEO meta description + intro copy. */
  description: string;
  /** Longer SEO body copy rendered on the category page. */
  seoBody: string;
  /** Parent category slug, if this is a sub-category. */
  parentSlug?: string;
  heroImage?: string;
}
