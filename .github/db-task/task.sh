#!/bin/bash
# Read-only diagnostic: re-check /dashboard/badig live against current
# dashboard_crec. An old file in this repo (dupes-and-badig.txt, from an
# earlier session) shows badig DOES correlate to real LVR records (237
# flagged, names match exactly) - unlike igovr, which had at least one
# clearly wrong entry. Need live numbers before correcting the status doc.
# Also list badig-flagged records that DO have a handle on file (meaning
# the handle itself is suspect, e.g. a typo) vs ones with no handle at all
# (already known from the earlier no-handle scan).
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

(async () => {
  const [crecRaw, badigRaw] = await Promise.all([
    get(DB + '/dashboard_crec.json'),
    get(DB + '/dashboard/badig.json'),
  ]);
  const crec = JSON.parse(crecRaw) || {};
  const badig = JSON.parse(badigRaw) || {};

  const badigNums = Object.keys(badig);
  console.log('total badig-flagged entries: ' + badigNums.length);

  let liveWithHandle = [];
  let liveNoHandle = 0;
  let notInCrec = 0;

  for (const num of badigNums) {
    const r = crec[num];
    if (!r) { notInCrec++; continue; }
    const ig = (r.instagram || '').trim();
    if (ig) liveWithHandle.push({ num, name: r.name, ig });
    else liveNoHandle++;
  }

  console.log('not in dashboard_crec (deleted/gone): ' + notInCrec);
  console.log('live, no handle at all (already in needs-ig-handle.md): ' + liveNoHandle);
  console.log('live, HAS a handle but flagged bad (likely typo/wrong - NEW list): ' + liveWithHandle.length);
  liveWithHandle.slice(0, 60).forEach(x => console.log('  ' + x.num + ': ' + x.name + '  ' + x.ig));
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
NODE
