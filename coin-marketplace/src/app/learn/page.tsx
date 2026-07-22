import type { Metadata } from 'next';
import Link from 'next/link';
import { guides } from '@/data/guides';
import { site } from '@/lib/site';
import { Breadcrumbs } from '@/components/Breadcrumbs';

export const metadata: Metadata = {
  title: 'Coin Guides & Value Guides — Learn from the Experts',
  description:
    'Free expert coin guides: how to grade coins, spot counterfeits, value your Morgan dollars, sell coins for the most money, and start collecting gold and silver.',
  alternates: { canonical: '/learn' },
};

export default function LearnHubPage() {
  return (
    <div className="container-page py-8">
      <Breadcrumbs items={[{ name: 'Home', url: '/' }, { name: 'Coin Guides', url: '/learn' }]} />

      <div className="mt-6 max-w-2xl">
        <p className="text-sm font-semibold uppercase tracking-widest text-gold-300">
          The Christensen Coins Library
        </p>
        <h1 className="mt-2 font-serif text-4xl font-bold text-white sm:text-5xl">
          Coin Guides &amp; Value Guides
        </h1>
        <p className="mt-4 text-lg leading-relaxed text-silver-300">
          Decades of numismatic know-how, written down. Learn how to grade coins, spot fakes, value
          your collection, and buy and sell with confidence — from a dealer who has done it for real.
        </p>
      </div>

      <div className="mt-10 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
        {guides.map((g) => (
          <Link
            key={g.slug}
            href={`/learn/${g.slug}`}
            className="card group flex flex-col p-6 transition-all hover:-translate-y-1 hover:border-gold-400/30 hover:shadow-gold-glow"
          >
            <span className="chip w-fit border-gold-400/30 text-gold-200">{g.kicker}</span>
            <h2 className="mt-4 font-serif text-xl font-semibold leading-snug text-white group-hover:text-gold-100">
              {g.title}
            </h2>
            <p className="mt-2 flex-1 text-sm leading-relaxed text-silver-300">{g.description}</p>
            <span className="mt-4 text-xs font-semibold text-gold-300">
              Read guide · {g.readingMinutes} min →
            </span>
          </Link>
        ))}
      </div>

      <div className="mt-14 card flex flex-col items-start gap-4 p-8 md:flex-row md:items-center md:justify-between">
        <div>
          <h2 className="font-serif text-2xl font-bold text-white">Questions about a specific coin?</h2>
          <p className="mt-2 text-sm text-silver-300">
            Talk to a real numismatist. Call {site.phone} or browse our certified inventory.
          </p>
        </div>
        <div className="flex flex-wrap gap-3">
          <Link href="/coins" className="btn-gold">
            Browse Coins
          </Link>
          <Link href="/sell" className="btn-outline">
            Sell Your Coins
          </Link>
        </div>
      </div>
    </div>
  );
}
