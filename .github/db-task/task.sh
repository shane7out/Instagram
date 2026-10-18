#!/bin/bash
# Read-only diagnostic: haven't checked the /dashboard/problem path yet
# (one of the dashboard's known features - a "Problem" badge/filter).
# See if it holds any flagged records worth knowing about, same pattern
# as the badig/igsuggest investigation. No writes.
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
  const [problemRaw, crecRaw] = await Promise.all([
    get(DB + '/dashboard/problem.json'),
    get(DB + '/dashboard_crec.json'),
  ]);
  const problem = JSON.parse(problemRaw) || {};
  const crec = JSON.parse(crecRaw) || {};

  const keys = Object.keys(problem);
  console.log('problem-flagged entries: ' + keys.length);
  for (const k of keys) {
    const r = crec[k];
    console.log('  ' + k + ': ' + (r ? r.name + ' (' + (r.instagram||'no handle') + ')' : '(no matching crec record)') + '  value=' + JSON.stringify(problem[k]));
  }
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
NODE
