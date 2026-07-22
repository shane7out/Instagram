/**
 * Central site configuration. Everything brand-related lives here so the whole
 * site can be re-skinned by editing one file (or find-and-replacing the name).
 *
 * Placeholder brand: "RareCoinsForSale". Swap `name`, `domain`, and `url`
 * for your real brand/domain and the entire site — titles, canonical URLs,
 * sitemap, structured data, Open Graph — updates automatically.
 */
export const site = {
  name: 'RareCoinsForSale',
  legalName: 'RareCoinsForSale, LLC',
  tagline: 'The World’s Finest Rare Coins — Curated, Graded & Guaranteed',
  shortDescription:
    'Buy rare and collectible coins from the world’s top dealers, all in one place. Certified Morgan dollars, gold eagles, ancient coins and more — every coin authenticity-guaranteed.',
  // Change this to your real domain. Used for canonical URLs, sitemap, JSON-LD.
  domain: 'rarecoinsforsale.co',
  url: 'https://rarecoinsforsale.co',
  // Contact & trust
  phone: '+1 (800) 555-0199',
  email: 'concierge@rarecoinsforsale.co',
  foundedYear: 1998,
  // Social handles (used for sameAs in Organization schema)
  social: {
    twitter: 'https://twitter.com/rarecoinsforsale',
    facebook: 'https://facebook.com/rarecoinsforsale',
    instagram: 'https://instagram.com/rarecoinsforsale',
    youtube: 'https://youtube.com/@rarecoinsforsale',
  },
  // Business model knobs
  freeShippingThreshold: 250,
  // Trust badges shown across the site
  guarantees: [
    'Lifetime Authenticity Guarantee',
    'PCGS & NGC Certified',
    '30-Day Money-Back Returns',
    'Fully Insured Shipping',
  ],
} as const;

export const nav = [
  { label: 'Shop All', href: '/coins' },
  { label: 'US Coins', href: '/category/us-coins' },
  { label: 'Gold', href: '/category/gold-coins' },
  { label: 'Silver Dollars', href: '/category/silver-dollars' },
  { label: 'Ancient', href: '/category/ancient-coins' },
  { label: 'Sell Your Coins', href: '/sell' },
] as const;
