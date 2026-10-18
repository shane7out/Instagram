#!/bin/bash
# Read-only diagnostic: found 7 live restaurants flagged "problem" in
# /dashboard/problem. Check /dashboard/usernotes for the same nums to see
# if there's an explanation of what the problem actually is, before
# deciding whether this is worth surfacing to the owner. No writes.
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
  const [usernotesRaw, crecRaw] = await Promise.all([
    get(DB + '/dashboard/usernotes.json'),
    get(DB + '/dashboard_crec.json'),
  ]);
  const usernotes = JSON.parse(usernotesRaw) || {};
  const crec = JSON.parse(crecRaw) || {};

  const nums = ['50324', '50413', '50416', '50439', '50454', '50479', '50501'];
  for (const n of nums) {
    const r = crec[n];
    console.log(n + ' (' + (r ? r.name : '?') + '): usernotes=' + JSON.stringify(usernotes[n]) + '  record_notes=' + JSON.stringify(r ? r.notes : undefined));
  }
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
NODE
