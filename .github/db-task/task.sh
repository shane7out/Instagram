#!/bin/bash
# One-shot: add Duke's Dogs (Cali-style hot dog food truck, screenshot from
# Shane) to dashboard_crec with full DM-visibility per the standing rule.
# Dedup-checks first.
set +e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json" -o /tmp/crec.json --max-time 20
curl -s "$DB/dashboard/customrecords.json" -o /tmp/customrecords.json --max-time 20
curl -s "$DB/dashboard/deleted.json" -o /tmp/deleted.json --max-time 20

node <<'NODE'
const fs = require('fs');
function load(p){ try { return JSON.parse(fs.readFileSync(p,'utf8')) || {}; } catch(e){ return {}; } }
const crec = load('/tmp/crec.json');
const customrecords = load('/tmp/customrecords.json');
const deleted = load('/tmp/deleted.json');

const existing = Object.values(crec).filter(Boolean);
const dup = existing.find(r => {
  const n = (r.name||'').toLowerCase();
  const ig = (r.instagram||'').toLowerCase().replace('@','');
  return n.includes("duke's dogs") || n.includes('dukes dogs') || ig.includes('dukesdogs702');
});
if (dup) {
  console.log('DUP_FOUND:' + JSON.stringify(dup));
  process.exit(0);
}

let max = 59999;
function scan(obj){
  for (const r of Object.values(obj||{})) {
    if (r && typeof r === 'object' && typeof r.num === 'number' && r.num > max) max = r.num;
  }
}
scan(crec); scan(customrecords); scan(deleted);
const num = max + 1;

const record = {
  num,
  name: "Duke's Dogs",
  instagram: '@dukesdogs702',
  cuisine: 'Cali-style street hot dogs (food truck)',
  address: 'Las Vegas, NV (mobile food truck - pop-ups)',
  phone: '',
  email: '',
  owner: 'Local Operators',
  notes: 'Manually added - O.G. Cali dogs, from Cali to Vegas, 1,921 followers as of add date'
};

fs.writeFileSync('/tmp/dd_record.json', JSON.stringify(record));
fs.writeFileSync('/tmp/dd_num.txt', String(num));
console.log('WILL_ADD num=' + num + ' ' + JSON.stringify(record));
NODE

if [ -f /tmp/dd_num.txt ]; then
  NUM=$(cat /tmp/dd_num.txt)
  echo "Writing dashboard_crec/$NUM ..."
  curl -s -X PUT -d @/tmp/dd_record.json "$DB/dashboard_crec/$NUM.json"
  echo
  curl -s -X PUT -d '"pending"' "$DB/dashboard/status/$NUM.json"
  echo
  curl -s -X PUT -d '[{"email":"","status":"pending","date":null,"note":""}]' "$DB/dashboard/attempts/$NUM.json"
  echo
  echo "Verifying..."
  curl -s "$DB/dashboard_crec/$NUM.json"
  echo
else
  echo "Skipped write - see DUP check output above"
fi
