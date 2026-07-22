import Stripe from 'stripe';

/**
 * Server-side Stripe client.
 *
 * Initialized lazily from STRIPE_SECRET_KEY so the app builds and runs fine
 * with no keys configured (checkout simply falls back to the reserve/contact
 * flow). NEVER import this into a client component — the secret key must stay
 * on the server.
 */
let cached: Stripe | null = null;

export function getStripe(): Stripe | null {
  const key = process.env.STRIPE_SECRET_KEY;
  if (!key) return null;
  if (!cached) {
    // Use the SDK's pinned API version (no override needed).
    cached = new Stripe(key);
  }
  return cached;
}

/** Whether live checkout is available (a secret key is configured). */
export function isCheckoutEnabled(): boolean {
  return Boolean(process.env.STRIPE_SECRET_KEY);
}
