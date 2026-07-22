'use client';

import { useState } from 'react';
import type { Coin } from '@/lib/types';
import { site } from '@/lib/site';
import { formatUsd } from '@/lib/pricing';

/**
 * Purchase panel. "Buy This Coin" starts a real Stripe Checkout session via
 * /api/checkout and redirects to Stripe's hosted payment page. If Stripe isn't
 * configured yet (no keys), it gracefully falls back to reserving the coin so
 * the concierge can follow up — the arbitrage model: on purchase we source the
 * coin from the dealer, take delivery, and ship it on.
 */
export function BuyPanel({ coin }: { coin: Coin }) {
  const [reserved, setReserved] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const freeShipping = coin.price >= site.freeShippingThreshold;

  async function handleBuy() {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch('/api/checkout', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ slug: coin.slug }),
      });
      if (res.ok) {
        const { url } = await res.json();
        if (url) {
          window.location.href = url; // redirect to Stripe Checkout
          return;
        }
      }
      // 503 = checkout not configured yet → fall back to reserve flow.
      if (res.status === 503) {
        setReserved(true);
      } else {
        setError('Something went wrong starting checkout. Please call to order.');
      }
    } catch {
      setError('Network error. Please call to order.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="mt-7 rounded-2xl border border-white/[0.08] bg-ink-900/70 p-6">
      <div className="flex items-end justify-between">
        <div>
          <div className="font-serif text-3xl font-bold text-gold-200">{formatUsd(coin.price)}</div>
          {coin.compareAtPrice && coin.compareAtPrice > coin.price && (
            <div className="mt-1 text-sm text-silver-400">
              <span className="line-through">{formatUsd(coin.compareAtPrice)}</span>{' '}
              <span className="font-semibold text-emerald-400">
                Save {formatUsd(coin.compareAtPrice - coin.price)}
              </span>
            </div>
          )}
        </div>
        <span
          className={[
            'chip',
            coin.inStock ? 'border-emerald-400/30 text-emerald-300' : 'border-red-400/30 text-red-300',
          ].join(' ')}
        >
          <span className={`h-1.5 w-1.5 rounded-full ${coin.inStock ? 'bg-emerald-400' : 'bg-red-400'}`} />
          {coin.inStock ? 'In Stock — Ready to Ship' : 'Sold'}
        </span>
      </div>

      <div className="mt-5 flex flex-col gap-3">
        <button
          type="button"
          disabled={!coin.inStock || reserved || loading}
          onClick={handleBuy}
          className="btn-gold w-full !py-3.5 text-base disabled:cursor-not-allowed disabled:opacity-60"
        >
          {loading
            ? 'Starting secure checkout…'
            : reserved
              ? '✓ Reserved — we’ll be in touch'
              : coin.inStock
                ? 'Buy This Coin'
                : 'Sold Out'}
        </button>
        <a href={`tel:${site.phone.replace(/[^+\d]/g, '')}`} className="btn-outline w-full !py-3">
          Call to Order · {site.phone}
        </a>
      </div>

      {error && (
        <p className="mt-4 rounded-lg bg-red-500/10 p-3 text-sm text-red-200">{error}</p>
      )}

      {reserved && (
        <p className="mt-4 rounded-lg bg-emerald-500/10 p-3 text-sm text-emerald-200">
          Thanks! This coin is reserved for you. Our concierge will confirm your order and secure the
          coin from our verified source before it ships — fully insured, in tamper-evident packaging.
        </p>
      )}

      <ul className="mt-5 space-y-2 text-xs text-silver-400">
        <li className="flex items-center gap-2">
          <TruckIcon />
          {freeShipping
            ? 'FREE fully-insured shipping'
            : `Insured shipping · free over ${formatUsd(site.freeShippingThreshold)}`}
        </li>
        <li className="flex items-center gap-2">
          <ShieldIcon /> Lifetime authenticity guarantee · 30-day returns
        </li>
        <li className="flex items-center gap-2">
          <LockIcon /> Secure checkout · trusted since {site.foundedYear}
        </li>
      </ul>
    </div>
  );
}

function TruckIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" className="text-gold-400" aria-hidden>
      <path d="M1 4h13v10H1zM14 8h4l3 3v3h-7z" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
      <circle cx="5.5" cy="17" r="1.8" stroke="currentColor" strokeWidth="1.5" />
      <circle cx="17.5" cy="17" r="1.8" stroke="currentColor" strokeWidth="1.5" />
    </svg>
  );
}
function ShieldIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" className="text-gold-400" aria-hidden>
      <path d="M12 2l8 3v6c0 5-3.5 8.5-8 11-4.5-2.5-8-6-8-11V5l8-3z" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
    </svg>
  );
}
function LockIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" className="text-gold-400" aria-hidden>
      <rect x="4" y="10" width="16" height="11" rx="2" stroke="currentColor" strokeWidth="1.5" />
      <path d="M8 10V7a4 4 0 118 0v3" stroke="currentColor" strokeWidth="1.5" />
    </svg>
  );
}
