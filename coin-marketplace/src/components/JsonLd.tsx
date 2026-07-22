import { site } from '@/lib/site';
import type { Coin } from '@/lib/types';
import { getCategory } from '@/data/categories';

/**
 * Structured data (schema.org JSON-LD). This is the single biggest technical
 * SEO lever for a marketplace: it makes coins eligible for rich product results
 * (price, availability, ratings) and gives search engines an unambiguous map of
 * the site. Every listing, category, and breadcrumb emits the right type.
 */

function Script({ data }: { data: unknown }) {
  return (
    <script
      type="application/ld+json"
      // Data is built from our own trusted content.
      dangerouslySetInnerHTML={{ __html: JSON.stringify(data) }}
    />
  );
}

export function OrganizationJsonLd() {
  return (
    <Script
      data={{
        '@context': 'https://schema.org',
        '@type': 'Organization',
        name: site.name,
        legalName: site.legalName,
        url: site.url,
        description: site.shortDescription,
        foundingDate: String(site.foundedYear),
        email: site.email,
        telephone: site.phone,
        sameAs: Object.values(site.social),
        contactPoint: {
          '@type': 'ContactPoint',
          telephone: site.phone,
          contactType: 'sales',
          areaServed: 'US',
          availableLanguage: 'English',
        },
      }}
    />
  );
}

export function WebsiteJsonLd() {
  return (
    <Script
      data={{
        '@context': 'https://schema.org',
        '@type': 'WebSite',
        name: site.name,
        url: site.url,
        potentialAction: {
          '@type': 'SearchAction',
          target: {
            '@type': 'EntryPoint',
            urlTemplate: `${site.url}/coins?q={search_term_string}`,
          },
          'query-input': 'required name=search_term_string',
        },
      }}
    />
  );
}

export function ProductJsonLd({ coin }: { coin: Coin }) {
  const category = getCategory(coin.categorySlug);
  const url = `${site.url}/coins/${coin.slug}`;
  return (
    <Script
      data={{
        '@context': 'https://schema.org',
        '@type': 'Product',
        name: coin.title,
        description: coin.description || `${coin.title} for sale — certified and authenticity guaranteed.`,
        sku: coin.id,
        category: category?.name,
        brand: { '@type': 'Brand', name: coin.series || site.name },
        image: coin.images.length ? coin.images.map((i) => i.url) : `${site.url}/og/${coin.slug}.png`,
        offers: {
          '@type': 'Offer',
          url,
          priceCurrency: 'USD',
          price: coin.price,
          availability: coin.inStock
            ? 'https://schema.org/InStock'
            : 'https://schema.org/OutOfStock',
          itemCondition: 'https://schema.org/UsedCondition',
          seller: { '@type': 'Organization', name: site.name },
          priceValidUntil: `${new Date().getFullYear() + 1}-12-31`,
          shippingDetails: {
            '@type': 'OfferShippingDetails',
            shippingRate: { '@type': 'MonetaryAmount', value: 0, currency: 'USD' },
            shippingDestination: { '@type': 'DefinedRegion', addressCountry: 'US' },
          },
          hasMerchantReturnPolicy: {
            '@type': 'MerchantReturnPolicy',
            applicableCountry: 'US',
            returnPolicyCategory: 'https://schema.org/MerchantReturnFiniteReturnWindow',
            merchantReturnDays: 30,
            returnMethod: 'https://schema.org/ReturnByMail',
            returnFees: 'https://schema.org/FreeReturn',
          },
        },
      }}
    />
  );
}

export function BreadcrumbJsonLd({ items }: { items: { name: string; url: string }[] }) {
  return (
    <Script
      data={{
        '@context': 'https://schema.org',
        '@type': 'BreadcrumbList',
        itemListElement: items.map((item, i) => ({
          '@type': 'ListItem',
          position: i + 1,
          name: item.name,
          item: `${site.url}${item.url}`,
        })),
      }}
    />
  );
}

export function ItemListJsonLd({ coins, name }: { coins: Coin[]; name: string }) {
  return (
    <Script
      data={{
        '@context': 'https://schema.org',
        '@type': 'ItemList',
        name,
        numberOfItems: coins.length,
        itemListElement: coins.slice(0, 30).map((coin, i) => ({
          '@type': 'ListItem',
          position: i + 1,
          url: `${site.url}/coins/${coin.slug}`,
          name: coin.title,
        })),
      }}
    />
  );
}
