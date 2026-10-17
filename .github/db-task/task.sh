#!/bin/bash
# Read-only diagnostic: an old session's deals-diagnosis.txt (from Sep 20)
# found that 0 of 669 cars.json entries would survive the 30-day
# freshness rule - meaning the Deals site's grid may already be close to
# empty, given the pipeline has been blocked on FIREBASE_DEALS_SA since
# before this session started. Re-check live, current state to see how
# much worse it's gotten and give a concrete number for why the secret
# fix matters. No writes.
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
  console.log('cars.json http: ' + r.status + '  bytes: ' + r.body.length);
  let arr;
  try { arr = JSON.parse(r.body); } catch(e) { console.log('PARSE FAIL: ' + e.message); return; }
  console.log('total entries: ' + arr.length);

  const now = Date.now();
  const THIRTY_DAYS = 30 * 24 * 3600 * 1000;
  let fresh = 0, stale = 0, noDate = 0;
  let newestAdded = null, oldestAdded = null;

  for (const e of arr) {
    const ts = e.addedTs || e.postedTs;
    if (!ts) { noDate++; continue; }
    const t = new Date(ts).getTime();
    if (isNaN(t)) { noDate++; continue; }
    if (newestAdded === null || t > newestAdded) newestAdded = t;
    if (oldestAdded === null || t < oldestAdded) oldestAdded = t;
    if (now - t <= THIRTY_DAYS) fresh++; else stale++;
  }

  console.log('fresh (<=30 days old): ' + fresh);
  console.log('stale (>30 days old): ' + stale);
  console.log('no parseable date: ' + noDate);
  console.log('newest entry added: ' + (newestAdded ? new Date(newestAdded).toISOString() : 'n/a') + '  (' + (newestAdded ? Math.round((now-newestAdded)/3600000) + ' hours ago' : '') + ')');
  console.log('oldest entry added: ' + (oldestAdded ? new Date(oldestAdded).toISOString() : 'n/a'));
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
NODE
