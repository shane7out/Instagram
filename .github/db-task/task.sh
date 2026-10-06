#!/bin/bash
# Read-only verification: confirm the 2026-10-05 corrective patch (20
# restaurants + Etho Wellness Club + Cobra Clutch + Black Mountain Griddle)
# actually stuck and hasn't been overwritten by anything since. Routine
# 3-hour check-in sanity check, not a new change.
set +e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json"     -o crec.json
curl -s "$DB/dashboard_adv_crec.json" -o adv.json

node <<'NODE'
const fs = require('fs');
const crec = JSON.parse(fs.readFileSync('crec.json', 'utf8')) || {};
const adv = JSON.parse(fs.readFileSync('adv.json', 'utf8')) || {};

const RESTAURANT_KEYS = [
  "-P3D5Cxd2NWLmDQSo027","-P3D5CzCj8d_H6_RKw-B","-P3D5CzvEvvWT9RHlaqF","-P3D5D-eyoVDuESZDUxx",
  "-P3D5D0N21yDDWZWqcOH","-P3D5D15jKNf51nXQMlq","-P3D5D1nyhbF75SE8c6t","-P3D5D2W_P5UY_-qoXOc",
  "-P3D5D3Ew9ds6S_ilIjr","-P3D5D3yqtBkroEB68VJ","-P3D5D4f7Wf57WSyE_0i","-P3D5D5Otabi482O5Sye",
  "-P3D5D66FkdD-JnXpmva","-P3D5D6pHa5TBcMcVE4m","-P3D5D7XKDN8MuBhVAtj","-P3D5D8EOpHeEctCSG7e",
  "-P3D5D8wuHxrVBo6YkXu","-P3D5D9e5EqNNfZmdJWh","-P3D5DAMl-8jtopknOvk","-P3D5DB4p5k3QX3huIsN",
];
const ETHO_KEY = "-P3D5DBmIwlpOkej7Hza";

let ok = 0, missingNum = 0, missingBoth = [];
for (const k of RESTAURANT_KEYS) {
  const r = crec[k];
  if (!r) { console.log(`MISSING RECORD: ${k}`); continue; }
  const hasNum = r.num != null;
  const hasIG = !!r.instagram;
  if (hasNum) ok++; else missingNum++;
  if (!hasNum) missingBoth.push(`${r.name} (key ${k}) - num:${r.num} ig:${r.instagram||'(none)'}`);
}
console.log(`Restaurants: ${ok}/${RESTAURANT_KEYS.length} have a num field intact, ${missingNum} missing num`);
if (missingBoth.length) { console.log("REGRESSION DETECTED:"); missingBoth.forEach(l => console.log("  " + l)); }

const etho = adv[ETHO_KEY];
console.log(`\nEtho Wellness Club: num=${etho ? etho.num : 'RECORD MISSING'}, ig=${etho ? etho.ig : '-'}, instagram field=${etho ? etho.instagram : '-'} (should be null/absent)`);

const cobra = Object.values(crec).find(v => v && v.name && String(v.name).toLowerCase().trim() === 'cobra clutch');
console.log(`Cobra Clutch: ${cobra ? `num=${cobra.num}, instagram=${cobra.instagram}` : 'NOT FOUND'}`);

const bmg = Object.values(crec).find(v => v && v.name && String(v.name).toLowerCase().trim() === 'black mountain griddle');
console.log(`Black Mountain Griddle: ${bmg ? `num=${bmg.num}, instagram=${bmg.instagram}, phone=${bmg.phone}` : 'NOT FOUND'}`);

console.log(`\ncrec total records: ${Object.keys(crec).length}`);
console.log(`adv total records: ${Object.keys(adv).length}`);
NODE
