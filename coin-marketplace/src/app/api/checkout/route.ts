import { NextResponse } from 'next/server';
import { getStripe } from '@/lib/stripe';
import { getCoinBySlug } from '@/lib/catalog';
import { site } from '@/lib/site';

/**
 * Creates a Stripe Checkout Session for a single coin.
 *
 * Security: the client only sends the coin *slug*. The price, name, and image
 * are looked up from our own trusted catalog server-side — never trust a price
 * sent by the browser. Returns { url } to redirect the buyer to Stripe's hosted,
 * PCI-compliant checkout page.
 *
 * If Stripe isn't configured (no STRIPE_SECRET_KEY), returns 503 so the UI can
 * fall back to the reserve/call flow.
 */
export const dynamic = 'force-dynamic';

export async function POST(req: Request) {
  const stripe = getStripe();
  if (!stripe) {
    return NextResponse.json(
      { error: 'checkout_unavailable', message: 'Online checkout is not configured yet.' },
      { status: 503 },
    );
  }

  let slug: string | undefined;
  try {
    const body = await req.json();
    slug = typeof body?.slug === 'string' ? body.slug : undefined;
  } catch {
    return NextResponse.json({ error: 'bad_request' }, { status: 400 });
  }

  const coin = slug ? getCoinBySlug(slug) : undefined;
  if (!coin) {
    return NextResponse.json({ error: 'coin_not_found' }, { status: 404 });
  }
  if (!coin.inStock) {
    return NextResponse.json({ error: 'out_of_stock' }, { status: 409 });
  }

  // Prefer the real request origin (works in dev + prod); fall back to config.
  const origin = req.headers.get('origin') ?? site.url;

  try {
    const session = await stripe.checkout.sessions.create({
      mode: 'payment',
      submit_type: 'pay',
      line_items: [
        {
          quantity: 1,
          price_data: {
            currency: 'usd',
            unit_amount: Math.round(coin.price * 100), // cents, from trusted catalog
            product_data: {
              name: coin.title,
              description: `${coin.gradingService} ${coin.grade} · ${coin.series}`.slice(0, 300),
              metadata: { coinId: coin.id, slug: coin.slug },
            },
          },
        },
      ],
      // Collect what we need to source + ship the coin.
      shipping_address_collection: { allowed_countries: ['US'] },
      phone_number_collection: { enabled: true },
      metadata: {
        coinId: coin.id,
        slug: coin.slug,
        sourceName: coin.source.name,
        sourcePrice: String(coin.sourcePrice),
        salePrice: String(coin.price),
      },
      success_url: `${origin}/checkout/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${origin}/coins/${coin.slug}?checkout=cancelled`,
    });

    return NextResponse.json({ url: session.url });
  } catch (err) {
    console.error('[checkout] Stripe error:', (err as Error).message);
    return NextResponse.json({ error: 'stripe_error' }, { status: 502 });
  }
}
