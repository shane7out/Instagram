'use client';

import { useState } from 'react';

/**
 * Lead-capture form for the sell flow. In this build it validates and confirms
 * on the client; wire `onSubmit` to your CRM / email / webhook when live.
 */
export function SellForm() {
  const [submitted, setSubmitted] = useState(false);

  if (submitted) {
    return (
      <div className="card flex h-full flex-col items-center justify-center gap-4 p-10 text-center">
        <div className="flex h-16 w-16 items-center justify-center rounded-full bg-gold-sheen text-2xl text-ink-950">
          ✓
        </div>
        <h2 className="font-serif text-2xl font-bold text-white">Offer request received!</h2>
        <p className="max-w-sm text-sm text-silver-300">
          Thank you. Our numismatic team will review your coins and reach out — usually within one
          business day — with a fair, market-based offer.
        </p>
        <button className="btn-outline mt-2" onClick={() => setSubmitted(false)}>
          Submit another
        </button>
      </div>
    );
  }

  return (
    <form
      className="card space-y-4 p-6 sm:p-8"
      onSubmit={(e) => {
        e.preventDefault();
        setSubmitted(true);
      }}
    >
      <h2 className="font-serif text-2xl font-bold text-white">Get Your Free Offer</h2>
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Full name" name="name" required />
        <Field label="Email" name="email" type="email" required />
      </div>
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Phone" name="phone" type="tel" />
        <div>
          <label className="mb-1.5 block text-sm font-medium text-silver-200">
            What are you selling?
          </label>
          <select
            name="type"
            className="w-full rounded-lg border border-white/10 bg-ink-800 px-3 py-2.5 text-sm text-silver-100 focus:border-gold-400/50 focus:outline-none"
          >
            <option>A few coins</option>
            <option>A full collection</option>
            <option>An estate / inheritance</option>
            <option>Bullion</option>
            <option>Not sure — need help</option>
          </select>
        </div>
      </div>
      <div>
        <label className="mb-1.5 block text-sm font-medium text-silver-200">
          Describe your coins
        </label>
        <textarea
          name="details"
          rows={5}
          placeholder="e.g. 1889-CC Morgan dollar PCGS VF-30, roll of silver Peace dollars, grandfather's world coin collection…"
          className="w-full rounded-lg border border-white/10 bg-ink-800 px-3 py-2.5 text-sm text-silver-100 placeholder:text-silver-500 focus:border-gold-400/50 focus:outline-none"
        />
      </div>
      <button type="submit" className="btn-gold w-full !py-3.5 text-base">
        Request My Free Offer
      </button>
      <p className="text-center text-xs text-silver-500">
        No obligation. We’ll never share your information.
      </p>
    </form>
  );
}

function Field({
  label,
  name,
  type = 'text',
  required,
}: {
  label: string;
  name: string;
  type?: string;
  required?: boolean;
}) {
  return (
    <div>
      <label className="mb-1.5 block text-sm font-medium text-silver-200">
        {label}
        {required && <span className="text-gold-400"> *</span>}
      </label>
      <input
        type={type}
        name={name}
        required={required}
        className="w-full rounded-lg border border-white/10 bg-ink-800 px-3 py-2.5 text-sm text-silver-100 placeholder:text-silver-500 focus:border-gold-400/50 focus:outline-none"
      />
    </div>
  );
}
