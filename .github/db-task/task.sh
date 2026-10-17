#!/bin/bash
# Read-only diagnostic: re-run the duplicate-handle/name scan (last run
# 2026-10-16) to make sure none of the 4 restaurants added since then
# (Resort at Summerlin, Sourdough & Co, Rangoli Social Eats, Frank's
# Pizza) accidentally duplicate an existing record. No writes.
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

function norm(s) {
  return (s || '').toLowerCase().replace(/[^a-z0-9]/g, '');
}

(async () => {
  const raw = await get(DB + '/dashboard_crec.json');
  const recs = JSON.parse(raw) || {};
  const byIg = {};
  const byName = {};
  for (const [num, r] of Object.entries(recs)) {
    if (!r) continue;
    const ig = (r.instagram || '').toLowerCase().replace(/^@/, '').trim();
    if (ig) (byIg[ig] = byIg[ig] || []).push({ num, name: r.name });
    const nm = norm(r.name);
    if (nm) (byName[nm] = byName[nm] || []).push({ num, name: r.name, instagram: r.instagram });
  }

  console.log('--- duplicate instagram handles ---');
  let foundIg = 0;
  for (const [ig, list] of Object.entries(byIg)) {
    if (list.length > 1) { foundIg++; console.log(ig + ': ' + JSON.stringify(list)); }
  }
  if (!foundIg) console.log('none found');

  console.log('--- duplicate/near-duplicate names ---');
  let foundNm = 0;
  for (const [nm, list] of Object.entries(byName)) {
    if (list.length > 1) { foundNm++; console.log(nm + ': ' + JSON.stringify(list)); }
  }
  if (!foundNm) console.log('none found');

  console.log('total records scanned: ' + Object.keys(recs).length);
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
NODE
