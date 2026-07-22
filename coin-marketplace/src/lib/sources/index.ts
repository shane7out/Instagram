import type { SourceAdapter } from './types';
import { HeritageAdapter } from './heritage';
import { MoneyMetalsAdapter } from './moneymetals';

/**
 * Source registry. Register a new dealer/auction site by adding its adapter to
 * this array — the importer picks it up automatically. Each adapter must
 * implement the SourceAdapter contract (see ./types).
 *
 * Adapters intentionally NOT bundled yet (stubs to add next): GreatCollections,
 * eBay Certified, APMEX, David Lawrence Rare Coins. Each is a single file that
 * extends BaseSourceAdapter — copy heritage.ts as a template.
 */
export const adapters: SourceAdapter[] = [
  new MoneyMetalsAdapter(),
  new HeritageAdapter(),
  // new GreatCollectionsAdapter(),
  // new EbayCertifiedAdapter(),
  // new ApmexAdapter(),
];

export function getAdapter(id: string): SourceAdapter | undefined {
  return adapters.find((a) => a.id === id);
}

export * from './types';
export { BaseSourceAdapter } from './base';
