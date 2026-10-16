#!/bin/bash
# Dedup fix: remove two confirmed duplicate records, keeping the version with
# the real Instagram handle / proper key. Both duplicates are untouched
# (status: pending, no DM attempts) so nothing is lost.
#   - "Viva" (num 50867, no instagram, "Yelp migration" stub) duplicates
#     "VIVA!" (num 50465, @eatdrinkviva) -> delete 50867.
#   - The push-ID-keyed "Jet's Pizza" record (@jetspizza, num 60011 stored
#     under a malformed non-numeric key) duplicates "Jet' Detroit Sytle
#     Pizza" (num 50217, @jetspizza) -> delete the malformed push-ID record.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

node <<'NODE'
const https = require('https');
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';

function del(url) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const req = https.request(u, { method: 'DELETE' }, r => {
      let d = ''; r.on('data', c => d += c); r.on('end', () => resolve({ status: r.statusCode, body: d }));
    });
    req.on('error', reject); req.end();
  });
}

(async () => {
  const r1 = await del(DB + '/dashboard_crec/50867.json');
  console.log('delete dashboard_crec/50867 (duplicate "Viva"): ' + r1.status);
  const r2 = await del(DB + '/dashboard/status/50867.json');
  console.log('delete dashboard/status/50867: ' + r2.status);
  const r3 = await del(DB + '/dashboard/attempts/50867.json');
  console.log('delete dashboard/attempts/50867: ' + r3.status);

  const key2 = '-P3D5D4f7Wf57WSyE_0i';
  const r4 = await del(DB + '/dashboard_crec/' + key2 + '.json');
  console.log('delete dashboard_crec/' + key2 + ' (duplicate "Jet\'s Pizza", malformed key): ' + r4.status);
  const r5 = await del(DB + '/dashboard/status/' + key2 + '.json');
  console.log('delete dashboard/status/' + key2 + ': ' + r5.status);
  const r6 = await del(DB + '/dashboard/attempts/' + key2 + '.json');
  console.log('delete dashboard/attempts/' + key2 + ': ' + r6.status);

  console.log('DONE: removed 2 duplicate records (Viva, Jet\'s Pizza push-ID dup)');
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
NODE
