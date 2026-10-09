#!/bin/bash
# 3-hour check-in (2026-10-09 ~06:36 UTC). Re-checking GitHub Pages / DNS
# after a >24h gap since the last actual check, plus a fresh outreach-
# progress read (status distribution) since that hasn't been looked at
# in a while either.
set +e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

echo "=== GitHub Pages / DNS ==="
curl -s -o /dev/null -w "shane7out.github.io/Instagram/ -> HTTP %{http_code}\n" https://shane7out.github.io/Instagram/ --max-time 15
curl -s -o /dev/null -w "keytechnologies.si/ -> HTTP %{http_code}\n" https://keytechnologies.si/ --max-time 15

echo
echo "=== Outreach progress (status distribution) ==="
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
for (const [k,c] of Object.entries(counts).sort((a,b)=>b[1]-a[1])) {
  console.log('  ' + k + ': ' + c);
}

let dmable = 0;
for (const r of Object.values(crec)) {
  if (!r || typeof r !== 'object') continue;
  if (r.num == null || !r.instagram || !String(r.instagram).trim()) continue;
  dmable++;
}
console.log('DM-able restaurants total: ' + dmable);
console.log('Total restaurants in dashboard_crec: ' + Object.keys(crec).length);
NODE
