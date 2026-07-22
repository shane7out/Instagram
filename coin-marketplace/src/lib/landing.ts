import { getAllCoins, filterCoins, type CoinFilters } from '@/lib/catalog';
import type { Coin } from '@/lib/types';

/**
 * Programmatic SEO engine.
 *
 * The "rank #1 for everything" strategy is long-tail programmatic pages: one
 * indexable landing page per high-intent search phrase ("1921 Morgan Silver
 * Dollar for sale", "PCGS certified gold coins", "key date coins for sale").
 * Each page is a real, useful, filtered view of inventory with unique copy —
 * not thin doorway spam — so it earns rankings and converts.
 *
 * Pages are DERIVED from the live catalog: add inventory and new landing pages
 * appear automatically; sell out of a facet and its page stops generating.
 */

export interface LandingPage {
  slug: string;
  /** H1 / page title. */
  title: string;
  /** Meta description. */
  description: string;
  /** Intro paragraph rendered above the grid. */
  intro: string;
  /** Filter applied to select this page's coins. */
  filter: CoinFilters;
  /** Grouping for internal-linking hubs. */
  group: 'series' | 'metal' | 'grade' | 'year-series' | 'theme';
}

const uniq = <T,>(a: T[]) => Array.from(new Set(a));

function slugify(s: string): string {
  return s
    .toLowerCase()
    .replace(/\$/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');
}

/** Build the full set of landing pages from current inventory. */
function generate(): LandingPage[] {
  const coins = getAllCoins();
  const pages: LandingPage[] = [];
  const MIN = 1; // minimum coins for a page to be worth generating

  const withFilter = (f: CoinFilters) => filterCoins(coins, f);

  // --- Per series ---
  for (const series of uniq(coins.map((c) => c.series)).filter(Boolean)) {
    const list = withFilter({ series });
    if (list.length < MIN) continue;
    pages.push({
      slug: `${slugify(series)}-for-sale`,
      title: `${series} for Sale`,
      description: `Buy certified ${series} coins for sale. ${list.length} graded examples in stock, authenticity guaranteed with insured shipping.`,
      intro: `Shop our selection of ${series} coins for sale. Every ${series} is independently certified and backed by our lifetime authenticity guarantee. Browse ${list.length} available example${list.length === 1 ? '' : 's'} below.`,
      filter: { series },
      group: 'series',
    });
  }

  // --- Per metal ---
  for (const metal of uniq(coins.map((c) => c.metal))) {
    const list = withFilter({ metal });
    if (list.length < MIN) continue;
    pages.push({
      slug: `${slugify(metal)}-coins-for-sale`,
      title: `${metal} Coins for Sale`,
      description: `Certified ${metal.toLowerCase()} coins for sale — ${list.length} in stock. Rare dates and investment-grade ${metal.toLowerCase()}, PCGS & NGC graded.`,
      intro: `Explore certified ${metal.toLowerCase()} coins for sale, from classic rarities to investment-grade pieces. Each coin is graded and guaranteed genuine.`,
      filter: { metal },
      group: 'metal',
    });
  }

  // --- Per grading service ---
  for (const service of uniq(coins.map((c) => c.gradingService)).filter(
    (s) => s !== 'Raw' && s !== 'Uncertified',
  )) {
    const list = withFilter({ gradingService: service });
    if (list.length < MIN) continue;
    pages.push({
      slug: `${slugify(service)}-certified-coins`,
      title: `${service} Certified Coins for Sale`,
      description: `${service} certified coins for sale. ${list.length} independently graded coins, guaranteed authentic with 30-day returns.`,
      intro: `Every coin on this page is certified by ${service}, one of the world’s most trusted grading services, so you know exactly what you are buying.`,
      filter: { gradingService: service },
      group: 'grade',
    });
  }

  // --- Per year + series (the long tail) ---
  const yearSeries = uniq(
    coins.filter((c) => c.year).map((c) => `${c.year}__${c.series}`),
  );
  for (const key of yearSeries) {
    const [yearStr, series] = key.split('__');
    const year = Number(yearStr);
    const list = coins.filter((c) => c.year === year && c.series === series);
    if (list.length < MIN) continue;
    pages.push({
      slug: `${year}-${slugify(series)}-for-sale`,
      title: `${year} ${series} for Sale`,
      description: `Buy a ${year} ${series} for sale — certified and guaranteed. ${list.length} available. Prices, grades, and full specs.`,
      intro: `Looking to buy a ${year} ${series}? We have ${list.length} certified example${list.length === 1 ? '' : 's'} in stock, each graded and authenticity-guaranteed.`,
      filter: { series }, // year-narrowing handled at render for exactness
      group: 'year-series',
    });
  }

  // --- Themed / intent pages ---
  const themes: { slug: string; title: string; description: string; intro: string; pick: (c: Coin) => boolean }[] = [
    {
      slug: 'key-date-coins-for-sale',
      title: 'Key Date Coins for Sale',
      description: 'Key date and semi-key coins for sale — the scarce dates that complete a collection. Certified and guaranteed.',
      intro: 'Key dates are the scarce issues that make — or break — a complete set. These are the coins serious collectors chase, all certified and guaranteed genuine.',
      pick: (c) => Boolean(c.rarityNote) || /key|3-legged|high relief/i.test(c.title),
    },
    {
      slug: 'investment-grade-gold-coins',
      title: 'Investment-Grade Gold Coins for Sale',
      description: 'Investment-grade certified gold coins for sale. US and world gold, from bullion to rare dates, fully insured.',
      intro: 'Gold coins combine precious-metal value with numismatic upside. These certified gold coins are ideal for collectors and investors alike.',
      pick: (c) => c.metal === 'Gold',
    },
    {
      slug: 'coins-under-500',
      title: 'Certified Coins Under $500',
      description: 'Certified rare coins for sale under $500. Affordable entry points into collecting, every coin graded and guaranteed.',
      intro: 'You don’t need a fortune to own certified rare coins. Every coin here is graded, guaranteed, and priced under $500 — perfect for new collectors and gifts.',
      pick: (c) => c.price < 500,
    },
  ];
  for (const t of themes) {
    const list = coins.filter(t.pick);
    if (list.length < MIN) continue;
    pages.push({
      slug: t.slug,
      title: t.title,
      description: t.description,
      intro: t.intro,
      filter: {}, // themed pages resolve their own list at render
      group: 'theme',
    });
  }

  return pages;
}

export const landingPages: LandingPage[] = generate();

export const landingBySlug = new Map(landingPages.map((p) => [p.slug, p]));

/** Resolve the coins a landing page should display (handles special cases). */
export function coinsForLanding(page: LandingPage): Coin[] {
  const coins = getAllCoins();

  if (page.group === 'year-series') {
    const m = page.slug.match(/^(\d{4})-(.+)-for-sale$/);
    if (m) {
      const year = Number(m[1]);
      return coins.filter((c) => c.year === year && filterCoins([c], page.filter).length > 0);
    }
  }

  if (page.group === 'theme') {
    // Re-derive from the same predicates used to generate the page.
    if (page.slug === 'key-date-coins-for-sale')
      return coins.filter((c) => Boolean(c.rarityNote) || /key|3-legged|high relief/i.test(c.title));
    if (page.slug === 'investment-grade-gold-coins') return coins.filter((c) => c.metal === 'Gold');
    if (page.slug === 'coins-under-500') return coins.filter((c) => c.price < 500);
  }

  return filterCoins(coins, page.filter);
}

/** A few "popular" landing pages to surface in internal-linking modules. */
export function popularLandingPages(limit = 12): LandingPage[] {
  const order: LandingPage['group'][] = ['series', 'metal', 'theme', 'grade'];
  return [...landingPages]
    .sort((a, b) => order.indexOf(a.group) - order.indexOf(b.group))
    .slice(0, limit);
}
