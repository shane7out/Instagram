#!/bin/bash
# Read-only diagnostic: the dashboard schema has "igsuggest" and "igovr"
# paths under /dashboard that I haven't inspected yet - check if either
# already holds data for any of the 109 no-handle records found earlier.
# If so, that could solve part of the handle backlog without any guessing.
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
  const [igsuggestRaw, igovrRaw, badigRaw] = await Promise.all([
    get(DB + '/dashboard/igsuggest.json'),
    get(DB + '/dashboard/igovr.json'),
    get(DB + '/dashboard/badig.json'),
  ]);
  const igsuggest = JSON.parse(igsuggestRaw);
  const igovr = JSON.parse(igovrRaw);
  const badig = JSON.parse(badigRaw);

  console.log('igsuggest: ' + (igsuggest ? JSON.stringify(igsuggest).slice(0, 2000) : 'null/empty'));
  console.log('igovr: ' + (igovr ? JSON.stringify(igovr).slice(0, 2000) : 'null/empty'));
  console.log('badig count: ' + (badig ? Object.keys(badig).length : 0));
  if (badig) console.log('badig sample: ' + JSON.stringify(Object.entries(badig).slice(0, 10)));
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
NODE
