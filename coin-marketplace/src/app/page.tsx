import Link from 'next/link';
import { site } from '@/lib/site';
import { getFeaturedCoins, getNewArrivals, getAllCoins } from '@/lib/catalog';
import { topCategories, categories } from '@/data/categories';
import { CoinGrid } from '@/components/CoinCard';
import { CoinMedallion } from '@/components/CoinMedallion';
import { ItemListJsonLd } from '@/components/JsonLd';
import { formatUsd } from '@/lib/pricing';

export default function HomePage() {
  const featured = getFeaturedCoins(8);
  const newArrivals = getNewArrivals(4);
  const all = getAllCoins();
  const heroCoins = featured.slice(0, 3);

  return (
    <>
      <ItemListJsonLd coins={featured} name="Featured Coins" />

      {/* ---- Hero ---- */}
      <section className="relative overflow-hidden">
        <div className="container-page grid items-center gap-12 py-16 lg:grid-cols-2 lg:py-24">
          <div>
            <span className="chip mb-5 border-gold-400/30 text-gold-200">
              ★ Trusted since {site.foundedYear} · {all.length}+ certified coins in stock
            </span>
            <h1 className="font-serif text-4xl font-bold leading-[1.05] text-white sm:text-5xl lg:text-6xl">
              The World’s Finest
              <br />
              <span className="text-gold-sheen">Rare Coins</span>, Curated
              <br />
              &amp; Guaranteed.
            </h1>
            <p className="mt-6 max-w-lg text-lg leading-relaxed text-silver-300">
              Certified Morgan dollars, gold eagles, ancient treasures and key-date rarities from the
              world’s top dealers — every coin PCGS or NGC graded and backed by our lifetime
              authenticity guarantee.
            </p>
            <div className="mt-8 flex flex-wrap gap-3">
              <Link href="/coins" className="btn-gold">
                Browse the Collection
              </Link>
              <Link href="/sell" className="btn-outline">
                Sell Your Coins
              </Link>
            </div>
            <dl className="mt-10 grid max-w-md grid-cols-3 gap-4">
              <Stat label="Coins Sold" value="120,000+" />
              <Stat label="Avg. Rating" value="4.9 / 5" />
              <Stat label="Guarantee" value="Lifetime" />
            </dl>
          </div>

          {/* Floating coins */}
          <div className="relative mx-auto flex h-[340px] w-full max-w-md items-center justify-center lg:h-[440px]">
            <div className="absolute inset-0 rounded-full bg-gold-400/10 blur-3xl" />
            {heroCoins.map((coin, i) => (
              <Link
                key={coin.id}
                href={`/coins/${coin.slug}`}
                className={[
                  'group absolute transition-transform duration-500 hover:z-20 hover:scale-105',
                  i === 0 ? 'z-10 h-56 w-56 lg:h-72 lg:w-72' : '',
                  i === 1 ? 'left-0 top-4 h-36 w-36 lg:h-44 lg:w-44' : '',
                  i === 2 ? 'bottom-2 right-2 h-40 w-40 lg:h-52 lg:w-52' : '',
                ].join(' ')}
                style={{ filter: 'drop-shadow(0 20px 40px rgba(0,0,0,0.5))' }}
                aria-label={coin.title}
              >
                <CoinMedallion coin={coin} className="h-full w-full" />
              </Link>
            ))}
          </div>
        </div>
        <div className="hairline" />
      </section>

      {/* ---- Trust strip ---- */}
      <section className="container-page grid grid-cols-2 gap-6 py-10 md:grid-cols-4">
        {[
          { t: 'PCGS & NGC Certified', d: 'Independently graded and sealed' },
          { t: 'Lifetime Authenticity', d: 'Guaranteed genuine, forever' },
          { t: 'Fully Insured Shipping', d: 'Free over ' + formatUsd(site.freeShippingThreshold) },
          { t: '30-Day Returns', d: 'Shop with total confidence' },
        ].map((f) => (
          <div key={f.t} className="flex items-start gap-3">
            <ShieldIcon />
            <div>
              <div className="text-sm font-semibold text-silver-100">{f.t}</div>
              <div className="text-xs text-silver-400">{f.d}</div>
            </div>
          </div>
        ))}
      </section>

      {/* ---- Categories ---- */}
      <section className="container-page py-14">
        <SectionHeading
          eyebrow="Shop by Category"
          title="Collect What You Love"
          href="/coins"
          linkText="View all coins"
        />
        <div className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {categories.map((cat) => {
            const sample = all.find(
              (c) => c.categorySlug === cat.slug || c.extraCategorySlugs?.includes(cat.slug),
            );
            return (
              <Link
                key={cat.slug}
                href={`/category/${cat.slug}`}
                className="card group flex items-center gap-5 overflow-hidden p-5 transition-all hover:border-gold-400/30 hover:shadow-gold-glow"
              >
                <div className="h-20 w-20 flex-shrink-0">
                  {sample ? (
                    <CoinMedallion coin={sample} className="h-full w-full transition-transform duration-500 group-hover:rotate-[8deg]" />
                  ) : null}
                </div>
                <div>
                  <h3 className="font-serif text-lg font-semibold text-white">{cat.name}</h3>
                  <p className="mt-1 line-clamp-2 text-xs text-silver-400">{cat.description}</p>
                  <span className="mt-2 inline-block text-xs font-semibold text-gold-300">
                    Shop {cat.shortName ?? cat.name} →
                  </span>
                </div>
              </Link>
            );
          })}
        </div>
      </section>

      {/* ---- Featured ---- */}
      <section className="container-page py-14">
        <SectionHeading
          eyebrow="Handpicked"
          title="Featured Rarities"
          href="/coins?sort=featured"
          linkText="See more"
        />
        <div className="mt-8">
          <CoinGrid coins={featured} />
        </div>
      </section>

      {/* ---- How it works ---- */}
      <section className="border-y border-white/[0.06] bg-ink-900/40">
        <div className="container-page py-16">
          <div className="mx-auto max-w-2xl text-center">
            <p className="text-sm font-semibold uppercase tracking-widest text-gold-300">
              Simple & Secure
            </p>
            <h2 className="mt-3 font-serif text-3xl font-bold text-white">
              How Buying a Rare Coin Works
            </h2>
          </div>
          <div className="mt-12 grid gap-8 md:grid-cols-3">
            {[
              {
                n: '01',
                t: 'Find Your Coin',
                d: 'Browse thousands of certified coins, aggregated from the world’s most reputable dealers into one trusted marketplace.',
              },
              {
                n: '02',
                t: 'We Secure It',
                d: 'The moment you order, we purchase and take delivery of your exact coin, verify it, and insure it.',
              },
              {
                n: '03',
                t: 'Delivered to You',
                d: 'Your coin ships fully insured in tamper-evident packaging, backed by our 30-day return promise.',
              },
            ].map((s) => (
              <div key={s.n} className="card p-7">
                <div className="font-serif text-4xl font-bold text-gold-sheen">{s.n}</div>
                <h3 className="mt-4 text-lg font-semibold text-white">{s.t}</h3>
                <p className="mt-2 text-sm leading-relaxed text-silver-300">{s.d}</p>
              </div>
            ))}
          </div>
          <div className="mt-10 text-center">
            <Link href="/how-it-works" className="btn-outline">
              Learn more about our guarantee
            </Link>
          </div>
        </div>
      </section>

      {/* ---- New arrivals ---- */}
      <section className="container-page py-14">
        <SectionHeading
          eyebrow="Just Listed"
          title="New Arrivals"
          href="/coins?sort=year-desc"
          linkText="See all new"
        />
        <div className="mt-8">
          <CoinGrid coins={newArrivals} />
        </div>
      </section>

      {/* ---- SEO copy + sell CTA ---- */}
      <section className="container-page py-14">
        <div className="card grid gap-8 p-8 md:grid-cols-2 md:p-12">
          <div>
            <h2 className="font-serif text-2xl font-bold text-white">
              Buy &amp; Sell Rare Coins With Confidence
            </h2>
            <div className="mt-4 space-y-4 text-sm leading-relaxed text-silver-300">
              <p>
                {site.name} brings the entire rare-coin market into a single, trustworthy destination.
                Instead of combing dozens of auction sites and dealer inventories, you shop one curated
                catalog of certified coins — Morgan and Peace silver dollars, classic US gold, ancient
                Greek and Roman issues, and world rarities — each independently graded by PCGS or NGC.
              </p>
              <p>
                Every price is transparent, every coin is guaranteed authentic for life, and every order
                ships fully insured. Ready to sell? We buy quality collections outright at fair,
                market-based prices — no consignment waits, no auction fees.
              </p>
            </div>
          </div>
          <div className="flex flex-col justify-center gap-4 rounded-xl bg-gradient-to-br from-gold-400/10 to-transparent p-8">
            <h3 className="font-serif text-xl font-semibold text-white">Have coins to sell?</h3>
            <p className="text-sm text-silver-300">
              Get a fast, fair offer for a single coin or an entire estate collection.
            </p>
            <Link href="/sell" className="btn-gold w-fit">
              Get a Free Offer
            </Link>
          </div>
        </div>
      </section>
    </>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <dt className="text-xs uppercase tracking-wider text-silver-400">{label}</dt>
      <dd className="mt-1 font-serif text-xl font-bold text-gold-200">{value}</dd>
    </div>
  );
}

function SectionHeading({
  eyebrow,
  title,
  href,
  linkText,
}: {
  eyebrow: string;
  title: string;
  href: string;
  linkText: string;
}) {
  return (
    <div className="flex items-end justify-between gap-4">
      <div>
        <p className="text-sm font-semibold uppercase tracking-widest text-gold-300">{eyebrow}</p>
        <h2 className="mt-2 font-serif text-3xl font-bold text-white">{title}</h2>
      </div>
      <Link href={href} className="hidden shrink-0 text-sm font-semibold text-gold-300 hover:text-gold-200 sm:block">
        {linkText} →
      </Link>
    </div>
  );
}

function ShieldIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" className="mt-0.5 flex-shrink-0 text-gold-400" aria-hidden>
      <path
        d="M12 2l8 3v6c0 5-3.5 8.5-8 11-4.5-2.5-8-6-8-11V5l8-3z"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinejoin="round"
      />
      <path d="M9 12l2 2 4-4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}
