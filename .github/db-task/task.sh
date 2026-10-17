#!/bin/bash
# Read-only diagnostic: pull the FULL igsuggest dataset (25 entries) plus
# full dashboard_crec, and do thorough matching: (1) confirmations - entry
# key IS a crec num and the suggested handle matches what's already
# stored (flag is stale, no action needed), (2) corrections - entry key IS
# a crec num but the suggested handle DIFFERS from what's stored (real fix
# candidate), (3) entries whose key is NOT a crec num at all (can't be
# matched this way - note separately). No writes, just full visibility
# before deciding anything.
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
  const [igsuggestRaw, crecRaw] = await Promise.all([
    get(DB + '/dashboard/igsuggest.json'),
    get(DB + '/dashboard_crec.json'),
  ]);
  const igsuggest = JSON.parse(igsuggestRaw) || {};
  const crec = JSON.parse(crecRaw) || {};

  const keys = Object.keys(igsuggest);
  console.log('igsuggest total entries: ' + keys.length);

  let confirmed = [], corrections = [], noCrecMatch = [];

  for (const key of keys) {
    const entry = igsuggest[key];
    const r = crec[key];
    if (!r) { noCrecMatch.push({ key, entry }); continue; }
    const curIg = (r.instagram || '').toLowerCase().replace(/^@/, '');
    const sugIg = (entry.ig || '').toLowerCase().replace(/^@/, '');
    if (curIg === sugIg) {
      confirmed.push({ key, name: r.name, ig: r.instagram, conf: entry.conf, note: entry.note });
    } else {
      corrections.push({ key, name: r.name, currentIg: r.instagram, suggestedIg: entry.ig, conf: entry.conf, note: entry.note });
    }
  }

  console.log('=== CONFIRMED (key IS a crec num, suggested handle MATCHES current - flag is stale) === ' + confirmed.length);
  confirmed.forEach(c => console.log('  ' + c.key + ': ' + c.name + ' ' + c.ig + ' [' + c.conf + ']'));

  console.log('=== CORRECTIONS (key IS a crec num, suggested handle DIFFERS from current) === ' + corrections.length);
  corrections.forEach(c => console.log('  ' + c.key + ': ' + c.name + '  current=' + c.currentIg + '  suggested=@' + c.suggestedIg + '  [' + c.conf + ']  note=' + c.note));

  console.log('=== NO CREC MATCH (key is not a current crec num) === ' + noCrecMatch.length);
  noCrecMatch.forEach(c => console.log('  key=' + c.key + ' suggested=@' + c.entry.ig + '  note=' + (c.entry.note||'').slice(0,100)));
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
NODE
