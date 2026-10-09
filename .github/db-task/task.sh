#!/bin/bash
# 3-hour check-in (2026-10-09 ~12:36 UTC). Sanity pass on the 9 manual
# restaurant adds from the last ~18h (Mezban, Terminal 4, What The Grill,
# The Stadium, Duke's Dogs, Roxie's, Ten Seconds Yunnan, SnoGlow, Rollin
# Sweet) - checking for (a) accidental near-duplicate num/name/handle
# collisions across the whole dashboard_crec, and (b) confirming all 9
# still have proper num+instagram+status set (nothing got clobbered by a
# later write).
set +e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json" -o /tmp/crec.json --max-time 20
curl -s "$DB/dashboard/status.json" -o /tmp/status.json --max-time 20

node <<'NODE'
const fs = require('fs');
function load(p){ try { return JSON.parse(fs.readFileSync(p,'utf8')) || {}; } catch(e){ return {}; } }
const crec = load('/tmp/crec.json');
const status = load('/tmp/status.json');

const recent = ['Mezban','Terminal 4','What The Grill','The Stadium',"Duke's Dogs",
  "Roxie's Drive n' Diner",'Ten Seconds Yunnan Rice Noodle Las Vegas','SnoGlow Shaved Ice','Rollin Sweet'];

console.log('=== recent-add verification ===');
for (const name of recent) {
  const match = Object.values(crec).find(r => r && r.name === name);
  if (!match) { console.log('MISSING: ' + name); continue; }
  const hasIg = !!(match.instagram && String(match.instagram).trim());
  const hasStatus = String(match.num) in status;
  console.log((hasIg ? 'OK' : 'NO-IG') + ' | ' + (hasStatus ? 'status-set' : 'NO-STATUS') + ' | num=' + match.num + ' | ' + name);
}

console.log('\n=== duplicate scan (whole dashboard_crec) ===');
const byNum = {};
const seen = [];
let numCollisions = 0;
for (const [k, r] of Object.entries(crec)) {
  if (!r || typeof r !== 'object') continue;
  if (byNum[r.num]) { numCollisions++; console.log('NUM COLLISION: ' + r.num + ' -> "' + byNum[r.num] + '" vs "' + r.name + '"'); }
  else byNum[r.num] = r.name;
  seen.push({ name: (r.name||'').toLowerCase().replace(/[^a-z0-9]/g,''), real: r.name, ig: (r.instagram||'').toLowerCase().replace('@','').trim() });
}
let nameDupes = 0;
for (let i = 0; i < seen.length; i++) {
  for (let j = i+1; j < seen.length; j++) {
    if (seen[i].name && seen[i].name === seen[j].name) {
      nameDupes++;
      console.log('NAME DUPE: "' + seen[i].real + '" appears twice');
    }
  }
}
console.log('num collisions: ' + numCollisions + ', name dupes: ' + nameDupes + ' (out of ' + seen.length + ' total restaurants)');
NODE
