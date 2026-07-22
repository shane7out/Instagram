import { BaseSourceAdapter } from './base';
import type { NormalizedListing, FetchOptions } from './types';

/**
 * Example adapter: Heritage Auctions (coins.ha.com).
 *
 * This shows the shape a real adapter takes. In `dryRun` mode it returns baked
 * fixtures so the importer can be exercised end-to-end with no network access.
 * To go live, implement the two TODOs: call the source's search/listing
 * endpoint in `fetchListings`, and map each raw row to a NormalizedListing in
 * `mapRow`. The base class provides the field parsers.
 *
 * Always respect the source's Terms of Service, robots.txt, and rate limits.
 */
export class HeritageAdapter extends BaseSourceAdapter {
  readonly id = 'heritage';
  readonly name = 'Heritage Auctions';
  readonly baseUrl = 'https://coins.ha.com';

  async fetchListings(opts: FetchOptions = {}): Promise<NormalizedListing[]> {
    if (opts.dryRun !== false) {
      // Default to fixtures unless the caller explicitly opts into live network.
      return this.fixtures(opts.limit);
    }

    // ---- Live path (implement for production) ----
    // 1. Build a search URL from opts.query and pagination.
    // const url = `${this.baseUrl}/c/search-results.zx?N=...&Nty=1&Ntt=${encodeURIComponent(opts.query ?? '')}`;
    // 2. Fetch and parse the results (HTML or JSON API).
    // const html = await this.httpGet(url);
    // 3. Extract raw rows and map each with this.mapRow(row).
    throw new Error(
      'HeritageAdapter live fetch not implemented — run with { dryRun: true } to use fixtures.',
    );
  }

  /** Map one raw source row (title + price + url + optional fields) to normalized. */
  private mapRow(row: { title: string; priceText: string; url: string; imageUrl?: string; description?: string }): NormalizedListing {
    const { service, grade, numeric } = BaseSourceAdapter.parseGrade(row.title);
    return {
      sourceListingId: row.url.split('/').pop() ?? BaseSourceAdapter.slugify(row.title),
      title: row.title,
      sourcePrice: BaseSourceAdapter.parsePrice(row.priceText) ?? 0,
      sourceUrl: row.url,
      year: BaseSourceAdapter.parseYear(row.title),
      mintMark: BaseSourceAdapter.parseMintMark(row.title),
      metal: BaseSourceAdapter.parseMetal(`${row.title} ${row.description ?? ''}`),
      gradingService: service,
      grade: grade ?? undefined,
      gradeNumeric: numeric,
      imageUrls: row.imageUrl ? [row.imageUrl] : [],
      description: row.description,
      quantityAvailable: 1,
    };
  }

  /** Offline fixtures so the pipeline is runnable without network access. */
  private fixtures(limit?: number): NormalizedListing[] {
    const rows = [
      {
        title: '1885-CC Morgan Silver Dollar PCGS MS-64',
        priceText: '$1,350.00',
        url: 'https://coins.ha.com/itm/morgan-dollars/1885-cc-1-ms64-pcgs/a/000-00001.s',
        description:
          'A low-mintage Carson City Morgan with satiny white surfaces and a strong strike.',
      },
      {
        title: '1907 High Relief Saint-Gaudens $20 NGC AU-58',
        priceText: '$14,750.00',
        url: 'https://coins.ha.com/itm/saint-gaudens/1907-high-relief-20-au58-ngc/a/000-00002.s',
        description:
          'The celebrated 1907 High Relief Double Eagle — a sculptural masterpiece and a blue-chip rarity.',
      },
      {
        title: '1916 Standing Liberty Quarter PCGS VF-20',
        priceText: '$4,100.00',
        url: 'https://coins.ha.com/itm/standing-liberty/1916-25c-vf20-pcgs/a/000-00003.s',
        description: 'The key-date first-year Standing Liberty quarter, an important type rarity.',
      },
    ].map((r) => this.mapRow(r));
    return typeof limit === 'number' ? rows.slice(0, limit) : rows;
  }
}
