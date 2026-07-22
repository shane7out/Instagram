import type { SourceAdapter, NormalizedListing, FetchOptions } from './types';

/**
 * Shared helpers for building source adapters: a small fetch wrapper with a
 * realistic User-Agent and timeout, plus parsers for the messy free-text fields
 * (grade strings, metals, years) that every coin site formats differently.
 *
 * Real adapters extend `BaseSourceAdapter` and implement `fetchListings`. The
 * parsing helpers below are deliberately conservative — they return null rather
 * than guess, and the importer's enricher fills remaining gaps.
 */
export abstract class BaseSourceAdapter implements SourceAdapter {
  abstract readonly id: string;
  abstract readonly name: string;
  abstract readonly baseUrl: string;

  abstract fetchListings(opts?: FetchOptions): Promise<NormalizedListing[]>;

  /** Polite fetch with timeout + a browser-like UA. */
  protected async httpGet(url: string, opts: { timeoutMs?: number } = {}): Promise<string> {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), opts.timeoutMs ?? 15_000);
    try {
      const res = await fetch(url, {
        signal: controller.signal,
        headers: {
          'User-Agent':
            'ChristensenCoinsBot/1.0 (+https://christensencoins.com/bot; aggregator)',
          Accept: 'text/html,application/xhtml+xml,application/json',
        },
      });
      if (!res.ok) throw new Error(`${this.id}: HTTP ${res.status} for ${url}`);
      return await res.text();
    } finally {
      clearTimeout(timeout);
    }
  }

  // ---- Parsing helpers (shared across adapters) ----

  /** Extract a 4-digit coinage year (1600–2099) from a title. */
  static parseYear(text: string): number | null {
    const m = text.match(/\b(1[6-9]\d{2}|20\d{2})\b/);
    return m ? Number(m[1]) : null;
  }

  /** Parse a mintmark from a title, e.g. "1889-CC" -> "CC". */
  static parseMintMark(text: string): string | null {
    const m = text.match(/\b\d{4}[-\s]([A-Z]{1,2})\b/);
    if (m) return m[1];
    const m2 = text.match(/\b(CC|[A-Z])\s*(?:mint\b)/i);
    return m2 ? m2[1].toUpperCase() : null;
  }

  /** Parse grade + service, e.g. "PCGS MS-65", "NGC PR69 DCAM". */
  static parseGrade(text: string): {
    service: NormalizedListing['gradingService'];
    grade: string | null;
    numeric: number | null;
  } {
    const svcMatch = text.match(/\b(PCGS|NGC|ANACS|ICG)\b/i);
    const service = (svcMatch?.[1]?.toUpperCase() as NormalizedListing['gradingService']) ?? 'Raw';
    const gradeMatch = text.match(/\b(MS|PR|PF|AU|XF|EF|VF|VG|AG|G|F)[-\s]?(\d{1,2})\b/i);
    if (!gradeMatch) return { service, grade: null, numeric: null };
    const prefix = gradeMatch[1].toUpperCase();
    const numeric = Number(gradeMatch[2]);
    return { service, grade: `${prefix}-${numeric}`, numeric };
  }

  /** Best-guess metal from the coin title / description. */
  static parseMetal(text: string): NormalizedListing['metal'] | undefined {
    const t = text.toLowerCase();
    if (/\bgold\b|\bAGW\b|eagle|sovereign|ducat|aureus|solidus/i.test(text)) return 'Gold';
    if (/\bsilver\b|denarius|tetradrachm|reales|dollar|dime|quarter|half/.test(t)) return 'Silver';
    if (/\bplatinum\b/.test(t)) return 'Platinum';
    if (/\bnickel\b/.test(t)) return 'Nickel';
    if (/\bbronze\b|follis|sestertius|as\b/.test(t)) return 'Bronze';
    if (/\bcent\b|penny|copper/.test(t)) return 'Copper';
    return undefined;
  }

  /** Parse a USD price from strings like "$5,850.00" or "USD 165". */
  static parsePrice(text: string): number | null {
    const m = text.replace(/,/g, '').match(/(\d+(?:\.\d{1,2})?)/);
    return m ? Number(m[1]) : null;
  }

  /** Turn a title into a URL slug. */
  static slugify(text: string): string {
    return text
      .toLowerCase()
      .replace(/\$/g, '')
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '')
      .slice(0, 90);
  }
}
