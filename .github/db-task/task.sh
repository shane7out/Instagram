#!/bin/bash
# One-shot: add The Stadium (sports bar & restaurant, Arts District Las
# Vegas, screenshot from Shane) to dashboard_crec with full DM-visibility
# per the standing rule. Dedup-checks first.
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
  return n.includes('the stadium') || ig.includes('thestadiumlv');
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
  name: 'The Stadium',
  instagram: '@thestadiumlv',
  cuisine: 'Sports bar & restaurant',
  address: '1508 South Main Street, Las Vegas, NV 89104 (Arts District)',
  phone: '',
  email: '',
  owner: 'Local Operators',
  notes: 'Manually added - sports bar, beers/cocktails/food, 25+ HD TVs, thestadiumlvnv.com, 2,858 followers as of add date'
};

fs.writeFileSync('/tmp/stadium_record.json', JSON.stringify(record));
fs.writeFileSync('/tmp/stadium_num.txt', String(num));
console.log('WILL_ADD num=' + num + ' ' + JSON.stringify(record));
NODE

if [ -f /tmp/stadium_num.txt ]; then
  NUM=$(cat /tmp/stadium_num.txt)
  echo "Writing dashboard_crec/$NUM ..."
  curl -s -X PUT -d @/tmp/stadium_record.json "$DB/dashboard_crec/$NUM.json"
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
