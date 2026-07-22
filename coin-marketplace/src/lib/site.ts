/**
 * Central site configuration. Everything brand-related lives here so the whole
 * site can be re-skinned by editing one file (or find-and-replacing the name).
 *
 * Brand: "Christensen Coins" (christensencoins.com). Swap `name`, `domain`,
 * and `url` for a different brand/domain and the entire site — titles,
 * canonical URLs, sitemap, structured data, Open Graph — updates automatically.
 */
export const site = {
  name: 'Christensen Coins',
  legalName: 'Christensen Coins, LLC',
  tagline: 'The World’s Finest Rare Coins — Curated, Graded & Guaranteed',
  shortDescription:
    'Buy rare and collectible coins from the world’s top dealers, all in one place. Certified Morgan dollars, gold eagles, ancient coins and more — every coin authenticity-guaranteed.',
  // Change this to your real domain. Used for canonical URLs, sitemap, JSON-LD.
  domain: 'christensencoins.com',
  url: 'https://christensencoins.com',
  // Contact & trust
  phone: '+1 (800) 555-0199',
  email: 'concierge@christensencoins.com',
  foundedYear: 1998,
  // Social handles (used for sameAs in Organization schema)
  social: {
    twitter: 'https://twitter.com/christensencoins',
    facebook: 'https://facebook.com/christensencoins',
    instagram: 'https://instagram.com/christensencoins',
    youtube: 'https://youtube.com/@christensencoins',
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
