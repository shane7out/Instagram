import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import Link from 'next/link';
import { site } from '@/lib/site';
import { getAllCoins, getCoinBySlug, getRelatedCoins } from '@/lib/catalog';
import { getCategory } from '@/data/categories';
import { formatUsd } from '@/lib/pricing';
import { CoinMedallion } from '@/components/CoinMedallion';
import { CoinGrid } from '@/components/CoinCard';
import { Breadcrumbs } from '@/components/Breadcrumbs';
import { ProductJsonLd } from '@/components/JsonLd';
import { BuyPanel } from '@/components/BuyPanel';

export function generateStaticParams() {
  return getAllCoins().map((c) => ({ slug: c.slug }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const coin = getCoinBySlug(slug);
  if (!coin) return { title: 'Coin Not Found' };
  const title = `${coin.title} for Sale — ${formatUsd(coin.price)}`;
  const description =
    `Buy the ${coin.title} for ${formatUsd(coin.price)}. ` +
    `${coin.gradingService} certified ${coin.grade}. ` +
    `${(coin.description || '').slice(0, 110)} Authenticity guaranteed, insured shipping.`;
  return {
    title,
    description,
    alternates: { canonical: `/coins/${coin.slug}` },
    openGraph: {
      type: 'website',
      title,
      description,
      url: `${site.url}/coins/${coin.slug}`,
    },
  };
}

export default async function CoinPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const coin = getCoinBySlug(slug);
  if (!coin) notFound();

  const category = getCategory(coin.categorySlug);
  const related = getRelatedCoins(coin, 4);

  const specs: [string, string | null][] = [
    ['Year', coin.year ? String(coin.year) : 'Ancient / Undated'],
    ['Denomination', coin.denomination],
    ['Series', coin.series],
    ['Mint', coin.mint ? `${coin.mint}${coin.mintMark ? ` (${coin.mintMark})` : ''}` : coin.mintMark],
    ['Grade', `${coin.gradingService} ${coin.grade}`],
    ['Condition', coin.condition],
    ['Metal', coin.metal],
    ['Composition', coin.composition],
    ['Weight', coin.weightGrams ? `${coin.weightGrams} g` : null],
    ['Diameter', coin.diameterMm ? `${coin.diameterMm} mm` : null],
    ['Country', coin.country],
    ['Certification #', coin.certNumber],
  ];

  return (
    <div className="container-page py-8">
      <ProductJsonLd coin={coin} />
      <Breadcrumbs
        items={[
          { name: 'Home', url: '/' },
          { name: 'Coins', url: '/coins' },
          ...(category ? [{ name: category.name, url: `/category/${category.slug}` }] : []),
          { name: coin.title, url: `/coins/${coin.slug}` },
        ]}
      />

      <div className="mt-6 grid gap-10 lg:grid-cols-2">
        {/* Image */}
        <div>
          <div className="card coin-shine group relative flex aspect-square items-center justify-center overflow-hidden bg-gradient-to-b from-ink-800 to-ink-900 p-12">
            {coin.images.length > 0 ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={coin.images[0].url} alt={coin.images[0].alt} className="h-full w-full object-contain" />
            ) : (
              <CoinMedallion coin={coin} className="h-full w-full drop-shadow-2xl transition-transform duration-700 group-hover:rotate-[6deg]" />
            )}
            {coin.compareAtPrice && coin.compareAtPrice > coin.price && (
              <span className="absolute right-4 top-4 rounded-full bg-emerald-500/90 px-3 py-1 text-xs font-bold text-white">
                Save {formatUsd(coin.compareAtPrice - coin.price)}
              </span>
            )}
          </div>
          <p className="mt-3 text-center text-xs text-silver-500">
            Illustrative rendering. Actual certified coin photos provided at checkout.
          </p>
        </div>

        {/* Details */}
        <div>
          <div className="flex flex-wrap items-center gap-2">
            <span className="chip border-gold-400/30 text-gold-200">{coin.gradingService} Certified</span>
            <span className="chip">{coin.grade}</span>
            {coin.isNew && <span className="chip border-gold-400/30 text-gold-200">New Arrival</span>}
          </div>

          <h1 className="mt-4 font-serif text-3xl font-bold leading-tight text-white sm:text-4xl">
            {coin.title}
          </h1>

          <p className="mt-4 text-base leading-relaxed text-silver-300">{coin.description}</p>

          {coin.highlights.length > 0 && (
            <ul className="mt-5 grid gap-2 sm:grid-cols-2">
              {coin.highlights.map((h) => (
                <li key={h} className="flex items-start gap-2 text-sm text-silver-200">
                  <CheckIcon />
                  {h}
                </li>
              ))}
            </ul>
          )}

          <BuyPanel coin={coin} />

          {coin.rarityNote && (
            <div className="mt-6 rounded-xl border border-gold-400/20 bg-gold-400/[0.05] p-4">
              <div className="text-xs font-semibold uppercase tracking-wider text-gold-300">
                Rarity &amp; Collector Note
              </div>
              <p className="mt-1.5 text-sm text-silver-200">{coin.rarityNote}</p>
            </div>
          )}
        </div>
      </div>

      {/* Specs */}
      <section className="mt-14">
        <h2 className="font-serif text-2xl font-bold text-white">Coin Specifications</h2>
        <dl className="mt-5 grid gap-x-8 gap-y-0 sm:grid-cols-2">
          {specs
            .filter(([, v]) => v)
            .map(([k, v]) => (
              <div key={k} className="flex items-center justify-between border-b border-white/[0.06] py-3">
                <dt className="text-sm text-silver-400">{k}</dt>
                <dd className="text-sm font-medium text-silver-100">{v}</dd>
              </div>
            ))}
        </dl>
      </section>

      {/* Related */}
      {related.length > 0 && (
        <section className="mt-16">
          <h2 className="font-serif text-2xl font-bold text-white">You May Also Like</h2>
          <div className="mt-6">
            <CoinGrid coins={related} />
          </div>
        </section>
      )}

      {/* SEO body */}
      <section className="mt-16 max-w-3xl">
        <h2 className="font-serif text-xl font-bold text-white">
          About the {coin.year ? `${coin.year} ` : ''}
          {coin.series}
        </h2>
        <div className="mt-3 space-y-3 text-sm leading-relaxed text-silver-300">
          <p>
            This {coin.title} is offered for sale at {formatUsd(coin.price)} and comes {coin.gradingService}
            {coin.gradingService === 'Raw' || coin.gradingService === 'Uncertified'
              ? ' with our own authenticity guarantee'
              : ` certified in grade ${coin.grade}`}
            . Like every coin at {site.name}, it is backed by our lifetime authenticity guarantee, a
            30-day money-back return policy, and fully insured shipping.
          </p>
          <p>
            Whether you are adding to a {coin.series} collection, building a type set, or investing in
            certified {coin.metal.toLowerCase()}, buying certified coins protects your purchase and your
            resale value. Questions about this coin? Call our numismatic concierge at{' '}
            <a href={`tel:${site.phone.replace(/[^+\d]/g, '')}`} className="text-gold-300 hover:text-gold-200">
              {site.phone}
            </a>
            .
          </p>
        </div>
        <div className="mt-6 flex flex-wrap gap-2">
          {category && (
            <Link href={`/category/${category.slug}`} className="chip hover:bg-white/5">
              More {category.name}
            </Link>
          )}
          <Link href={`/coins?series=${encodeURIComponent(coin.series)}`} className="chip hover:bg-white/5">
            More {coin.series}
          </Link>
          <Link href={`/coins?metal=${coin.metal}`} className="chip hover:bg-white/5">
            More {coin.metal} Coins
          </Link>
        </div>
      </section>
    </div>
  );
}

function CheckIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" className="mt-0.5 flex-shrink-0 text-gold-400" aria-hidden>
      <path d="M20 6L9 17l-5-5" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}
