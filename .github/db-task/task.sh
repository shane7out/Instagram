#!/bin/bash
# Apply 8 verified Instagram handle corrections sourced from
# /dashboard/igsuggest (a genuine, sourced IG-verification dataset found
# this cycle - each entry cites a specific address/follower count/website
# cross-reference). All 8 are "high" confidence single-character-typo
# fixes or a brand-new verified handle for a previously-blank record.
# Explicitly SKIPPING 2 lower-confidence igsuggest entries (50206, 50608)
# that the data itself flags as needing a human look first - left for the
# owner, not auto-applied.
# For each: fetch current record, update only instagram (+ igHandle if
# present), preserve every other field, then clear the stale badig flag.
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
function put(url, body) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const u = new URL(url);
    const req = https.request(u, { method: 'PUT', headers: { 'Content-Type': 'application/json' } }, r => {
      let d = ''; r.on('data', c => d += c); r.on('end', () => resolve({ status: r.statusCode, body: d }));
    });
    req.on('error', reject); req.write(data); req.end();
  });
}
function del(url) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const req = https.request(u, { method: 'DELETE' }, r => {
      let d = ''; r.on('data', c => d += c); r.on('end', () => resolve({ status: r.statusCode, body: d }));
    });
    req.on('error', reject); req.end();
  });
}

const fixes = {
  '50125': '@nanas_house_of_soul_food_',
  '50204': '@whiskfulthinkingcakeslv',
  '50278': '@teriyakimadnesslv',
  '50315': '@sonrisagrill.lv',
  '50345': '@earthlyplantbased',
  '50360': '@aguas_el_chavo',
  '50611': '@koreahouselv',
  '50818': '@daikonvegansushi',
};

(async () => {
  for (const [num, newIg] of Object.entries(fixes)) {
    const raw = await get(DB + '/dashboard_crec/' + num + '.json');
    const rec = JSON.parse(raw);
    if (!rec) { console.log(num + ': NOT FOUND - skipping'); continue; }
    const before = rec.instagram || '(blank)';
    rec.instagram = newIg;
    if (rec.igHandle !== undefined) rec.igHandle = newIg;
    const r1 = await put(DB + '/dashboard_crec/' + num + '.json', rec);
    console.log(num + ' (' + rec.name + '): ' + before + ' -> ' + newIg + '  write:' + r1.status);
    const r2 = await del(DB + '/dashboard/badig/' + num + '.json');
    console.log('  cleared badig flag: ' + r2.status);
  }
  console.log('DONE: applied 8 verified igsuggest corrections');
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
NODE
