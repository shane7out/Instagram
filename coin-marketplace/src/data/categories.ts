import type { Category } from '@/lib/types';

/**
 * Category taxonomy. Categories are the backbone of the site's SEO: each one is
 * a landing page targeting a high-intent keyword cluster ("morgan silver
 * dollars for sale", "gold coins for sale", etc.). Sub-categories roll up under
 * parents via `parentSlug`.
 */
export const categories: Category[] = [
  {
    slug: 'us-coins',
    name: 'US Coins',
    shortName: 'US Coins',
    heading: 'US Coins for Sale',
    description:
      'Shop certified United States coins — from Colonial coppers to modern gold. Every coin PCGS or NGC graded and authenticity-guaranteed.',
    seoBody:
      'Our United States coin collection spans more than two centuries of American history, from early Draped Bust silver to the enduring Morgan and Peace dollars and classic US gold. Whether you are assembling a date-and-mintmark set, hunting a key-date rarity, or investing in certified type coins, every piece is independently graded by PCGS or NGC and backed by our lifetime authenticity guarantee.',
  },
  {
    slug: 'silver-dollars',
    name: 'Silver Dollars',
    shortName: 'Silver Dollars',
    heading: 'Silver Dollars for Sale',
    description:
      'Buy Morgan and Peace silver dollars, certified and graded. Key dates, Carson City mint, and gem uncirculated examples in stock.',
    seoBody:
      'The American silver dollar is the most collected coin in the world, and for good reason: big, beautiful 90% silver coins struck across storied mints from Carson City to New Orleans. We carry an extensive selection of Morgan dollars (1878–1921) and Peace dollars (1921–1935), including sought-after CC-mint issues, key dates, and gem MS-65 and finer examples. Each dollar is certified by PCGS or NGC so you know exactly what you are buying.',
    parentSlug: 'us-coins',
  },
  {
    slug: 'gold-coins',
    name: 'Gold Coins',
    shortName: 'Gold',
    heading: 'Gold Coins for Sale',
    description:
      'Certified US and world gold coins — Saint-Gaudens Double Eagles, Liberty Head, Indian, and modern Gold Eagles. Investment-grade and rare dates.',
    seoBody:
      'Gold coins combine intrinsic precious-metal value with numismatic rarity, making them a cornerstone of both collections and portfolios. Browse classic US gold — Saint-Gaudens and Liberty Head Double Eagles, Indian Head and Liberty quarter and half eagles — alongside modern American Gold Eagles and Buffalos. From bullion-priced common dates to condition-census rarities, every gold coin is certified and fully insured in transit.',
  },
  {
    slug: 'ancient-coins',
    name: 'Ancient Coins',
    shortName: 'Ancient',
    heading: 'Ancient Coins for Sale',
    description:
      'Genuine ancient Greek, Roman, and Byzantine coins. Silver denarii, gold aurei, and bronze — each with provenance and authenticity guaranteed.',
    seoBody:
      'Hold two thousand years of history in your hand. Our ancient coin selection features genuine Greek, Roman Republican and Imperial, and Byzantine issues — silver denarii and tetradrachms, bronze sestertii, and the occasional gold aureus or solidus. Every ancient is guaranteed authentic and, wherever possible, comes with documented provenance and NGC Ancients certification.',
  },
  {
    slug: 'world-coins',
    name: 'World Coins',
    shortName: 'World',
    heading: 'World & Foreign Coins for Sale',
    description:
      'Certified world coins from Great Britain, Canada, Mexico, China and beyond. Crowns, sovereigns, and rare foreign gold and silver.',
    seoBody:
      'Collecting knows no borders. Our world coin inventory brings together British sovereigns and crowns, Canadian and Mexican silver and gold, Chinese Pandas, German states, and rarities from every corner of the globe. Popular with type collectors and international investors alike, each world coin is graded and guaranteed genuine.',
  },
  {
    slug: 'type-coins',
    name: 'Type Coins',
    shortName: 'Type',
    heading: 'US Type Coins for Sale',
    description:
      'Build a US type set with certified representative examples — from Barber and Walking Liberty to Buffalo nickels and Mercury dimes.',
    seoBody:
      'A type set is one of the most rewarding ways to collect: a single high-grade example of each major US coin design. We stock beautiful certified type coins across denominations — Barber, Walking Liberty, Franklin, Buffalo, Mercury, Standing Liberty and more — so you can assemble a gorgeous, display-ready set one confident purchase at a time.',
    parentSlug: 'us-coins',
  },
];

export const categoryBySlug = new Map(categories.map((c) => [c.slug, c]));

export function getCategory(slug: string): Category | undefined {
  return categoryBySlug.get(slug);
}

/** Top-level categories (no parent) for nav / homepage. */
export const topCategories = categories.filter((c) => !c.parentSlug);
