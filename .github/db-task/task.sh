#!/bin/bash
# Read-only diagnostic: size the email outreach channel (dashboard has a
# separate "Sent"/"Waiting" email badge pair alongside the IG DM ones) -
# how many records have an email on file that's never been used, and
# sanity-check that yesterday's dedup deletes (Viva/Jet's Pizza) left no
# orphaned references anywhere else. No writes.
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
  const [crecRaw, custRaw] = await Promise.all([
    get(DB + '/dashboard_crec.json'),
    get(DB + '/customrecords.json'),
  ]);
  const crec = JSON.parse(crecRaw) || {};
  const cust = JSON.parse(custRaw) || {};

  let hasEmail = 0, noEmail = 0;
  for (const r of Object.values(crec)) {
    if (!r) continue;
    if ((r.email || '').trim()) hasEmail++; else noEmail++;
  }
  console.log('--- email field coverage (dashboard_crec) ---');
  console.log('has email on file: ' + hasEmail);
  console.log('no email on file: ' + noEmail);

  console.log('--- orphan check for yesterday\'s dedup deletes ---');
  const deadKeys = ['50867', '-P3D5D4f7Wf57WSyE_0i'];
  for (const k of deadKeys) {
    console.log(k + ' still in dashboard_crec: ' + (crec[k] !== undefined));
    console.log(k + ' still in customrecords: ' + (cust[k] !== undefined));
  }
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
NODE
