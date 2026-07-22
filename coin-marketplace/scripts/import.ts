/**
 * Import CLI.
 *
 * Pulls listings from the registered source adapters, applies the markup
 * engine, and prints a marketplace-ready catalog plus an internal margin
 * report. By default it runs in dry-run mode (fixtures, no network) so you can
 * see the whole pipeline work immediately:
 *
 *   npm run import                      # all sources, fixtures
 *   npm run import -- --source=heritage # one source
 *   npm run import -- --live            # hit the network (needs live adapters)
 *   npm run import -- --limit=50 --out=src/data/imported.json
 *
 * In production you'd point --out at the file the catalog reads from, and run
 * this on a schedule (cron / GitHub Action) to keep inventory fresh.
 */
import { writeFileSync } from 'node:fs';
import { runImport } from '../src/lib/sources/importer';
import { formatUsd } from '../src/lib/pricing';

function arg(name: string): string | undefined {
  const hit = process.argv.find((a) => a.startsWith(`--${name}=`));
  return hit?.split('=')[1];
}
function flag(name: string): boolean {
  return process.argv.includes(`--${name}`);
}

async function main() {
  const sources = arg('source')?.split(',');
  const limit = arg('limit') ? Number(arg('limit')) : undefined;
  const live = flag('live');
  const out = arg('out');

  console.log(`\n▶ Importing coins  (${live ? 'LIVE network' : 'dry-run / fixtures'})`);
  if (sources) console.log(`  sources: ${sources.join(', ')}`);

  const { coins, report } = await runImport({ sources, limit, dryRun: !live });

  console.log('\n── Import report ─────────────────────────────');
  for (const [id, s] of Object.entries(report.bySource)) {
    console.log(`  ${id.padEnd(18)} fetched ${s.fetched}  imported ${s.imported}`);
  }
  console.log(`  duplicates dropped: ${report.duplicatesDropped}`);
  console.log(`  coins in catalog:   ${report.totalImported}`);
  console.log(`  source value:       ${formatUsd(report.totalSourceValue)}`);
  console.log(`  list value:         ${formatUsd(report.totalListValue)}`);
  console.log(`  projected margin:   ${formatUsd(report.projectedGrossMargin)}`);

  console.log('\n── Sample marked-up listings ─────────────────');
  for (const c of coins.slice(0, 8)) {
    console.log(
      `  ${c.title}\n    source ${formatUsd(c.sourcePrice)}  →  list ${formatUsd(
        c.price,
      )}  (via ${c.source.name})`,
    );
  }

  if (out) {
    writeFileSync(out, JSON.stringify(coins, null, 2));
    console.log(`\n✔ Wrote ${coins.length} coins to ${out}`);
  }
  console.log('');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
