import { BaseSourceAdapter } from './base';
import type { NormalizedListing, FetchOptions } from './types';
import { moneyMetalsListings } from '@/data/moneymetals-listings';

/**
 * Money Metals Exchange adapter (moneymetals.com).
 *
 * Pulls the dealer's top-selling coins and normalizes them for the importer,
 * which applies our flat 35% markup. Two modes:
 *
 *  - dryRun (default): returns the grounded 20-coin snapshot from
 *    src/data/moneymetals-listings.ts — so `npm run import` works with no
 *    network and the site can be populated immediately.
 *  - live (`--live`): fetches a real category/best-sellers page and extracts
 *    listings. It first tries schema.org JSON-LD (which Money Metals embeds),
 *    then falls back to a price/name heuristic. Run it where outbound network
 *    is allowed (this build sandbox blocks it).
 *
 * Respect the source's Terms of Service, robots.txt, and rate limits.
 */
export class MoneyMetalsAdapter extends BaseSourceAdapter {
  readonly id = 'moneymetals';
  readonly name = 'Money Metals Exchange';
  readonly baseUrl = 'https://www.moneymetals.com';

  /** Category pages to sweep for best-sellers, in priority order. */
  private readonly categoryPaths = [
    '/buy/silver/silver-dollars',
    '/buy/silver/coins',
    '/buy/gold/coins',
  ];

  async fetchListings(opts: FetchOptions = {}): Promise<NormalizedListing[]> {
    const limit = opts.limit ?? 20;

    // Default: grounded snapshot (no network needed).
    if (opts.dryRun !== false) {
      return moneyMetalsListings.slice(0, limit).map((l) => ({
        sourceListingId: l.id,
        title: l.title,
        sourcePrice: l.sourcePrice,
        sourceUrl: l.sourceUrl,
        year: l.year,
        denomination: l.denomination,
        series: l.series,
        country: l.country,
        metal: l.metal,
        gradingService: l.gradingService,
        grade: l.grade,
        description: l.description,
        categoryHint: l.categorySlug,
        quantityAvailable: 25,
      }));
    }

    // Live: sweep category pages until we have `limit` listings.
    const out: NormalizedListing[] = [];
    const seen = new Set<string>();
    for (const path of this.categoryPaths) {
      if (out.length >= limit) break;
      try {
        const html = await this.httpGet(this.baseUrl + path);
        for (const listing of this.parseListings(html)) {
          if (out.length >= limit) break;
          if (seen.has(listing.sourceListingId)) continue;
          seen.add(listing.sourceListingId);
          out.push(listing);
        }
      } catch (err) {
        console.error(`[moneymetals] ${path} failed:`, (err as Error).message);
      }
    }
    return out.slice(0, limit);
  }

  /** Extract listings from a category page: JSON-LD first, then heuristic. */
  private parseListings(html: string): NormalizedListing[] {
    const fromJsonLd = this.parseJsonLd(html);
    if (fromJsonLd.length) return fromJsonLd;
    return this.parseHeuristic(html);
  }

  /** Parse schema.org Product / ItemList blocks embedded as JSON-LD. */
  private parseJsonLd(html: string): NormalizedListing[] {
    const out: NormalizedListing[] = [];
    const blocks = html.match(
      /<script[^>]+type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi,
    );
    if (!blocks) return out;

    const pushProduct = (node: any) => {
      if (!node || node['@type'] !== 'Product') return;
      const offers = Array.isArray(node.offers) ? node.offers[0] : node.offers;
      const price = Number(offers?.price ?? offers?.lowPrice);
      if (!node.name || !price) return;
      const url: string = offers?.url ?? node.url ?? '';
      out.push(this.normalize(node.name, price, url, node.image));
    };

    for (const block of blocks) {
      const jsonText = block.replace(/^[\s\S]*?>/, '').replace(/<\/script>$/i, '');
      try {
        const data = JSON.parse(jsonText);
        const nodes = Array.isArray(data) ? data : data['@graph'] ?? [data];
        for (const node of nodes) {
          pushProduct(node);
          // ItemList of products
          const items = node?.itemListElement;
          if (Array.isArray(items)) items.forEach((el: any) => pushProduct(el?.item ?? el));
        }
      } catch {
        // Skip malformed JSON-LD block.
      }
    }
    return out;
  }

  /** Fallback: pair product links with nearby "$1,234.56" prices. */
  private parseHeuristic(html: string): NormalizedListing[] {
    const out: NormalizedListing[] = [];
    const rowRe =
      /<a[^>]+href=["']([^"']+)["'][^>]*>\s*([^<]{6,90}?(?:eagle|dollar|maple|krugerrand|britannia|philharmonic|panda|buffalo|sovereign|silver|gold)[^<]{0,40}?)<\/a>[\s\S]{0,400}?\$\s?([\d,]+(?:\.\d{2})?)/gi;
    let m: RegExpExecArray | null;
    while ((m = rowRe.exec(html)) && out.length < 60) {
      const [, href, rawName, rawPrice] = m;
      const price = Number(rawPrice.replace(/,/g, ''));
      const name = rawName.replace(/\s+/g, ' ').trim();
      if (!price || price < 5) continue;
      const url = href.startsWith('http') ? href : this.baseUrl + href;
      out.push(this.normalize(name, price, url));
    }
    return out;
  }

  /** Build a NormalizedListing from raw name/price/url using the base parsers. */
  private normalize(name: string, price: number, url: string, image?: string | string[]): NormalizedListing {
    const grade = BaseSourceAdapter.parseGrade(name);
    return {
      sourceListingId: url.split('/').filter(Boolean).pop() ?? BaseSourceAdapter.slugify(name),
      title: name,
      sourcePrice: price,
      sourceUrl: url,
      year: BaseSourceAdapter.parseYear(name),
      mintMark: BaseSourceAdapter.parseMintMark(name),
      metal: BaseSourceAdapter.parseMetal(name),
      gradingService: grade.service,
      grade: grade.grade ?? undefined,
      gradeNumeric: grade.numeric,
      imageUrls: image ? (Array.isArray(image) ? image : [image]) : [],
      quantityAvailable: 25,
    };
  }
}
