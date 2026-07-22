import type { Metadata } from 'next';
import Link from 'next/link';
import { site } from '@/lib/site';
import { Breadcrumbs } from '@/components/Breadcrumbs';

export const metadata: Metadata = {
  title: 'How It Works — Buying & Selling Rare Coins',
  description:
    'Learn how Crystal Coins works: how we source certified coins, our authenticity guarantee, insured shipping, 30-day returns, and how selling to us works.',
  alternates: { canonical: '/how-it-works' },
};

const faqs = [
  {
    q: 'Are your coins authentic?',
    a: 'Yes — unconditionally. The vast majority of our coins are certified by PCGS or NGC, the two leading third-party grading services. Every coin we sell is backed by our lifetime authenticity guarantee.',
  },
  {
    q: 'How does shipping work?',
    a: `Every order ships fully insured in discreet, tamper-evident packaging with tracking and signature confirmation. Shipping is free on orders over ${'$' + site.freeShippingThreshold}.`,
  },
  {
    q: 'What is your return policy?',
    a: 'You have 30 days to return any coin for a full refund, no questions asked. If a coin is not exactly as described, we make it right.',
  },
  {
    q: 'How are your prices set?',
    a: 'We aggregate certified coins from the world’s most reputable dealers and auction houses, then price transparently against live market data. You get one trusted place to shop the entire market.',
  },
  {
    q: 'Can I sell my coins to you?',
    a: 'Absolutely. From a single coin to an entire estate, we make fair, market-based offers with fast payment and no auction fees. Visit our Sell page to get started.',
  },
];

export default function HowItWorksPage() {
  return (
    <div className="container-page py-8">
      <Breadcrumbs items={[{ name: 'Home', url: '/' }, { name: 'How It Works', url: '/how-it-works' }]} />

      {/* FAQ structured data for rich results */}
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify({
            '@context': 'https://schema.org',
            '@type': 'FAQPage',
            mainEntity: faqs.map((f) => ({
              '@type': 'Question',
              name: f.q,
              acceptedAnswer: { '@type': 'Answer', text: f.a },
            })),
          }),
        }}
      />

      <div className="mx-auto mt-6 max-w-3xl">
        <h1 className="font-serif text-4xl font-bold text-white sm:text-5xl">How It Works</h1>
        <p className="mt-5 text-lg leading-relaxed text-silver-300">
          {site.name} brings the entire rare-coin market into one trusted destination. Here is exactly
          what happens when you buy — and how selling to us works.
        </p>

        {/* Buying steps */}
        <div className="mt-12 space-y-6">
          {[
            {
              t: '1. Browse one curated catalog',
              d: 'We aggregate certified coins from the world’s top dealers and auction houses so you can shop the whole market in one place — no more chasing listings across a dozen sites.',
            },
            {
              t: '2. Order with confidence',
              d: 'When you place an order, we immediately secure your exact coin from our verified source and take delivery ourselves. Every coin is inspected before it moves.',
            },
            {
              t: '3. We verify & insure',
              d: 'Your coin is checked against its certification, then packed in tamper-evident, fully insured packaging.',
            },
            {
              t: '4. Delivered to your door',
              d: 'Track your coin every step of the way, backed by our lifetime authenticity guarantee and a 30-day money-back return policy.',
            },
          ].map((s) => (
            <div key={s.t} className="card p-6">
              <h2 className="font-serif text-xl font-semibold text-gold-100">{s.t}</h2>
              <p className="mt-2 text-sm leading-relaxed text-silver-300">{s.d}</p>
            </div>
          ))}
        </div>

        {/* Guarantees */}
        <div className="mt-12 grid gap-4 sm:grid-cols-2">
          {site.guarantees.map((g) => (
            <div key={g} className="flex items-center gap-3 rounded-xl border border-gold-400/20 bg-gold-400/[0.05] p-4">
              <span className="text-gold-400">✦</span>
              <span className="text-sm font-medium text-silver-100">{g}</span>
            </div>
          ))}
        </div>

        {/* FAQ */}
        <h2 className="mt-16 font-serif text-3xl font-bold text-white">Frequently Asked Questions</h2>
        <div className="mt-6 space-y-3">
          {faqs.map((f) => (
            <details key={f.q} className="card group p-5">
              <summary className="flex cursor-pointer list-none items-center justify-between font-semibold text-silver-100">
                {f.q}
                <span className="text-gold-400 transition-transform group-open:rotate-45">+</span>
              </summary>
              <p className="mt-3 text-sm leading-relaxed text-silver-300">{f.a}</p>
            </details>
          ))}
        </div>

        <div className="mt-12 flex flex-wrap gap-3">
          <Link href="/coins" className="btn-gold">
            Start Browsing
          </Link>
          <Link href="/sell" className="btn-outline">
            Sell Your Coins
          </Link>
        </div>
      </div>
    </div>
  );
}
