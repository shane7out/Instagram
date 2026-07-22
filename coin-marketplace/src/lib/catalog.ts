import type { Coin, Category } from '@/lib/types';
import { coins as curatedCoins } from '@/data/inventory';
import { importedCoins } from '@/data/imported';
import { categories, getCategory, topCategories } from '@/data/categories';

/**
 * The full catalog = our curated certified inventory + coins imported from
 * source dealers (Money Metals Exchange). Imported coins come first so newly
 * synced stock surfaces at the top of listings.
 */
const coins: Coin[] = [...importedCoins, ...curatedCoins];

/**
 * Read model over the inventory. Pages and components query the catalog through
 * these helpers instead of touching the raw arrays, so we can later swap the
 * backing store (DB, CMS, live import) without changing the UI.
 */

export function getAllCoins(): Coin[] {
  return coins;
}

export function getCoinBySlug(slug: string): Coin | undefined {
  return coins.find((c) => c.slug === slug);
}

/** Coins in a category, counting both primary and cross-listed categories. */
export function getCoinsByCategory(categorySlug: string): Coin[] {
  return coins.filter(
    (c) => c.categorySlug === categorySlug || c.extraCategorySlugs?.includes(categorySlug),
  );
}

export function getFeaturedCoins(limit = 6): Coin[] {
  const featured = coins.filter((c) => c.featured);
  return (featured.length ? featured : coins).slice(0, limit);
}

export function getNewArrivals(limit = 8): Coin[] {
  return [...coins].sort((a, b) => Number(b.isNew) - Number(a.isNew)).slice(0, limit);
}

export function getRelatedCoins(coin: Coin, limit = 4): Coin[] {
  return coins
    .filter((c) => c.slug !== coin.slug)
    .map((c) => {
      let score = 0;
      if (c.categorySlug === coin.categorySlug) score += 3;
      if (c.series === coin.series) score += 4;
      if (c.metal === coin.metal) score += 1;
      if (c.country === coin.country) score += 1;
      return { c, score };
    })
    .sort((a, b) => b.score - a.score)
    .slice(0, limit)
    .map((x) => x.c);
}

export { categories, getCategory, topCategories };
export type { Coin, Category };

// ---- Faceted browse ----

export interface CoinFilters {
  category?: string;
  metal?: string;
  series?: string;
  gradingService?: string;
  minPrice?: number;
  maxPrice?: number;
  country?: string;
  q?: string;
}

export type SortKey = 'featured' | 'price-asc' | 'price-desc' | 'year-asc' | 'year-desc' | 'grade-desc';

export function filterCoins(all: Coin[], f: CoinFilters): Coin[] {
  return all.filter((c) => {
    if (f.category && c.categorySlug !== f.category && !c.extraCategorySlugs?.includes(f.category))
      return false;
    if (f.metal && c.metal !== f.metal) return false;
    if (f.series && c.series !== f.series) return false;
    if (f.gradingService && c.gradingService !== f.gradingService) return false;
    if (f.country && c.country !== f.country) return false;
    if (typeof f.minPrice === 'number' && c.price < f.minPrice) return false;
    if (typeof f.maxPrice === 'number' && c.price > f.maxPrice) return false;
    if (f.q) {
      const hay = `${c.title} ${c.series} ${c.country} ${c.denomination} ${c.grade}`.toLowerCase();
      if (!hay.includes(f.q.toLowerCase())) return false;
    }
    return true;
  });
}

export function sortCoins(list: Coin[], sort: SortKey = 'featured'): Coin[] {
  const arr = [...list];
  switch (sort) {
    case 'price-asc':
      return arr.sort((a, b) => a.price - b.price);
    case 'price-desc':
      return arr.sort((a, b) => b.price - a.price);
    case 'year-asc':
      return arr.sort((a, b) => (a.year ?? 9999) - (b.year ?? 9999));
    case 'year-desc':
      return arr.sort((a, b) => (b.year ?? -9999) - (a.year ?? -9999));
    case 'grade-desc':
      return arr.sort((a, b) => (b.gradeNumeric ?? 0) - (a.gradeNumeric ?? 0));
    case 'featured':
    default:
      return arr.sort(
        (a, b) => Number(b.featured) - Number(a.featured) || b.price - a.price,
      );
  }
}

/** Distinct facet values present in a set of coins, for building filter UIs. */
export function facetsFor(list: Coin[]) {
  const uniq = (vals: string[]) => Array.from(new Set(vals)).sort();
  return {
    metals: uniq(list.map((c) => c.metal)),
    series: uniq(list.map((c) => c.series)),
    gradingServices: uniq(list.map((c) => c.gradingService)),
    countries: uniq(list.map((c) => c.country)),
  };
}
