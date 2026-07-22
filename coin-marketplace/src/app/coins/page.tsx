import type { Metadata } from 'next';
import Link from 'next/link';
import { site } from '@/lib/site';
import {
  getAllCoins,
  filterCoins,
  sortCoins,
  facetsFor,
  type CoinFilters,
  type SortKey,
} from '@/lib/catalog';
import { categories } from '@/data/categories';
import { CoinGrid } from '@/components/CoinCard';
import { Breadcrumbs } from '@/components/Breadcrumbs';
import { ItemListJsonLd } from '@/components/JsonLd';

export const metadata: Metadata = {
  title: 'Shop All Coins for Sale — Certified & Guaranteed',
  description:
    'Browse our full inventory of certified rare and collectible coins for sale. Filter by category, metal, series, grade and price. Every coin PCGS or NGC graded.',
  alternates: { canonical: '/coins' },
};

type SearchParams = { [key: string]: string | string[] | undefined };

function str(v: string | string[] | undefined): string | undefined {
  return Array.isArray(v) ? v[0] : v;
}

export default async function CoinsPage({
  searchParams,
}: {
  searchParams: Promise<SearchParams>;
}) {
  const sp = await searchParams;
  const filters: CoinFilters = {
    category: str(sp.category),
    metal: str(sp.metal),
    series: str(sp.series),
    gradingService: str(sp.gradingService),
    country: str(sp.country),
    q: str(sp.q),
    minPrice: sp.minPrice ? Number(str(sp.minPrice)) : undefined,
    maxPrice: sp.maxPrice ? Number(str(sp.maxPrice)) : undefined,
  };
  const sort = (str(sp.sort) as SortKey) || 'featured';

  const all = getAllCoins();
  const facets = facetsFor(all);
  const filtered = sortCoins(filterCoins(all, filters), sort);

  // Helper to build a URL preserving other params while toggling one.
  const buildHref = (key: string, value?: string) => {
    const params = new URLSearchParams();
    for (const [k, v] of Object.entries(sp)) {
      const val = str(v);
      if (val && k !== key) params.set(k, val);
    }
    if (value && filters[key as keyof CoinFilters] !== value) params.set(key, value);
    const qs = params.toString();
    return `/coins${qs ? `?${qs}` : ''}`;
  };

  const activeFilters = Object.entries(filters).filter(([, v]) => v !== undefined && v !== '');

  return (
    <div className="container-page py-8">
      <Breadcrumbs
        items={[
          { name: 'Home', url: '/' },
          { name: 'Shop All Coins', url: '/coins' },
        ]}
      />

      <ItemListJsonLd coins={filtered} name="Coins for Sale" />

      <div className="mt-6 flex flex-col gap-2 border-b border-white/[0.06] pb-6 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h1 className="font-serif text-3xl font-bold text-white sm:text-4xl">
            {filters.q ? `“${filters.q}”` : 'All Coins for Sale'}
          </h1>
          <p className="mt-2 text-sm text-silver-400">
            {filtered.length} {filtered.length === 1 ? 'coin' : 'coins'} · certified &amp; authenticity
            guaranteed
          </p>
        </div>

        {/* Search + sort (GET form keeps it crawlable & JS-optional) */}
        <form method="get" className="flex flex-wrap items-center gap-2">
          <input
            type="search"
            name="q"
            defaultValue={filters.q}
            placeholder="Search coins…"
            className="w-44 rounded-full border border-white/10 bg-ink-800 px-4 py-2 text-sm text-silver-100 placeholder:text-silver-500 focus:border-gold-400/50 focus:outline-none"
          />
          <select
            name="sort"
            defaultValue={sort}
            className="rounded-full border border-white/10 bg-ink-800 px-3 py-2 text-sm text-silver-100 focus:border-gold-400/50 focus:outline-none"
          >
            <option value="featured">Featured</option>
            <option value="price-asc">Price: Low to High</option>
            <option value="price-desc">Price: High to Low</option>
            <option value="year-desc">Newest Year</option>
            <option value="year-asc">Oldest Year</option>
            <option value="grade-desc">Highest Grade</option>
          </select>
          <button type="submit" className="btn-gold !px-4 !py-2 text-sm">
            Apply
          </button>
        </form>
      </div>

      <div className="mt-6 grid gap-8 lg:grid-cols-[240px_1fr]">
        {/* Sidebar facets */}
        <aside className="space-y-6">
          {activeFilters.length > 0 && (
            <div className="flex flex-wrap gap-2">
              {activeFilters.map(([k, v]) => (
                <Link
                  key={k}
                  href={buildHref(k)}
                  className="chip border-gold-400/40 text-gold-200 hover:bg-gold-400/10"
                >
                  {String(v)} ✕
                </Link>
              ))}
              <Link href="/coins" className="chip hover:bg-white/5">
                Clear all
              </Link>
            </div>
          )}

          <FacetGroup title="Category">
            {categories.map((c) => (
              <FacetLink key={c.slug} href={buildHref('category', c.slug)} active={filters.category === c.slug}>
                {c.name}
              </FacetLink>
            ))}
          </FacetGroup>

          <FacetGroup title="Metal">
            {facets.metals.map((m) => (
              <FacetLink key={m} href={buildHref('metal', m)} active={filters.metal === m}>
                {m}
              </FacetLink>
            ))}
          </FacetGroup>

          <FacetGroup title="Series">
            {facets.series.map((s) => (
              <FacetLink key={s} href={buildHref('series', s)} active={filters.series === s}>
                {s}
              </FacetLink>
            ))}
          </FacetGroup>

          <FacetGroup title="Grading Service">
            {facets.gradingServices.map((g) => (
              <FacetLink key={g} href={buildHref('gradingService', g)} active={filters.gradingService === g}>
                {g}
              </FacetLink>
            ))}
          </FacetGroup>
        </aside>

        {/* Results */}
        <div>
          {filtered.length > 0 ? (
            <CoinGrid coins={filtered} />
          ) : (
            <div className="card flex flex-col items-center gap-4 p-16 text-center">
              <p className="text-lg font-semibold text-white">No coins match those filters.</p>
              <p className="text-sm text-silver-400">Try clearing a filter or searching a different term.</p>
              <Link href="/coins" className="btn-outline">
                Reset filters
              </Link>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function FacetGroup({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div>
      <h2 className="mb-3 text-xs font-semibold uppercase tracking-wider text-gold-200">{title}</h2>
      <ul className="space-y-1.5">{children}</ul>
    </div>
  );
}
function FacetLink({ href, active, children }: { href: string; active: boolean; children: React.ReactNode }) {
  return (
    <li>
      <Link
        href={href}
        className={[
          'block rounded-lg px-3 py-1.5 text-sm transition-colors',
          active ? 'bg-gold-400/15 font-semibold text-gold-100' : 'text-silver-300 hover:bg-white/5 hover:text-white',
        ].join(' ')}
      >
        {children}
      </Link>
    </li>
  );
}
