import type { Metadata } from 'next';
import Link from 'next/link';
import { landingPages } from '@/lib/landing';
import { Breadcrumbs } from '@/components/Breadcrumbs';

export const metadata: Metadata = {
  title: 'Browse Coins by Type, Metal, Date & Grade',
  description:
    'Explore every way to buy coins — by series, metal, year, and grade. Certified rare coins for sale, organized for easy browsing.',
  alternates: { canonical: '/buy' },
};

const GROUP_LABELS: Record<string, string> = {
  series: 'Shop by Series',
  metal: 'Shop by Metal',
  grade: 'Shop by Grading Service',
  'year-series': 'Shop by Year',
  theme: 'Collections & Deals',
};

export default function BuyIndexPage() {
  const groups = ['series', 'metal', 'grade', 'theme', 'year-series'] as const;

  return (
    <div className="container-page py-8">
      <Breadcrumbs items={[{ name: 'Home', url: '/' }, { name: 'Browse by Type', url: '/buy' }]} />

      <div className="mt-6 max-w-2xl">
        <h1 className="font-serif text-4xl font-bold text-white sm:text-5xl">
          Find Exactly the Coin You Want
        </h1>
        <p className="mt-4 text-lg text-silver-300">
          Every series, metal, date, and grade — organized so you can go straight to what you collect.
        </p>
      </div>

      <div className="mt-10 space-y-10">
        {groups.map((group) => {
          const pages = landingPages.filter((p) => p.group === group);
          if (pages.length === 0) return null;
          return (
            <section key={group}>
              <h2 className="mb-4 font-serif text-2xl font-bold text-gold-100">
                {GROUP_LABELS[group]}
              </h2>
              <div className="flex flex-wrap gap-2">
                {pages.map((p) => (
                  <Link
                    key={p.slug}
                    href={`/buy/${p.slug}`}
                    className="rounded-lg border border-white/[0.06] bg-ink-900/70 px-4 py-2.5 text-sm text-silver-200 transition-all hover:border-gold-400/30 hover:text-white"
                  >
                    {p.title}
                  </Link>
                ))}
              </div>
            </section>
          );
        })}
      </div>
    </div>
  );
}
