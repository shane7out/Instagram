import type { MetadataRoute } from 'next';
import { site } from '@/lib/site';
import { getAllCoins } from '@/lib/catalog';
import { categories } from '@/data/categories';
import { landingPages } from '@/lib/landing';

/**
 * Dynamic sitemap. Every coin, category, and programmatic landing page is
 * listed so search engines discover and index the entire catalog. Regenerated
 * on each build (and on-demand with ISR), so new inventory shows up fast.
 */
export default function sitemap(): MetadataRoute.Sitemap {
  const now = new Date();

  const staticRoutes: MetadataRoute.Sitemap = [
    { url: `${site.url}/`, lastModified: now, changeFrequency: 'daily', priority: 1 },
    { url: `${site.url}/coins`, lastModified: now, changeFrequency: 'daily', priority: 0.9 },
    { url: `${site.url}/buy`, lastModified: now, changeFrequency: 'weekly', priority: 0.8 },
    { url: `${site.url}/sell`, lastModified: now, changeFrequency: 'monthly', priority: 0.7 },
    { url: `${site.url}/how-it-works`, lastModified: now, changeFrequency: 'monthly', priority: 0.6 },
    { url: `${site.url}/about`, lastModified: now, changeFrequency: 'monthly', priority: 0.5 },
  ];

  const categoryRoutes: MetadataRoute.Sitemap = categories.map((c) => ({
    url: `${site.url}/category/${c.slug}`,
    lastModified: now,
    changeFrequency: 'daily',
    priority: 0.8,
  }));

  const landingRoutes: MetadataRoute.Sitemap = landingPages.map((l) => ({
    url: `${site.url}/buy/${l.slug}`,
    lastModified: now,
    changeFrequency: 'weekly',
    priority: 0.7,
  }));

  const coinRoutes: MetadataRoute.Sitemap = getAllCoins().map((coin) => ({
    url: `${site.url}/coins/${coin.slug}`,
    lastModified: new Date(coin.lastSyncedAt),
    changeFrequency: 'weekly',
    priority: 0.7,
  }));

  return [...staticRoutes, ...categoryRoutes, ...landingRoutes, ...coinRoutes];
}
