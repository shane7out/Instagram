#!/bin/bash
# verify: 2026-10-09T20:42:27Z
# Final verification pass: reassemble the latest manual.json export (plain
# base64, no gzip - see deals-export-manual-json.sh for why), verify every
# chunk's hash + the full payload hash, confirm entry count, and seed it as
# the persistent CI-state baseline for the pipeline.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
mkdir -p .github/db-task/fetched

node <<'NODE'
const https = require('https'), fs = require('fs'), crypto = require('crypto');
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
function sha(s) { return crypto.createHash('sha256').update(s).digest('hex'); }

(async () => {
  const runId = JSON.parse(await get(DB + '/_debug/deals_manual_json_latest.json'));
  console.log('latest runId: ' + runId);
  const meta = JSON.parse(await get(DB + '/_debug/deals_manual_json/' + runId + '/meta.json'));
  console.log('meta: count=' + meta.count + ' rawBytes=' + meta.rawBytes + ' b64Bytes=' + meta.b64Bytes);

  let b64 = '';
  let anyBad = false;
  for (let i = 0; i < meta.count; i++) {
    const chunk = JSON.parse(await get(DB + '/_debug/deals_manual_json/' + runId + '/chunks/' + i + '.json'));
    const h = sha(chunk);
    const ok = h === meta.chunkHashes[i];
    if (!ok) anyBad = true;
    console.log('chunk ' + i + ': len=' + chunk.length + ' hashOK=' + ok);
    b64 += chunk;
  }
  if (anyBad) { console.log('ABORT: chunk hash mismatch'); process.exit(1); }
  const fullOk = sha(b64) === meta.fullHash;
  console.log('full hash match: ' + fullOk);
  if (!fullOk) { console.log('ABORT: full hash mismatch'); process.exit(1); }

  // NOTE: compare BYTE length, not JS string .length (UTF-16 code units) - that mismatch
  // (not gzip, not transit, not corruption) was the entire cause of every earlier "ABORT:
  // size mismatch" here. manual.json has multi-byte UTF-8 chars (accents, em-dashes, etc.)
  // in listing text, so decoded.length (code units) undercounts vs the Mac's byte count.
  const rawBuf = Buffer.from(b64, 'base64');
  const raw = rawBuf.toString('utf8');
  console.log('decoded raw: ' + rawBuf.length + ' bytes (expected ' + meta.rawBytes + '), string .length=' + raw.length);
  if (rawBuf.length !== meta.rawBytes) { console.log('ABORT: size mismatch'); process.exit(1); }

  const arr = JSON.parse(raw);
  console.log('SUCCESS: manual.json is an array of ' + arr.length + ' entries');
  const byType = {};
  arr.forEach(c => { const t = c.type || '(car/untyped)'; byType[t] = (byType[t] || 0) + 1; });
  console.log('breakdown by type: ' + JSON.stringify(byType));
  console.log('sample entry keys: ' + Object.keys(arr[0] || {}).join(', '));

  // Seed persistent CI-state baseline (stable path) for the future pipeline.
  for (let i = 0; i < meta.count; i++) {
    const chunk = b64.slice(i * meta.chunkSize, (i + 1) * meta.chunkSize);
    const r = await put(DB + '/_deals_ci_state/manual_json/chunks/' + i + '.json', chunk);
    console.log('seeded state chunk ' + i + ': ' + r.status);
  }
  const r2 = await put(DB + '/_deals_ci_state/manual_json/meta.json', meta);
  console.log('seeded state meta: ' + r2.status);

  const summary = {
    rawBytes: meta.rawBytes, entryCount: arr.length, byType,
    sampleKeys: Object.keys(arr[0] || {}), sampleEntry: arr[0],
    verifiedHashOK: true, seededAt: new Date().toISOString(),
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
  git commit -m "fetch: manual.json verified end-to-end (no-gzip), CI-state baseline seeded"
  git push origin HEAD:claude/master-file-e6ofy0
  echo "pushed"
fi
