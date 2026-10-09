#!/bin/bash
# Reassemble the manual.json export (gzip+base64 chunks) from Firebase diag,
# verifying each chunk's sha256 against what the Mac actually computed before
# upload (the earlier attempt silently lost ~10KB somewhere in transit with no
# error - this pins down exactly which chunk, if any, is bad).
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
mkdir -p .github/db-task/fetched

node <<'NODE'
const https = require('https'), fs = require('fs'), zlib = require('zlib'), crypto = require('crypto');
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
  console.log('meta: count=' + meta.count + ' rawBytes=' + meta.rawBytes + ' gzB64Bytes=' + meta.gzB64Bytes + ' chunkSize=' + meta.chunkSize);

  let b64 = '';
  let anyBad = false;
  for (let i = 0; i < meta.count; i++) {
    const chunk = JSON.parse(await get(DB + '/_debug/deals_manual_json/' + runId + '/chunks/' + i + '.json'));
    const h = sha(chunk);
    const ok = h === meta.chunkHashes[i];
    if (!ok) anyBad = true;
    console.log('chunk ' + i + ': len=' + chunk.length + ' hashOK=' + ok + (ok ? '' : (' expected=' + meta.chunkHashes[i].slice(0,12) + ' got=' + h.slice(0,12))));
    b64 += chunk;
  }
  if (anyBad) { console.log('ABORT: one or more chunks failed hash verification - re-export needed'); process.exit(1); }

  const fullHashCheck = sha(b64);
  console.log('full b64 hash match: ' + (fullHashCheck === meta.fullHash));
  if (fullHashCheck !== meta.fullHash) { console.log('ABORT: reassembled b64 does not match full hash'); process.exit(1); }

  const gz = Buffer.from(b64, 'base64');
  const raw = zlib.gunzipSync(gz).toString('utf8');
  console.log('decoded raw: ' + raw.length + ' bytes (expected ' + meta.rawBytes + ')');
  if (raw.length !== meta.rawBytes) { console.log('ABORT: raw size mismatch after verified-good chunks (unexpected)'); process.exit(1); }

  const arr = JSON.parse(raw);
  console.log('manual.json is an array of ' + arr.length + ' entries');
  const byType = {};
  arr.forEach(c => { const t = c.type || '(car/untyped)'; byType[t] = (byType[t] || 0) + 1; });
  console.log('breakdown by type: ' + JSON.stringify(byType));
  const sample = arr[0];
  console.log('sample entry keys: ' + Object.keys(sample || {}).join(', '));

  // Seed persistent CI-state baseline (stable path, not _debug/scratch) for the future pipeline.
  for (let i = 0; i < meta.count; i++) {
    const chunk = b64.slice(i * meta.chunkSize, (i + 1) * meta.chunkSize);
    const r = await put(DB + '/_deals_ci_state/manual_json/chunks/' + i + '.json', chunk);
    console.log('seeded state chunk ' + i + ': ' + r.status);
  }
  const r2 = await put(DB + '/_deals_ci_state/manual_json/meta.json', meta);
  console.log('seeded state meta: ' + r2.status);

  const summary = {
    rawBytes: meta.rawBytes, entryCount: arr.length, byType,
    sampleKeys: Object.keys(sample || {}), sampleEntry: sample,
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
  git commit -m "fetch: manual.json structure summary + seed CI-state baseline (verified)"
  git push origin HEAD:claude/master-file-e6ofy0
  echo "pushed"
fi
