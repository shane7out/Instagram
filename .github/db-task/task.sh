#!/bin/bash
# One-shot: add Vegas by Night (Las Vegas luxury travel agency, screenshot
# from Shane) as an ADVERTISER - not a restaurant. Per the dashboard's own
# rules (advSaveNewRecord()), new advertisers go to the STAGING node
# dashboard_adv_stg_crec, not straight to dashboard_adv_crec, with num
# allocated from a 9000+ pool, schema {num,name,ig,phone,email,cat,
# status:'pending',defaultStatus:'pending',notes:''}. Dedup-checks first.
set +e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_adv_crec.json" -o /tmp/advcrec.json --max-time 20
curl -s "$DB/dashboard_adv_stg_crec.json" -o /tmp/advstg.json --max-time 20
curl -s "$DB/dashboard_adv_deleted.json" -o /tmp/advdel.json --max-time 20

node <<'NODE'
const fs = require('fs');
function load(p){ try { return JSON.parse(fs.readFileSync(p,'utf8')) || {}; } catch(e){ return {}; } }
const advcrec = load('/tmp/advcrec.json');
const advstg = load('/tmp/advstg.json');
const advdel = load('/tmp/advdel.json');

const existing = [...Object.values(advcrec), ...Object.values(advstg)].filter(Boolean);
const dup = existing.find(r => {
  const n = (r.name||'').toLowerCase();
  const ig = (r.ig||'').toLowerCase().replace('@','');
  return n.includes('vegas by night') || ig.includes('lvegasbynight');
});
if (dup) {
  console.log('DUP_FOUND:' + JSON.stringify(dup));
  process.exit(0);
}

let max = 29999;
function scan(obj){
  for (const r of Object.values(obj||{})) {
    if (r && typeof r === 'object' && typeof r.num === 'number' && r.num > max) max = r.num;
  }
}
scan(advcrec); scan(advstg);
for (const k of Object.keys(advdel||{})) {
  const n = parseInt(k, 10);
  if (!isNaN(n) && n > max) max = n;
}
const num = max + 1;

const record = {
  num,
  name: 'Vegas by Night',
  ig: '@lvegasbynight',
  phone: '',
  email: 'LVegasbyNight@gmail.com',
  cat: 'Tours',
  status: 'pending',
  defaultStatus: 'pending',
  notes: 'Manually added - Las Vegas luxury travel agency/advisor, 38K followers as of add date'
};

fs.writeFileSync('/tmp/vbn_record.json', JSON.stringify(record));
fs.writeFileSync('/tmp/vbn_num.txt', String(num));
console.log('WILL_ADD num=' + num + ' ' + JSON.stringify(record));
NODE

if [ -f /tmp/vbn_num.txt ]; then
  NUM=$(cat /tmp/vbn_num.txt)
  echo "Writing dashboard_adv_stg_crec/$NUM ..."
  curl -s -X PUT -d @/tmp/vbn_record.json "$DB/dashboard_adv_stg_crec/$NUM.json"
  echo
  echo "Verifying..."
  curl -s "$DB/dashboard_adv_stg_crec/$NUM.json"
  echo
else
  echo "Skipped write - see DUP check output above"
fi
