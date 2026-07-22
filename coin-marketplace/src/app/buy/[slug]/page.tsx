import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import Link from 'next/link';
import { landingPages, landingBySlug, coinsForLanding, popularLandingPages } from '@/lib/landing';
import { sortCoins } from '@/lib/catalog';
import { CoinGrid } from '@/components/CoinCard';
import { Breadcrumbs } from '@/components/Breadcrumbs';
import { ItemListJsonLd } from '@/components/JsonLd';
import { formatUsd } from '@/lib/pricing';

export function generateStaticParams() {
  return landingPages.map((p) => ({ slug: p.slug }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const page = landingBySlug.get(slug);
  if (!page) return { title: 'Not Found' };
  return {
    title: page.title,
    description: page.description,
    alternates: { canonical: `/buy/${page.slug}` },
    openGraph: { title: page.title, description: page.description },
  };
}

export default async function LandingPageView({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const page = landingBySlug.get(slug);
  if (!page) notFound();

  const coins = sortCoins(coinsForLanding(page), 'featured');
  if (coins.length === 0) notFound();

  const priceFrom = Math.min(...coins.map((c) => c.price));
  const related = popularLandingPages(10).filter((p) => p.slug !== page.slug);

  return (
    <div className="container-page py-8">
      <Breadcrumbs
        items={[
          { name: 'Home', url: '/' },
          { name: 'Coins', url: '/coins' },
          { name: page.title, url: `/buy/${page.slug}` },
        ]}
      />

      <ItemListJsonLd coins={coins} name={page.title} />

      <div className="mt-6 border-b border-white/[0.06] pb-8">
        <h1 className="font-serif text-4xl font-bold text-white sm:text-5xl">{page.title}</h1>
        <p className="mt-4 max-w-2xl text-lg leading-relaxed text-silver-300">{page.intro}</p>
        <div className="mt-5 flex flex-wrap gap-2">
          <span className="chip">{coins.length} available</span>
          <span className="chip">From {formatUsd(priceFrom)}</span>
          <span className="chip border-gold-400/30 text-gold-200">Authenticity Guaranteed</span>
        </div>
      </div>

      <div className="mt-8">
        <CoinGrid coins={coins} />
      </div>

      {/* Internal-linking hub */}
      <section className="mt-16">
        <h2 className="font-serif text-xl font-bold text-white">Related Searches</h2>
        <div className="mt-4 flex flex-wrap gap-2">
          {related.map((p) => (
            <Link key={p.slug} href={`/buy/${p.slug}`} className="chip hover:bg-white/5">
              {p.title}
            </Link>
          ))}
        </div>
      </section>
    </div>
  );
}
