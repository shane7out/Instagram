#!/bin/bash
# Adds new restaurants/bars from an IG listicle post (@foodiedhillon,
# Aug 25 - "NEW RESTAURANT AND BARS IN LAS VEGAS") to the LVR database.
# Don Rice Bar and Yu by Sijie from the same list were already added in
# an earlier session, so they're skipped here. Dedup-checks every
# remaining name against all record-holding nodes (case-insensitive)
# before adding anything, same as every other IG-screenshot addition
# this session. Only the name + the area shown in the screenshot are
# known - no phone/IG/address was shown for these, so none is invented;
# notes say "IG needed" same as other incomplete records in the DB.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json"             -o crec.json
curl -s "$DB/dashboard_adv_crec.json"         -o adv.json
curl -s "$DB/dashboard_exp_crec.json"         -o exp.json
curl -s "$DB/dashboard/customrecords.json"    -o custom.json
curl -s "$DB/dashboard_infl_crec.json"        -o infl.json 2>/dev/null || echo '{}' > infl.json

node <<'NODE'
const fs = require('fs');
const DB = "https://lvr-data-a60c1-default-rtdb.firebaseio.com";

function names(file) {
  let d;
  try { d = JSON.parse(fs.readFileSync(file, 'utf8')); } catch { return []; }
  if (!d || typeof d !== 'object') return [];
  return Object.values(d).map(v => (v && v.name ? String(v.name).toLowerCase().trim() : '')).filter(Boolean);
}

const existing = new Set([
  ...names('crec.json'), ...names('adv.json'), ...names('exp.json'),
  ...names('custom.json'), ...names('infl.json'),
]);

// [name, area, node, extraNote]
const candidates = [
  ["888 Sushi & Wagyu", "Chinatown", "crec", ""],
  ["CAVA", "Centennial Center", "crec", ""],
  ["Cliff House", "Wynn Golf Club / Wynn Las Vegas", "crec", ""],
  ["Cobra Clutch", "Arts District", "crec", ""],
  ["Dancing Dumplings", "Boca Park", "crec", ""],
  ["Doanburi", "Spring Valley", "crec", ""],
  ["Finney's Crafthouse", "Downtown Summerlin", "crec", ""],
  ["Giddy Up", "Dean Martin Dr.", "crec", ""],
  ["Gigolo", "The Strip", "crec", ""],
  ["Glass Box Vegas", "The Bend", "crec", ""],
  ["Hello Kitty Cafe", "The Strip", "crec", ""],
  ["Jet's Pizza", "Centennial Hills", "crec", ""],
  ["Mama's", "Durango Social Club", "crec", ""],
  ["Mama Tess Artisan Kitchen", "Southern Highlands", "crec", ""],
  ["Meril", "M Resort, Henderson", "crec", ""],
  ["Pasta & Pomo", "Fort Apache", "crec", ""],
  ["Royale Frites", "Chinatown", "crec", "Soft opening Oct 10"],
  ["The Corner Store", "The Cosmopolitan", "crec", ""],
  ["Vinyl Room", "Las Vegas", "crec", ""],
  ["Wagyu Factory", "Boca Park", "crec", ""],
  ["WSKY Bar + Grill", "Centennial", "crec", ""],
  ["Etho Wellness Club", "UnCommons", "adv", ""],
];

const nodeUrl = { crec: "dashboard_crec", adv: "dashboard_adv_crec" };

(async () => {
  const skipped = [];
  const added = [];
  const failed = [];
  for (const [name, area, node, extra] of candidates) {
    if (existing.has(name.toLowerCase().trim())) { skipped.push(name); continue; }
    const notesParts = [
      `Manually added from IG post (@foodiedhillon, "NEW RESTAURANT AND BARS IN LAS VEGAS", Aug 25) - IG handle not shown in source post, needs lookup`,
    ];
    if (extra) notesParts.push(extra);
    const record = {
      name,
      address: area,
      cuisine: "",
      notes: notesParts.join(". "),
      owner: "",
      phone: "",
      email: "",
      instagram: "",
    };
    try {
      const res = await fetch(`${DB}/${nodeUrl[node]}.json`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(record),
      });
      const j = await res.json();
      if (j && j.name) { added.push(`${name} -> ${nodeUrl[node]}/${j.name}`); }
      else { failed.push(`${name}: unexpected response ${JSON.stringify(j)}`); }
    } catch (e) {
      failed.push(`${name}: ${e.message}`);
    }
  }
  console.log(`SKIPPED (already present): ${skipped.length}`);
  skipped.forEach(n => console.log(`  - ${n}`));
  console.log(`ADDED: ${added.length}`);
  added.forEach(n => console.log(`  - ${n}`));
  console.log(`FAILED: ${failed.length}`);
  failed.forEach(n => console.log(`  - ${n}`));
})();
NODE
