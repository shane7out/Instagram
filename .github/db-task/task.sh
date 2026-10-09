#!/bin/bash
# Reassemble the manual.json export (3 gzip+base64 chunks) from Firebase diag,
# decode it, sanity-check its structure, seed it into a persistent CI-state
# location in Firebase (so the future GH-Actions pipeline has a starting
# point), and write a small summary (NOT the full 3.4MB) into the repo.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
mkdir -p .github/db-task/fetched

node <<'NODE'
const https = require('https'), fs = require('fs'), zlib = require('zlib');
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';

function get(url) {
  return new Promise((resolve, reject) => {
    https.get(url, r => { let d = ''; r.on('data', c => d += c); r.on('end', () => resolve(d)); }).on('error', reject);
  });
}
function put(url, body) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const u = new URL(url);
    const req = https.request(u, { method: 'PUT', headers: { 'Content-Type': 'application/json' } }, r => {
      let d = ''; r.on('data', c => d += c); r.on('end', () => resolve({ status: r.statusCode, body: d }));
    });
    req.on('error', reject); req.write(data); req.end();
  });
}

(async () => {
  const meta = JSON.parse(await get(DB + '/_debug/deals_manual_json/meta.json'));
  console.log('meta: ' + JSON.stringify(meta));
  let b64 = '';
  for (let i = 0; i < meta.count; i++) {
    const chunk = JSON.parse(await get(DB + '/_debug/deals_manual_json/chunks/' + i + '.json'));
    b64 += chunk;
    console.log('chunk ' + i + ' fetched: ' + chunk.length + ' chars');
  }
  if (b64.length !== meta.gzB64Bytes) { console.log('SIZE MISMATCH: got ' + b64.length + ' expected ' + meta.gzB64Bytes); process.exit(1); }
  const gz = Buffer.from(b64, 'base64');
  const raw = zlib.gunzipSync(gz).toString('utf8');
  if (raw.length !== meta.rawBytes) { console.log('RAW SIZE MISMATCH: got ' + raw.length + ' expected ' + meta.rawBytes); process.exit(1); }
  console.log('decoded OK: ' + raw.length + ' bytes, matches expected');

  const arr = JSON.parse(raw);
  console.log('manual.json is an array of ' + arr.length + ' entries');
  const byType = {};
  arr.forEach(c => { const t = c.type || '(car/untyped)'; byType[t] = (byType[t] || 0) + 1; });
  console.log('breakdown by type: ' + JSON.stringify(byType));
  const sample = arr[0];
  const sampleKeys = sample ? Object.keys(sample) : [];
  console.log('sample entry keys: ' + sampleKeys.join(', '));

  // Seed this as the persistent CI-state baseline for the future pipeline.
  // Re-upload the SAME gzip+base64 chunks under a stable state path (not _debug,
  // which is scratch/diag). The CI workflow will read from here each run and
  // write the updated manual.json back here after harvesting.
  for (let i = 0; i < meta.count; i++) {
    const chunk = b64.slice(i * 300000, (i + 1) * 300000);
    const r = await put(DB + '/_deals_ci_state/manual_json/chunks/' + i + '.json', chunk);
    console.log('seeded state chunk ' + i + ': ' + r.status);
  }
  const r2 = await put(DB + '/_deals_ci_state/manual_json/meta.json', meta);
  console.log('seeded state meta: ' + r2.status);

  // Write a small summary (not the full data) into the repo for reference.
  const summary = {
    rawBytes: meta.rawBytes,
    entryCount: arr.length,
    byType,
    sampleKeys,
    sampleEntry: sample,
    seededAt: new Date().toISOString(),
  };
  fs.writeFileSync('.github/db-task/fetched/manual-json-summary.json', JSON.stringify(summary, null, 2));
  console.log('summary written to repo');
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
NODE

git config user.name "db-task-bot"
git config user.email "db-task-bot@users.noreply.github.com"
git add .github/db-task/fetched/manual-json-summary.json
if git diff --cached --quiet; then
  echo "nothing new to commit"
else
  git commit -m "fetch: manual.json structure summary + seed CI-state baseline"
  git push origin HEAD:claude/master-file-e6ofy0
  echo "pushed"
fi
