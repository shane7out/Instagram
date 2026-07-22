/**
 * Markup pricing engine.
 *
 * Business model: we aggregate listings from other dealers/auction sites and
 * resell at a markup. When a customer buys, we purchase the coin from the
 * source, take delivery, and ship it on. This module turns a dealer's
 * `sourcePrice` into our marketplace `price`.
 *
 * Pricing policy: a flat markup on the dealer's source price. At 35% a coin the
 * dealer lists for $100 sells for exactly $135. The percentage lives in one
 * place (`MARKUP_PERCENT`) so the whole catalog re-prices by changing one number.
 */

/** The markup applied to every coin, as a percentage. 35 => +35% (x1.35). */
export const MARKUP_PERCENT = 35;

export interface MarkupConfig {
  /** Markup percentage, e.g. 35 for +35%. */
  percent: number;
  /**
   * Rounding of the final price:
   *  - 'exact'  : keep cents ($100 -> $135.00, $84.50 -> $114.08)
   *  - 'dollar' : round to the nearest whole dollar
   *  - 'charm'  : retail "charm" endings ($…9 / $…95)
   * Default is 'exact' so the markup is transparent and predictable.
   */
  rounding: 'exact' | 'dollar' | 'charm';
  /**
   * Show a "compare at" strike-through price at this multiple of our price.
   * 0 disables it (default) — keeps pricing honest with no invented anchor.
   */
  compareAtMultiplier: number;
}

export const DEFAULT_MARKUP: MarkupConfig = {
  percent: MARKUP_PERCENT,
  rounding: 'exact',
  compareAtMultiplier: 0,
};

/** Optional retail "charm" rounding ($…9 / $…95), if a config opts into it. */
export function charmRound(value: number): number {
  if (value < 100) return Math.max(9, Math.ceil(value / 5) * 5 - 1);
  if (value < 1_000) return Math.ceil(value / 5) * 5 - 1;
  if (value < 10_000) return Math.ceil(value / 5) * 5 - 5;
  return Math.round(value / 50) * 50;
}

/** Compute our selling price from a dealer's source price (flat markup). */
export function computePrice(sourcePrice: number, config: MarkupConfig = DEFAULT_MARKUP): number {
  const marked = sourcePrice * (1 + config.percent / 100);
  switch (config.rounding) {
    case 'charm':
      return charmRound(marked);
    case 'dollar':
      return Math.round(marked);
    case 'exact':
    default:
      return Math.round(marked * 100) / 100;
  }
}

/** Optional anchor / "compare at" price for merchandising (off by default). */
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
