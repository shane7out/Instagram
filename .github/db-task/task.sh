#!/bin/bash
# Cleanup: remove 6 orphaned dashboard/status + dashboard/attempts entries
# (nums 4, 5, 15, 72, 766, 60006) that point to no dashboard_crec record at
# all - stale leftovers from old/deleted data, confirmed via a read-only
# scan this cycle. Harmless either way (the dashboard iterates by
# dashboard_crec, not by status, so these were never shown), just hygiene.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

node <<'NODE'
const https = require('https');
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';

function get(url) {
  return new Promise((resolve, reject) => {
    https.get(url, r => { let d = ''; r.on('data', c => d += c); r.on('end', () => resolve(d)); }).on('error', reject);
  });
}
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
  // re-verify right before deleting, in case anything changed since the scan
  const crecRaw = await get(DB + '/dashboard_crec.json?shallow=true');
  const crec = JSON.parse(crecRaw) || {};
  const orphans = ['4', '5', '15', '72', '766', '60006'];
  for (const num of orphans) {
    if (crec[num] !== undefined) {
      console.log(num + ': NOW HAS a crec record - skipping delete, re-check needed');
      continue;
    }
    const r1 = await del(DB + '/dashboard/status/' + num + '.json');
    console.log('delete dashboard/status/' + num + ': ' + r1.status);
    const r2 = await del(DB + '/dashboard/attempts/' + num + '.json');
    console.log('delete dashboard/attempts/' + num + ': ' + r2.status);
  }
  console.log('DONE: cleaned up orphaned sent-status entries');
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
NODE
