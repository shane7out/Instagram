#!/bin/bash
# Read-only diagnostic: re-check badig-flagged records live, since several
# restaurants have been added since the last pass (Resort at Summerlin,
# Sourdough & Co, Rangoli Social Eats, Frank's Pizza, Pasta Vine) and a
# past verification effort (igsuggest) was ongoing - check for any new
# flagged-with-handle entries beyond the ones already fixed/known. No writes.
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
  const [crecRaw, badigRaw] = await Promise.all([
    get(DB + '/dashboard_crec.json'),
    get(DB + '/dashboard/badig.json'),
  ]);
  const crec = JSON.parse(crecRaw) || {};
  const badig = JSON.parse(badigRaw) || {};

  const badigNums = Object.keys(badig);
  console.log('total badig-flagged entries: ' + badigNums.length);

  // already-known/handled nums from the earlier pass
  const known = new Set(['50125','50204','50206','50221','50278','50315','50345','50360','50395','50608','50611','50745','50818','50882','60029','60037']);

  let newOnes = [];
  for (const num of badigNums) {
    const r = crec[num];
    if (!r) continue;
    const ig = (r.instagram || '').trim();
    if (ig && !known.has(num)) newOnes.push({ num, name: r.name, ig });
  }
  console.log('NEW badig-flagged-with-handle entries not seen before: ' + newOnes.length);
  newOnes.forEach(x => console.log('  ' + x.num + ': ' + x.name + '  ' + x.ig));
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
NODE
