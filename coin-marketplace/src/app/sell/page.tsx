import type { Metadata } from 'next';
import { site } from '@/lib/site';
import { Breadcrumbs } from '@/components/Breadcrumbs';
import { SellForm } from '@/components/SellForm';

export const metadata: Metadata = {
  title: 'Sell Your Coins — Get a Fast, Fair Offer',
  description:
    'Sell your rare coins and collections to a trusted buyer. Free appraisals, fair market-based offers, and fast payment. Single coins to entire estate collections.',
  alternates: { canonical: '/sell' },
};

export default function SellPage() {
  return (
    <div className="container-page py-8">
      <Breadcrumbs items={[{ name: 'Home', url: '/' }, { name: 'Sell Your Coins', url: '/sell' }]} />

      <div className="mt-6 grid gap-12 lg:grid-cols-2">
        <div>
          <h1 className="font-serif text-4xl font-bold text-white sm:text-5xl">
            Sell Your Coins for a <span className="text-gold-sheen">Fair Price</span>
          </h1>
          <p className="mt-5 text-lg leading-relaxed text-silver-300">
            From a single key date to an entire estate collection, {site.name} makes selling simple.
            No consignment waits, no auction fees — just a fast, transparent, market-based offer from a
            buyer who has been in the business since {site.foundedYear}.
          </p>

          <div className="mt-8 space-y-5">
            {[
              { t: 'Tell Us What You Have', d: 'Send a few details and photos below. The more we know, the more accurate your offer.' },
              { t: 'Get a Fair Offer', d: 'We value your coins against live market data — often within one business day.' },
              { t: 'Ship Insured & Get Paid', d: 'Accept the offer, ship with a prepaid insured label, and get paid fast once verified.' },
            ].map((s, i) => (
              <div key={s.t} className="flex gap-4">
                <div className="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-full bg-gold-sheen font-bold text-ink-950">
                  {i + 1}
                </div>
                <div>
                  <h3 className="font-semibold text-white">{s.t}</h3>
                  <p className="mt-1 text-sm text-silver-300">{s.d}</p>
                </div>
              </div>
            ))}
          </div>

          <div className="mt-8 rounded-xl border border-gold-400/20 bg-gold-400/[0.05] p-5">
            <p className="text-sm text-silver-200">
              <span className="font-semibold text-gold-200">We buy:</span> Morgan &amp; Peace dollars,
              US &amp; world gold, ancient coins, type coins, proof &amp; mint sets, bullion, and
              complete collections. Prefer to talk?{' '}
              <a href={`tel:${site.phone.replace(/[^+\d]/g, '')}`} className="text-gold-300 hover:text-gold-200">
                Call {site.phone}
              </a>
              .
            </p>
          </div>
        </div>

        <div>
          <SellForm />
        </div>
      </div>
    </div>
  );
}
