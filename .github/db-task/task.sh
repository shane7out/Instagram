#!/bin/bash
# Read-only diagnostic: follow-up check on the Deals site freshness
# countdown (last checked: 2.3 days left as of 2026-10-18 18:36 UTC). No writes.
set -e

node <<'NODE'
const https = require('https');

function get(url) {
  return new Promise((resolve, reject) => {
    https.get(url, r => { let d = ''; r.on('data', c => d += c); r.on('end', () => resolve({status: r.statusCode, body: d})); }).on('error', reject);
  });
}

(async () => {
  const r = await get('https://classiccarsforsale-co.web.app/cars.json');
  let arr;
  try { arr = JSON.parse(r.body); } catch(e) { console.log('PARSE FAIL: ' + e.message); return; }

  const now = Date.now();
  const THIRTY_DAYS = 30 * 24 * 3600 * 1000;
  let fresh = 0, stale = 0;
  let newestAdded = null;

  for (const e of arr) {
    const ts = e.addedTs || e.postedTs;
    if (!ts) continue;
    const t = new Date(ts).getTime();
    if (isNaN(t)) continue;
    if (newestAdded === null || t > newestAdded) newestAdded = t;
    if (now - t <= THIRTY_DAYS) fresh++; else stale++;
  }

  console.log('total entries: ' + arr.length);
  console.log('fresh (<=30 days old): ' + fresh);
  console.log('stale (>30 days old): ' + stale);
  console.log('newest entry added: ' + (newestAdded ? new Date(newestAdded).toISOString() : 'n/a'));
  if (newestAdded) {
    const daysUntilStale = 30 - (now - newestAdded) / (24*3600*1000);
    console.log('days until the newest batch itself goes stale: ' + daysUntilStale.toFixed(2));
  }
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
NODE
