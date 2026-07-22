import type { Metadata } from 'next';
import Link from 'next/link';
import { site } from '@/lib/site';
import { Breadcrumbs } from '@/components/Breadcrumbs';

export const metadata: Metadata = {
  title: 'About Us — Trusted Rare Coin Dealer',
  description: `${site.name} has been a trusted name in rare coins since ${site.foundedYear}. Learn about our mission to make buying and selling certified coins simple and safe.`,
  alternates: { canonical: '/about' },
};

export default function AboutPage() {
  return (
    <div className="container-page py-8">
      <Breadcrumbs items={[{ name: 'Home', url: '/' }, { name: 'About', url: '/about' }]} />

      <div className="mx-auto mt-6 max-w-3xl">
        <h1 className="font-serif text-4xl font-bold text-white sm:text-5xl">
          A Lifetime in Rare Coins
        </h1>
        <div className="mt-6 space-y-5 text-base leading-relaxed text-silver-300">
          <p>
            {site.name} was built by lifelong numismatists — including some of the largest coin
            dealers in the world — with a simple mission: make buying and selling rare coins as safe,
            simple, and transparent as it should be.
          </p>
          <p>
            For decades, collectors have had to chase listings across dozens of dealer sites and
            auction houses, never sure they were getting a fair price or a genuine coin. We changed
            that. By bringing the finest certified coins from the most reputable sources into a single
            curated marketplace, we give you the whole market in one trusted place — every coin graded
            by PCGS or NGC and guaranteed authentic for life.
          </p>
          <p>
            Whether you are buying your first Morgan dollar or selling a collection built over a
            lifetime, you deal with people who have spent their careers in this hobby and this
            business. That is the difference experience makes.
          </p>
        </div>

        <div className="mt-10 grid gap-4 sm:grid-cols-3">
          {[
            { v: `Since ${site.foundedYear}`, l: 'Trusted expertise' },
            { v: '120,000+', l: 'Coins sold' },
            { v: 'Lifetime', l: 'Authenticity guarantee' },
          ].map((s) => (
            <div key={s.l} className="card p-6 text-center">
              <div className="font-serif text-2xl font-bold text-gold-sheen">{s.v}</div>
              <div className="mt-1 text-sm text-silver-400">{s.l}</div>
            </div>
          ))}
        </div>

        <div className="mt-10 flex flex-wrap gap-3">
          <Link href="/coins" className="btn-gold">
            Browse the Collection
          </Link>
          <Link href="/how-it-works" className="btn-outline">
            How It Works
          </Link>
        </div>
      </div>
    </div>
  );
}
