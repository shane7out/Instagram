#!/bin/bash
# Read-only diagnostic: check /dashboard/interested - restaurants marked
# as having responded positively. If any have been sitting without a
# next step, that's a real "don't let a hot lead go cold" list worth
# surfacing. No writes.
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
  const [interestedRaw, crecRaw, foodtradeRaw, foodtradedoneRaw] = await Promise.all([
    get(DB + '/dashboard/interested.json'),
    get(DB + '/dashboard_crec.json'),
    get(DB + '/dashboard/foodtrade.json'),
    get(DB + '/dashboard/foodtradedone.json'),
  ]);
  const interested = JSON.parse(interestedRaw) || {};
  const crec = JSON.parse(crecRaw) || {};
  const foodtrade = JSON.parse(foodtradeRaw) || {};
  const foodtradedone = JSON.parse(foodtradedoneRaw) || {};

  const keys = Object.keys(interested);
  console.log('interested-flagged entries: ' + keys.length);
  for (const k of keys) {
    const r = crec[k];
    console.log('  ' + k + ': ' + (r ? r.name + ' (' + (r.instagram||'no handle') + ')' : '(no matching crec record)'));
  }

  console.log('foodtrade-flagged (in progress): ' + Object.keys(foodtrade).length);
  console.log('foodtradedone (completed): ' + Object.keys(foodtradedone).length);
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
NODE
