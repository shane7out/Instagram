#!/bin/bash
# Read-only diagnostic: pull full detail on the 7 "sent" (already DM'd)
# records - names + any DM timestamp data - to see how many would already
# qualify for the not-yet-deployed "Needs Follow-Up" feature once it ships.
# No writes.
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
  const [crecRaw, statusRaw, dashRaw] = await Promise.all([
    get(DB + '/dashboard_crec.json'),
    get(DB + '/dashboard/status.json'),
    get(DB + '/dashboard.json?shallow=true'),
  ]);
  const crec = JSON.parse(crecRaw) || {};
  const status = JSON.parse(statusRaw) || {};
  const dashKeys = JSON.parse(dashRaw) || {};

  console.log('--- top-level keys under /dashboard ---');
  console.log(JSON.stringify(Object.keys(dashKeys)));

  const sentNums = Object.keys(status).filter(k => status[k] === 'sent');
  console.log('--- sent records (' + sentNums.length + ') ---');
  for (const num of sentNums) {
    const r = crec[num];
    console.log(num + ': ' + (r ? r.name : '(no crec record found)'));
  }
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
NODE
