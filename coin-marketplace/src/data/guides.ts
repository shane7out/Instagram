/**
 * Editorial content hub ("Learn"). This is the site's topical-authority engine:
 * in-depth, genuinely useful guides that capture high-volume informational
 * searches ("how to grade a coin", "morgan silver dollar value", "how to tell
 * if a coin is real") and funnel that traffic to inventory.
 *
 * Each guide renders with Article + FAQPage + Breadcrumb structured data and
 * internal links to the relevant category/landing pages, so it earns rankings
 * AND converts. Add a guide here and it auto-appears in the hub, nav, and sitemap.
 */

export interface GuideSection {
  heading: string;
  /** Paragraphs of body copy. */
  body: string[];
  /** Optional bullet list rendered after the paragraphs. */
  list?: string[];
}

export interface GuideFaq {
  q: string;
  a: string;
}

export interface GuideLink {
  label: string;
  href: string;
}

export interface Guide {
  slug: string;
  title: string;
  /** Meta description + hub card summary. */
  description: string;
  /** Short category label (e.g. "Grading", "Value Guide"). */
  kicker: string;
  /** ISO date; drives Article schema + "updated" line. */
  updated: string;
  readingMinutes: number;
  /** Opening paragraph(s) under the H1. */
  intro: string[];
  sections: GuideSection[];
  faqs: GuideFaq[];
  /** Internal links surfaced as "keep exploring". */
  related: GuideLink[];
}

export const guides: Guide[] = [
  {
    slug: 'how-to-tell-if-a-coin-is-real',
    title: 'How to Tell if a Coin Is Real: Spotting Fakes & Counterfeits',
    description:
      'Learn how to spot counterfeit coins with simple at-home tests — weight, dimensions, magnet, and sound — plus why third-party certification is the only real guarantee.',
    kicker: 'Authentication',
    updated: '2026-07-20',
    readingMinutes: 7,
    intro: [
      'Counterfeit coins have never been more sophisticated. High-quality fakes of Morgan dollars, Trade dollars, and classic US gold flow out of overseas mints every year, and many are convincing enough to fool the naked eye. The good news: most counterfeits fail simple, objective tests you can run at home in minutes.',
      'This guide walks through the fastest checks a collector can do, what they can and can’t prove, and why — for anything of real value — third-party certification is the only ironclad guarantee.',
    ],
    sections: [
      {
        heading: 'Start with weight and dimensions',
        body: [
          'Genuine coins are struck to exact government specifications. A counterfeiter can copy a design, but hitting the precise weight, diameter, and thickness with the correct metal is much harder. This is the single most useful test you can run.',
          'Get an inexpensive scale that reads to 0.01 grams and a set of calipers. Compare your coin to the published specs. A genuine Morgan dollar weighs 26.73 g and measures 38.1 mm; a common fake often comes in light because base metals are less dense than 90% silver.',
        ],
        list: [
          'Morgan / Peace dollar: 26.73 g, 38.1 mm',
          'American Silver Eagle: 31.10 g (1 oz), 40.6 mm',
          '$20 Saint-Gaudens gold: 33.44 g, 34 mm',
          'If weight is off by more than ~0.3 g, be suspicious.',
        ],
      },
      {
        heading: 'The magnet test',
        body: [
          'Gold and silver are not magnetic. If a coin that should be precious metal is attracted to a strong magnet, it is fake — full stop. This won’t catch high-quality fakes made from non-magnetic alloys, but it instantly exposes the cheap ones.',
        ],
      },
      {
        heading: 'Listen to the ring',
        body: [
          'Balance a silver coin on your fingertip and tap it with another coin. Genuine 90% silver produces a long, high-pitched ring. Counterfeits made of lead, pewter, or plated base metal thud dully. It takes practice, but the difference is real and hard to fake.',
        ],
      },
      {
        heading: 'Inspect the details under magnification',
        body: [
          'Use a 10x loupe. Look for mushy or doubled lettering, a seam around the edge (a sign of a cast counterfeit), tooling marks, or a mintmark that looks added. On genuine struck coins the details are crisp and the fields are clean. Cast fakes often show tiny pits from air bubbles.',
        ],
      },
      {
        heading: 'Why certification is the real answer',
        body: [
          'At-home tests build confidence, but they can’t catch everything — and the higher the coin’s value, the more sophisticated the fakes become. That’s why the market runs on third-party grading. PCGS and NGC authenticate and grade coins, then seal them in tamper-evident holders with a verifiable certification number.',
          'Every certified coin we sell can be looked up directly on the grading service’s website by its cert number, and each is backed by our lifetime authenticity guarantee. When you buy certified, you remove the guesswork entirely.',
        ],
      },
    ],
    faqs: [
      {
        q: 'Can you tell if a coin is real with a magnet?',
        a: 'Partly. Real gold and silver are not magnetic, so if a supposedly precious-metal coin sticks to a strong magnet it is definitely fake. However, some counterfeits use non-magnetic base alloys, so passing the magnet test alone does not prove a coin is genuine.',
      },
      {
        q: 'What is the most reliable way to know a coin is authentic?',
        a: 'Third-party certification by PCGS or NGC. These services authenticate and grade the coin and seal it in a holder with a certification number you can verify online. It is the standard the entire hobby trusts.',
      },
      {
        q: 'Do fake coins have the right weight?',
        a: 'Usually not. Precise weight in the correct metal is one of the hardest things to fake, which is why weighing a coin to 0.01 g and comparing it to published specs is one of the best quick tests.',
      },
    ],
    related: [
      { label: 'Shop PCGS & NGC Certified Coins', href: '/buy/pcgs-certified-coins' },
      { label: 'Silver Dollars for Sale', href: '/category/silver-dollars' },
      { label: 'How Buying Works', href: '/how-it-works' },
    ],
  },
  {
    slug: 'coin-grading-explained',
    title: 'Coin Grading Explained: The Sheldon Scale, PCGS & NGC',
    description:
      'Understand how coins are graded on the 1–70 Sheldon scale, what MS-65 and PR-69 mean, and why the difference between two grades can be thousands of dollars.',
    kicker: 'Grading',
    updated: '2026-07-19',
    readingMinutes: 8,
    intro: [
      'Grade is the single biggest driver of a coin’s value after rarity. Two coins of the same date and mint can differ in price by 10x or more based on condition alone. Understanding the grading scale is how you shop — and buy — with confidence.',
    ],
    sections: [
      {
        heading: 'The Sheldon scale: 1 to 70',
        body: [
          'Modern coin grading uses the 70-point Sheldon scale, where 1 is barely identifiable and 70 is flawless under magnification. The scale is split into circulated grades (1–58) and uncirculated, or “Mint State,” grades (60–70).',
        ],
        list: [
          'G-4 (Good): heavily worn but the design and date are readable',
          'F-12 (Fine): moderate even wear, all major features clear',
          'XF-40 (Extremely Fine): light wear on the highest points only',
          'AU-58 (About Uncirculated): a trace of wear; often looks mint',
          'MS-65 (Gem Mint State): sharp, lustrous, minimal marks',
          'MS-70 / PR-70: perfect, no flaws at 5x magnification',
        ],
      },
      {
        heading: 'Mint State vs. Proof',
        body: [
          'Mint State (MS) coins are business strikes made for circulation but preserved in uncirculated condition. Proof (PR or PF) coins are specially struck for collectors using polished dies and planchets, producing mirror-like fields. A "PR-69 DCAM" is a near-perfect proof with Deep Cameo contrast between frosted devices and mirrored fields.',
        ],
      },
      {
        heading: 'Why PCGS and NGC matter',
        body: [
          'Before third-party grading, buyers had to trust the seller’s opinion of a coin’s grade. PCGS (founded 1985) and NGC (founded 1987) changed the market by grading coins consistently and sealing them in tamper-evident holders. Their consistency is why a certified coin sells for more — and sells faster — than a raw one.',
          'Both services also authenticate, so a certified coin is guaranteed genuine. When comparing prices, always compare like grades from these two services; a raw coin “graded” by the seller is not the same thing.',
        ],
      },
      {
        heading: 'The grade cliffs that cost real money',
        body: [
          'Value doesn’t rise smoothly with grade — it jumps at key thresholds. For many series, the leap from MS-64 to MS-65 (the “gem” threshold) can double the price, and MS-66 to MS-67 can be exponential for condition-rarities. This is why the exact grade on the holder matters so much, and why buying certified protects you from overpaying for an optimistic grade.',
        ],
      },
    ],
    faqs: [
      {
        q: 'What does MS-65 mean on a coin?',
        a: 'MS-65 is a "Gem Mint State" grade on the 70-point Sheldon scale. The coin is uncirculated with strong luster, a good strike, and only minor, scattered contact marks. It is a common target grade for high-quality type coins.',
      },
      {
        q: 'Is PCGS or NGC better?',
        a: 'Both PCGS and NGC are highly respected industry leaders, and coins in either holder trade actively. PCGS sometimes carries a slight price premium in certain US series, but for most buyers the two are equivalently trusted.',
      },
      {
        q: 'What is the difference between a proof and a mint state coin?',
        a: 'Mint State coins are regular business strikes preserved uncirculated. Proof coins are specially made for collectors using polished dies and planchets, giving them mirror-like fields and, often, frosted designs.',
      },
    ],
    related: [
      { label: 'Shop Gem Mint State Coins', href: '/coins?sort=grade-desc' },
      { label: 'PCGS Certified Coins', href: '/buy/pcgs-certified-coins' },
      { label: 'NGC Certified Coins', href: '/buy/ngc-certified-coins' },
    ],
  },
  {
    slug: 'morgan-silver-dollar-value-guide',
    title: 'Morgan Silver Dollar Value Guide: Dates, Mintmarks & Prices',
    description:
      'What is your Morgan silver dollar worth? A complete guide to dates, mintmarks, key dates, and how grade and the Carson City mint drive value.',
    kicker: 'Value Guide',
    updated: '2026-07-18',
    readingMinutes: 9,
    intro: [
      'The Morgan silver dollar (1878–1921) is the most collected coin in America, and values range from a few tens of dollars for a common circulated example to six figures for the rarest dates in gem condition. Here’s how to figure out what yours is worth.',
    ],
    sections: [
      {
        heading: 'Start with the four value factors',
        body: [
          'Every Morgan’s value comes down to four things: date, mintmark, grade, and eye appeal. The date and mintmark tell you how rare the coin is; the grade tells you what condition it’s in; and eye appeal (luster, toning, strike) is the tiebreaker that separates a good example from a great one.',
        ],
      },
      {
        heading: 'Find the mintmark',
        body: [
          'The mintmark is on the reverse (tails side), below the wreath and above the letters "DO" in DOLLAR. It tells you which mint struck the coin — and Carson City coins carry a huge premium.',
        ],
        list: [
          'No mintmark = Philadelphia',
          'CC = Carson City (the collector favorite, always a premium)',
          'O = New Orleans',
          'S = San Francisco',
          'D = Denver (1921 only)',
        ],
      },
      {
        heading: 'The key dates that drive value',
        body: [
          'Most Morgans are common, but a handful of key dates are worth serious money in any grade. If you have one of these, get it certified before selling.',
        ],
        list: [
          '1893-S — the king of the series; scarce in every grade',
          '1889-CC — the key Carson City date',
          '1893-CC, 1879-CC, 1892-S, 1894 — major semi-keys',
          'Any CC-mint Morgan — a premium over common dates',
        ],
      },
      {
        heading: 'How grade multiplies value',
        body: [
          'A common-date Morgan in circulated condition trades close to its silver value. The same date in MS-63 might be $60–$90, in MS-65 several times that, and in MS-67 it can be a major rarity. For key dates the multipliers are even steeper. This is exactly why certification matters: the grade on the holder is the number the market pays on.',
        ],
      },
      {
        heading: 'Should you sell raw or certified?',
        body: [
          'For common circulated Morgans, raw is fine — they trade near melt. But for anything that looks uncirculated, or any CC-mint or key date, certification almost always pays for itself by unlocking the full market value and giving buyers confidence. We buy both, and can advise on what’s worth grading.',
        ],
      },
    ],
    faqs: [
      {
        q: 'How much is a Morgan silver dollar worth?',
        a: 'Common circulated Morgan dollars trade close to their silver value (often $30–$60 depending on the silver price), while better dates and high-grade certified examples range from the low hundreds into the tens of thousands. The 1893-S key date can bring six figures in high grade.',
      },
      {
        q: 'Which Morgan dollars are most valuable?',
        a: 'The 1893-S is the most valuable regular-issue Morgan, followed by key dates like the 1889-CC and other Carson City issues. Any CC-mint Morgan carries a premium, and value rises sharply with grade.',
      },
      {
        q: 'Where is the mintmark on a Morgan dollar?',
        a: 'On the reverse, below the eagle and wreath, above the "DO" in DOLLAR. No mintmark means it was struck in Philadelphia; CC, O, S, and D indicate Carson City, New Orleans, San Francisco, and Denver.',
      },
    ],
    related: [
      { label: 'Morgan Silver Dollars for Sale', href: '/buy/morgan-dollar-for-sale' },
      { label: 'Shop All Silver Dollars', href: '/category/silver-dollars' },
      { label: 'Key Date Coins for Sale', href: '/buy/key-date-coins-for-sale' },
    ],
  },
  {
    slug: 'how-to-sell-your-coins',
    title: 'How to Sell Your Coins for the Most Money',
    description:
      'A step-by-step guide to selling coins and collections — how to know what you have, avoid lowball offers, decide whether to grade, and get a fair price.',
    kicker: 'Selling',
    updated: '2026-07-17',
    readingMinutes: 6,
    intro: [
      'Whether you’ve inherited a collection or you’re ready to sell coins you’ve held for years, a little preparation is the difference between a fair price and getting lowballed. Here’s how to sell smart.',
    ],
    sections: [
      {
        heading: 'First, understand what you have',
        body: [
          'Before you sell anything, take an inventory. Note dates, mintmarks, and whether coins are already certified. Separate obvious bullion (common silver and gold you own for the metal) from potential numismatic pieces (key dates, certified coins, anything unusual). Don’t clean your coins — cleaning almost always lowers value.',
        ],
      },
      {
        heading: 'Know the two kinds of value',
        body: [
          'Bullion value is what the metal is worth — it tracks the daily gold and silver price. Numismatic value is the collector premium on top, driven by rarity and grade. A worn common-date silver dollar is essentially bullion; a certified key date is numismatic. Selling them the same way leaves money on the table.',
        ],
      },
      {
        heading: 'Decide what to certify',
        body: [
          'For high-value raw coins that look uncirculated, or any key date, grading can dramatically increase what a buyer will pay by removing their risk. For common circulated material, grading costs more than it returns. A reputable dealer will tell you honestly which of your coins are worth submitting.',
        ],
      },
      {
        heading: 'Get a fair, transparent offer',
        body: [
          'Avoid "we buy gold" pop-up shops that pay well under market. Sell to an established dealer who prices against live market data and explains the offer. Ask how the number was calculated. A fair buyer is happy to show their work.',
        ],
      },
      {
        heading: 'How we buy',
        body: [
          'We buy single coins and entire estate collections at fair, market-based prices — no consignment waits and no auction fees. Send a few details and photos and we’ll come back with a transparent offer, usually within a business day. Accept, ship with a prepaid insured label, and get paid fast once we verify.',
        ],
      },
    ],
    faqs: [
      {
        q: 'Should I clean my coins before selling them?',
        a: 'No. Cleaning a coin — even gently — leaves hairlines and damages the surface, and it almost always reduces value. Collectors and dealers pay more for original, uncleaned surfaces. Leave them exactly as they are.',
      },
      {
        q: 'Is it better to sell coins raw or graded?',
        a: 'It depends on the coin. High-value or key-date coins usually sell for more when certified by PCGS or NGC because it removes the buyer’s risk. Common circulated coins that trade near their metal value are not worth the grading cost.',
      },
      {
        q: 'How do I get a fair price for an inherited coin collection?',
        a: 'Inventory what you have without cleaning anything, separate bullion from potential rarities, and get an offer from an established dealer who prices against live market data and explains their numbers. Avoid pop-up "cash for gold" buyers.',
      },
    ],
    related: [
      { label: 'Sell Your Coins — Get an Offer', href: '/sell' },
      { label: 'How It Works', href: '/how-it-works' },
      { label: 'Gold Coins for Sale', href: '/category/gold-coins' },
    ],
  },
  {
    slug: 'buying-gold-and-silver-coins-for-beginners',
    title: 'Buying Gold & Silver Coins: A Beginner’s Guide',
    description:
      'New to precious metals? Learn the difference between bullion and numismatic coins, what "premium over spot" means, and which coins are best to start with.',
    kicker: 'Getting Started',
    updated: '2026-07-16',
    readingMinutes: 7,
    intro: [
      'Gold and silver coins are one of the most accessible ways to own precious metals — tangible, liquid, and government-backed. If you’re just starting out, here’s what you need to know to buy with confidence.',
    ],
    sections: [
      {
        heading: 'Bullion vs. numismatic coins',
        body: [
          'Bullion coins (like American Silver Eagles or Gold Maple Leafs) are valued mainly for their metal content and trade at a small premium over the spot price. Numismatic coins are valued for rarity and grade, and can be worth far more than their metal. Beginners usually start with bullion for simplicity, then move into numismatics as they learn.',
        ],
      },
      {
        heading: 'What "premium over spot" means',
        body: [
          'Spot is the live market price of the raw metal. The premium is the amount above spot you pay for a finished, government-minted coin — it covers minting, distribution, and dealer margin. Lower-premium products (like generic rounds or a common Silver Eagle) get you the most metal for your money; collectible issues carry higher premiums.',
        ],
      },
      {
        heading: 'Best coins to start with',
        body: [
          'Stick to widely recognized, easily resold coins when you’re starting out. These are liquid worldwide and hard to fake.',
        ],
        list: [
          'American Silver Eagle — the world’s most popular silver coin',
          'Canadian Silver Maple Leaf — .9999 fine with security features',
          'American Gold Eagle — the benchmark US gold bullion coin',
          'Gold or Silver Krugerrand, Britannia, or Philharmonic',
          '90% "junk" silver — pre-1965 US coins, lowest premium',
        ],
      },
      {
        heading: 'Buy certified when you cross into numismatics',
        body: [
          'The moment you’re buying a coin for its rarity rather than its metal, buy it certified. A PCGS or NGC holder guarantees authenticity and locks in the grade, which protects both your purchase and your future resale. It’s the simplest way to avoid costly mistakes as a new collector.',
        ],
      },
    ],
    faqs: [
      {
        q: 'What is the difference between bullion and numismatic coins?',
        a: 'Bullion coins are valued mainly for their precious-metal content and trade at a small premium over spot. Numismatic coins are valued for rarity and grade and can be worth far more than their metal content.',
      },
      {
        q: 'What is the best silver coin for beginners?',
        a: 'The American Silver Eagle is the most popular and liquid choice — government-backed, widely recognized, and easy to resell. Canadian Silver Maple Leafs and 90% "junk" silver are also excellent, low-hassle starting points.',
      },
      {
        q: 'What does premium over spot mean?',
        a: 'Spot is the live price of the raw metal. The premium is the extra amount you pay above spot for a finished, minted coin — covering minting, distribution, and dealer margin. Common bullion coins carry the lowest premiums.',
      },
    ],
    related: [
      { label: 'Gold Coins for Sale', href: '/buy/gold-coins-for-sale' },
      { label: 'Silver Coins for Sale', href: '/buy/silver-coins-for-sale' },
      { label: 'World Coins for Sale', href: '/category/world-coins' },
    ],
  },
];

export const guideBySlug = new Map(guides.map((g) => [g.slug, g]));

export function getGuide(slug: string): Guide | undefined {
  return guideBySlug.get(slug);
}
