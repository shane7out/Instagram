#!/bin/bash
# Read-only dupe-check only (NOT adding yet): Penny's Waikiki Malasadas
# (@pennyswaikikimalasadas). Bio says "Open daily at Royal Hawaiian Center"
# (Honolulu, HI) and "LAS VEGAS -> SOON" - meaning the Vegas location
# hasn't opened yet. Flagging to the owner rather than assuming, same as
# the earlier Rollin' Sweets case.
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
  const raw = await get(DB + '/dashboard_crec.json');
  const existing = JSON.parse(raw) || {};
  const dupe = Object.values(existing).find(r => r && (/penn.?y.?s? waikiki malasadas/i.test(r.name || '') || (r.instagram || '').toLowerCase() === 'pennyswaikikimalasadas'));
  if (dupe) {
    console.log('ALREADY IN DATABASE: ' + JSON.stringify(dupe));
  } else {
    console.log('NOT in database yet - holding off per Vegas-location-not-open-yet flag, not adding this cycle.');
  }
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
NODE
