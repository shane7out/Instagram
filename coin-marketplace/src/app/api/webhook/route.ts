import { NextResponse } from 'next/server';
import { getStripe } from '@/lib/stripe';

/**
 * Stripe webhook endpoint.
 *
 * This is the automation hub of the arbitrage model. When Stripe confirms a
 * payment (`checkout.session.completed`), this fires — the moment to:
 *   1. record the order,
 *   2. place the buy with the source dealer (the coin's `sourceName`/price are
 *      in the session metadata),
 *   3. kick off fulfillment (get delivery, then ship to the customer),
 *   4. email the customer their confirmation + tracking.
 *
 * Signature verification uses STRIPE_WEBHOOK_SECRET so only genuine Stripe
 * events are trusted. Point a Stripe webhook at /api/webhook and paste the
 * signing secret into that env var.
 */
export const dynamic = 'force-dynamic';

export async function POST(req: Request) {
  const stripe = getStripe();
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
  if (!stripe || !webhookSecret) {
    return NextResponse.json({ error: 'webhook_not_configured' }, { status: 503 });
  }

  const signature = req.headers.get('stripe-signature');
  if (!signature) {
    return NextResponse.json({ error: 'missing_signature' }, { status: 400 });
  }

  // Raw body is required for signature verification.
  const payload = await req.text();

  let event;
  try {
    event = stripe.webhooks.constructEvent(payload, signature, webhookSecret);
  } catch (err) {
    console.error('[webhook] signature verification failed:', (err as Error).message);
    return NextResponse.json({ error: 'invalid_signature' }, { status: 400 });
  }

  switch (event.type) {
    case 'checkout.session.completed': {
      const session = event.data.object;
      const meta = session.metadata ?? {};
      // TODO fulfillment: record order, place the source buy, ship, email.
      console.log('[webhook] payment complete', {
        coinId: meta.coinId,
        slug: meta.slug,
        source: meta.sourceName,
        sourcePrice: meta.sourcePrice,
        salePrice: meta.salePrice,
        customerEmail: session.customer_details?.email,
        amountTotal: session.amount_total,
      });
      break;
    }
    default:
      // Ignore other event types for now.
      break;
  }

  return NextResponse.json({ received: true });
}
