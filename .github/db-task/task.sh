#!/bin/bash
# Read-only diagnostic: pull full detail on the two duplicate pairs found
# (VIVA!/Viva and the two Jet's Pizza entries) including DM status/attempts,
# so a safe merge decision can be made. No writes.
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
  const keys = ['50465', '50867', '50217', '-P3D5D4f7Wf57WSyE_0i'];
  const [crecRaw, statusRaw, attemptsRaw] = await Promise.all([
    get(DB + '/dashboard_crec.json'),
    get(DB + '/dashboard/status.json'),
    get(DB + '/dashboard/attempts.json'),
  ]);
  const crec = JSON.parse(crecRaw) || {};
  const status = JSON.parse(statusRaw) || {};
  const attempts = JSON.parse(attemptsRaw) || {};

  for (const k of keys) {
    console.log('--- ' + k + ' ---');
    console.log('record: ' + JSON.stringify(crec[k]));
    console.log('status: ' + JSON.stringify(status[k]));
    console.log('attempts: ' + JSON.stringify(attempts[k]));
  }
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
NODE
