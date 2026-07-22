import Link from 'next/link';
import { site } from '@/lib/site';
import { topCategories, categories } from '@/data/categories';
import { Logo } from '@/components/Logo';

/**
 * SEO-rich footer: internal links to every category and popular landing page.
 * A deep, crawlable footer spreads link equity to money pages on every view.
 */
export function SiteFooter() {
  const year = 2026;
  return (
    <footer className="mt-24 border-t border-white/[0.06] bg-ink-900/50">
      <div className="container-page grid gap-10 py-14 md:grid-cols-2 lg:grid-cols-5">
        <div className="lg:col-span-2">
          <div className="flex items-center gap-2.5">
            <Logo className="h-8 w-8" />
            <span className="font-serif text-lg font-bold text-white">{site.name}</span>
          </div>
          <p className="mt-4 max-w-sm text-sm leading-relaxed text-silver-300">
            {site.shortDescription}
          </p>
          <div className="mt-5 flex flex-wrap gap-2">
            {site.guarantees.map((g) => (
              <span key={g} className="chip">
                {g}
              </span>
            ))}
          </div>
          <p className="mt-6 text-sm text-silver-300">
            <a href={`tel:${site.phone.replace(/[^+\d]/g, '')}`} className="link-underline">
              {site.phone}
            </a>
            {' · '}
            <a href={`mailto:${site.email}`} className="link-underline">
              {site.email}
            </a>
          </p>
        </div>

        <FooterCol title="Shop Coins">
          <FooterLink href="/coins">All Coins</FooterLink>
          {categories.map((c) => (
            <FooterLink key={c.slug} href={`/category/${c.slug}`}>
              {c.name}
            </FooterLink>
          ))}
        </FooterCol>

        <FooterCol title="Popular Searches">
          <FooterLink href="/coins?q=morgan">Morgan Silver Dollars</FooterLink>
          <FooterLink href="/coins?q=saint">Saint-Gaudens $20</FooterLink>
          <FooterLink href="/coins?metal=Gold">Gold Coins</FooterLink>
          <FooterLink href="/coins?q=key+date">Key Dates</FooterLink>
          <FooterLink href="/coins?series=Peace+Dollar">Peace Dollars</FooterLink>
          <FooterLink href="/coins?category=ancient-coins">Ancient Coins</FooterLink>
        </FooterCol>

        <FooterCol title="Company">
          <FooterLink href="/how-it-works">How It Works</FooterLink>
          <FooterLink href="/sell">Sell Your Coins</FooterLink>
          <FooterLink href="/about">About Us</FooterLink>
          <FooterLink href="/coins">Browse Inventory</FooterLink>
          <FooterLink href="/sitemap.xml">Sitemap</FooterLink>
        </FooterCol>
      </div>

      <div className="hairline">
        <div className="container-page flex flex-col items-center justify-between gap-3 py-6 text-xs text-silver-400 md:flex-row">
          <p>
            © {year} {site.legalName}. All rights reserved. Coin images are illustrative.
          </p>
          <p className="flex flex-wrap items-center gap-4">
            <Link href="/how-it-works" className="hover:text-silver-200">
              Authenticity Guarantee
            </Link>
            <Link href="/how-it-works" className="hover:text-silver-200">
              Shipping & Returns
            </Link>
            <span>Est. {site.foundedYear}</span>
          </p>
        </div>
      </div>
    </footer>
  );
}

function FooterCol({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div>
      <h3 className="text-sm font-semibold uppercase tracking-wider text-gold-200">{title}</h3>
      <ul className="mt-4 space-y-2.5 text-sm">{children}</ul>
    </div>
  );
}
function FooterLink({ href, children }: { href: string; children: React.ReactNode }) {
  return (
    <li>
      <Link href={href} className="text-silver-300 transition-colors hover:text-white">
        {children}
      </Link>
    </li>
  );
}
