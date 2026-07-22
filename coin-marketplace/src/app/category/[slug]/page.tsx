import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import Link from 'next/link';
import { categories, getCategory } from '@/data/categories';
import { getCoinsByCategory, sortCoins } from '@/lib/catalog';
import { CoinGrid } from '@/components/CoinCard';
import { Breadcrumbs } from '@/components/Breadcrumbs';
import { ItemListJsonLd } from '@/components/JsonLd';
import { formatUsd } from '@/lib/pricing';

export function generateStaticParams() {
  return categories.map((c) => ({ slug: c.slug }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const category = getCategory(slug);
  if (!category) return { title: 'Category Not Found' };
  return {
    title: `${category.heading} — Certified & Guaranteed`,
    description: category.description,
    alternates: { canonical: `/category/${category.slug}` },
    openGraph: { title: category.heading, description: category.description },
  };
}

export default async function CategoryPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const category = getCategory(slug);
  if (!category) notFound();

  const coins = sortCoins(getCoinsByCategory(slug), 'featured');
  const parent = category.parentSlug ? getCategory(category.parentSlug) : undefined;
  const subCategories = categories.filter((c) => c.parentSlug === slug);
  const priceFrom = coins.length ? Math.min(...coins.map((c) => c.price)) : 0;

  return (
    <div className="container-page py-8">
      <Breadcrumbs
        items={[
          { name: 'Home', url: '/' },
          { name: 'Coins', url: '/coins' },
          ...(parent ? [{ name: parent.name, url: `/category/${parent.slug}` }] : []),
          { name: category.name, url: `/category/${category.slug}` },
        ]}
      />

      <ItemListJsonLd coins={coins} name={category.heading} />

      {/* Hero */}
      <div className="mt-6 border-b border-white/[0.06] pb-8">
        <h1 className="font-serif text-4xl font-bold text-white sm:text-5xl">{category.heading}</h1>
        <p className="mt-4 max-w-2xl text-lg leading-relaxed text-silver-300">{category.description}</p>
        <div className="mt-5 flex flex-wrap gap-3 text-sm text-silver-400">
          <span className="chip">{coins.length} coins available</span>
          {priceFrom > 0 && <span className="chip">From {formatUsd(priceFrom)}</span>}
          <span className="chip border-gold-400/30 text-gold-200">PCGS &amp; NGC Certified</span>
        </div>
      </div>

      {/* Sub-categories */}
      {subCategories.length > 0 && (
        <div className="mt-6 flex flex-wrap gap-2">
          {subCategories.map((sc) => (
            <Link key={sc.slug} href={`/category/${sc.slug}`} className="chip hover:bg-white/5">
              {sc.name} →
            </Link>
          ))}
        </div>
      )}

      {/* Coins */}
      <div className="mt-8">
        {coins.length > 0 ? (
          <CoinGrid coins={coins} />
        ) : (
          <div className="card p-12 text-center text-silver-300">
            New inventory arriving soon. <Link href="/coins" className="text-gold-300">Browse all coins →</Link>
          </div>
        )}
      </div>

      {/* SEO body */}
      <section className="mt-16 max-w-3xl">
        <h2 className="font-serif text-2xl font-bold text-white">
          Buying {category.name} at {`RareCoinsForSale`}
        </h2>
        <p className="mt-4 text-sm leading-relaxed text-silver-300">{category.seoBody}</p>
        <div className="mt-6 flex flex-wrap gap-2">
          <Link href="/coins" className="chip hover:bg-white/5">
            Shop all coins
          </Link>
          <Link href="/how-it-works" className="chip hover:bg-white/5">
            How buying works
          </Link>
          <Link href="/sell" className="chip hover:bg-white/5">
            Sell your {category.name.toLowerCase()}
          </Link>
        </div>
      </section>
    </div>
  );
}
