/**
 * Markup pricing engine.
 *
 * Business model: we aggregate listings from other dealers/auction sites and
 * resell at a markup. When a customer buys, we purchase the coin from the
 * source, take delivery, and ship it on. This module turns a dealer's
 * `sourcePrice` into our marketplace `price`.
 *
 * The markup is tiered — lower percentage on high-ticket coins (where a flat
 * high percentage would price us out) and a healthy margin plus a fixed
 * handling floor on inexpensive coins (which cost the same to inspect, insure,
 * and ship regardless of value). Prices are rounded to "charm" endings so they
 * read like retail, not like a spreadsheet.
 */

export interface MarkupTier {
  /** Applies while sourcePrice < `upTo` (USD). Use Infinity for the top tier. */
  upTo: number;
  /** Markup as a multiplier, e.g. 1.35 = +35%. */
  multiplier: number;
}

export interface MarkupConfig {
  tiers: MarkupTier[];
  /** Minimum absolute margin added on top of source price (USD). */
  minMarginUsd: number;
  /** Fixed handling/insurance/shipping recovery added to every coin (USD). */
  handlingUsd: number;
  /**
   * Show a "compare at" strike-through price at this multiple of our price,
   * to anchor the discount. Set to 0 to disable.
   */
  compareAtMultiplier: number;
}

export const DEFAULT_MARKUP: MarkupConfig = {
  tiers: [
    { upTo: 100, multiplier: 1.6 }, // +60% on sub-$100 coins
    { upTo: 500, multiplier: 1.42 }, // +42%
    { upTo: 2_000, multiplier: 1.32 }, // +32%
    { upTo: 10_000, multiplier: 1.24 }, // +24%
    { upTo: 50_000, multiplier: 1.18 }, // +18%
    { upTo: Infinity, multiplier: 1.12 }, // +12% on trophy coins
  ],
  minMarginUsd: 25,
  handlingUsd: 12,
  compareAtMultiplier: 1.15,
};

/** Round up to a retail-friendly charm price ($.., $x9, $xx9, $x995 ...). */
export function charmRound(value: number): number {
  if (value < 100) {
    // e.g. 63.10 -> 69
    return Math.max(9, Math.ceil(value / 5) * 5 - 1);
  }
  if (value < 1_000) {
    // -> nearest 5 then subtract 1 (e.g. 342 -> 349)
    return Math.ceil(value / 5) * 5 - 1;
  }
  if (value < 10_000) {
    // -> $x,x95 (e.g. 3421 -> 3495)
    return Math.ceil(value / 5) * 5 - 5;
  }
  // Big coins: round to nearest $50
  return Math.round(value / 50) * 50;
}

/** Compute our selling price from a dealer's source price. */
export function computePrice(sourcePrice: number, config: MarkupConfig = DEFAULT_MARKUP): number {
  const tier = config.tiers.find((t) => sourcePrice < t.upTo) ?? config.tiers[config.tiers.length - 1];
  const marked = sourcePrice * tier.multiplier + config.handlingUsd;
  const withMinMargin = Math.max(marked, sourcePrice + config.minMarginUsd + config.handlingUsd);
  return charmRound(withMinMargin);
}

/** Optional anchor / "compare at" price for merchandising. */
export function computeCompareAt(price: number, config: MarkupConfig = DEFAULT_MARKUP): number | undefined {
  if (!config.compareAtMultiplier || config.compareAtMultiplier <= 1) return undefined;
  return charmRound(price * config.compareAtMultiplier);
}

/** Gross margin (USD and %) we make on a coin, for internal dashboards. */
export function computeMargin(sourcePrice: number, price: number) {
  const usd = price - sourcePrice;
  const pct = sourcePrice > 0 ? usd / sourcePrice : 0;
  return { usd, pct };
}

const usdFormatter = new Intl.NumberFormat('en-US', {
  style: 'currency',
  currency: 'USD',
  maximumFractionDigits: 0,
});

export function formatUsd(value: number): string {
  return usdFormatter.format(value);
}
