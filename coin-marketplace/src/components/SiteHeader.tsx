'use client';

import Link from 'next/link';
import { useState } from 'react';
import { site, nav } from '@/lib/site';
import { Logo } from '@/components/Logo';

export function SiteHeader() {
  const [open, setOpen] = useState(false);

  return (
    <header className="sticky top-0 z-40 border-b border-white/[0.06] bg-ink-950/80 backdrop-blur-md">
      {/* Trust bar */}
      <div className="hidden bg-gold-sheen text-ink-950 md:block">
        <div className="container-page flex items-center justify-center gap-6 py-1.5 text-xs font-semibold tracking-wide">
          {site.guarantees.map((g) => (
            <span key={g} className="flex items-center gap-1.5">
              <CheckIcon /> {g}
            </span>
          ))}
        </div>
      </div>

      <div className="container-page flex h-16 items-center justify-between gap-4">
        <Link href="/" className="flex items-center gap-2.5" aria-label={`${site.name} home`}>
          <Logo className="h-9 w-9" />
          <span className="font-serif text-xl font-bold tracking-tight text-white">
            Rare<span className="text-gold-sheen">Coins</span>
            <span className="text-silver-300">ForSale</span>
          </span>
        </Link>

        <nav className="hidden items-center gap-7 lg:flex" aria-label="Primary">
          {nav.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="link-underline text-sm font-medium text-silver-200 hover:text-white"
            >
              {item.label}
            </Link>
          ))}
        </nav>

        <div className="flex items-center gap-3">
          <Link href="/coins" className="hidden btn-outline !px-4 !py-2 sm:inline-flex">
            <SearchIcon /> Browse
          </Link>
          <Link href="/sell" className="btn-gold !px-4 !py-2 text-xs sm:text-sm">
            Sell Your Coins
          </Link>
          <button
            onClick={() => setOpen((v) => !v)}
            className="btn-ghost !px-2 !py-2 lg:hidden"
            aria-expanded={open}
            aria-label="Toggle menu"
          >
            <MenuIcon />
          </button>
        </div>
      </div>

      {open && (
        <nav className="container-page pb-4 lg:hidden" aria-label="Mobile">
          <div className="flex flex-col gap-1">
            {nav.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                onClick={() => setOpen(false)}
                className="rounded-lg px-3 py-2.5 text-sm font-medium text-silver-200 hover:bg-white/5 hover:text-white"
              >
                {item.label}
              </Link>
            ))}
          </div>
        </nav>
      )}
    </header>
  );
}

function CheckIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" aria-hidden>
      <path d="M20 6L9 17l-5-5" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}
function SearchIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden>
      <circle cx="11" cy="11" r="7" stroke="currentColor" strokeWidth="2" />
      <path d="M21 21l-4.3-4.3" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
    </svg>
  );
}
function MenuIcon() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden>
      <path d="M4 7h16M4 12h16M4 17h16" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
    </svg>
  );
}
