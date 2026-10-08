#!/bin/bash
# 3-hour check-in (2026-10-08 ~12:36 UTC). New angle: actual DM outreach
# progress, not just DB-visibility. dashboard/status/<num> holds each
# restaurant's real outreach state ('pending' | whatever the dashboard sets
# on contact/response) - this checks the live distribution so Shane has a
# real read on how much outreach has actually happened vs. still sitting.
set +e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard/status.json" -o /tmp/status.json --max-time 20
curl -s "$DB/dashboard_crec.json" -o /tmp/crec.json --max-time 20

node <<'NODE'
const fs = require('fs');
function load(p){ try { return JSON.parse(fs.readFileSync(p,'utf8')) || {}; } catch(e){ return {}; } }
const status = load('/tmp/status.json');
const crec = load('/tmp/crec.json');

const counts = {};
for (const v of Object.values(status||{})) {
  const k = (v === null || v === undefined) ? '(null)' : String(v);
  counts[k] = (counts[k]||0) + 1;
}
console.log('Total status entries: ' + Object.keys(status||{}).length);
console.log('Breakdown:');
for (const [k,c] of Object.entries(counts).sort((a,b)=>b[1]-a[1])) {
  console.log('  ' + k + ': ' + c);
}

// cross-check: how many restaurants have a DM-able igHandle but no status entry at all (truly untouched)
let dmable = 0, dmableNoStatus = 0;
for (const [k,r] of Object.entries(crec)) {
  if (!r || typeof r !== 'object') continue;
  if (r.num == null || !r.instagram || !String(r.instagram).trim()) continue;
  dmable++;
  if (!(String(r.num) in status)) dmableNoStatus++;
}
console.log('\nDM-able restaurants (num + instagram present): ' + dmable);
console.log('Of those, with NO status entry at all (not even "pending" written): ' + dmableNoStatus);
NODE
