#!/bin/bash
# Read-only diagnostic: pull full detail on the 3 records that have an
# igovr (IG override) entry sitting in Firebase, to see what the current
# stored instagram field is vs the override, before deciding whether to
# apply it. No writes.
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
  const nums = ['50204', '50258', '50385'];
  const [crecRaw, igovrRaw, statusRaw] = await Promise.all([
    get(DB + '/dashboard_crec.json'),
    get(DB + '/dashboard/igovr.json'),
    get(DB + '/dashboard/status.json'),
  ]);
  const crec = JSON.parse(crecRaw) || {};
  const igovr = JSON.parse(igovrRaw) || {};
  const status = JSON.parse(statusRaw) || {};

  for (const num of nums) {
    console.log('--- ' + num + ' ---');
    console.log('record: ' + JSON.stringify(crec[num]));
    console.log('igovr: ' + igovr[num]);
    console.log('status: ' + status[num]);
  }
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
NODE
