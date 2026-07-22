import type { Metadata } from 'next';
import Link from 'next/link';
import { getStripe } from '@/lib/stripe';
import { site } from '@/lib/site';
import { Logo } from '@/components/Logo';
import { formatUsd } from '@/lib/pricing';

export const metadata: Metadata = {
  title: 'Order Confirmed — Thank You',
  robots: { index: false, follow: false }, // don't index order confirmations
};

export const dynamic = 'force-dynamic';

export default async function CheckoutSuccessPage({
  searchParams,
}: {
  searchParams: Promise<{ session_id?: string }>;
}) {
  const { session_id } = await searchParams;
  const stripe = getStripe();

  let email: string | null = null;
  let amount: number | null = null;
  let itemName: string | null = null;

  if (stripe && session_id) {
    try {
      const session = await stripe.checkout.sessions.retrieve(session_id, {
        expand: ['line_items'],
      });
      email = session.customer_details?.email ?? null;
      amount = session.amount_total != null ? session.amount_total / 100 : null;
      itemName = session.line_items?.data?.[0]?.description ?? null;
    } catch {
      // Session lookup failed — still show a generic success message.
    }
  }

  return (
    <div className="container-page flex min-h-[60vh] flex-col items-center justify-center py-20 text-center">
      <div className="flex h-16 w-16 items-center justify-center rounded-full bg-gold-sheen text-3xl text-ink-950">
        ✓
      </div>
      <h1 className="mt-6 font-serif text-4xl font-bold text-white">Thank you for your order!</h1>
      <p className="mt-4 max-w-lg text-silver-300">
        Your payment was received{email ? ` and a confirmation is on its way to ${email}` : ''}. Our
        team will now secure your coin, verify it, and ship it fully insured in tamper-evident
        packaging — backed by our lifetime authenticity guarantee.
      </p>

      {(itemName || amount != null) && (
        <div className="mt-8 w-full max-w-sm rounded-2xl border border-white/[0.08] bg-ink-900/70 p-6 text-left">
          {itemName && (
            <div className="flex items-center justify-between border-b border-white/[0.06] py-2 text-sm">
              <span className="text-silver-400">Item</span>
              <span className="text-silver-100">{itemName}</span>
            </div>
          )}
          {amount != null && (
            <div className="flex items-center justify-between py-2 text-sm">
              <span className="text-silver-400">Total paid</span>
              <span className="font-semibold text-gold-200">{formatUsd(amount)}</span>
            </div>
          )}
        </div>
      )}

      <div className="mt-8 flex flex-wrap justify-center gap-3">
        <Link href="/coins" className="btn-gold">
          Continue Shopping
        </Link>
        <Link href="/learn" className="btn-outline">
          Read Our Coin Guides
        </Link>
      </div>

      <p className="mt-8 flex items-center gap-2 text-xs text-silver-500">
        <Logo className="h-5 w-5" /> Questions? Call {site.phone}
      </p>
    </div>
  );
}
