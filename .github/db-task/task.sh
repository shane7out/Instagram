#!/bin/bash
# Corrective pass for the 2026-10-05 IG-listicle additions, per the new
# standing rule in LVR-PROJECT-STATUS.md §10: every new business must be
# DM-able, not just a database row.
#
# Root cause (confirmed by reading the live dashboard's own JS in this
# repo at patched-dashboard.html): dashboard_crec entries without a `num`
# field are SILENTLY IGNORED by the real-time merge listener (_prOnRemote,
# requires r.num!=null) - they never even render in the restaurant list,
# let alone the DM queue. The 20 restaurants added earlier today have no
# num at all. Separately, "needs DM" also requires a non-empty Instagram
# handle (igHandle/ig gate) - all 20 were added blank. The advertiser
# addition (Etho Wellness Club) used the wrong field name (instagram
# instead of ig) and also has no num.
#
# This patches num + a REAL, web-search-verified Instagram handle (never
# guessed - 4 of 20 genuinely have no confirmed handle and are left
# blank, flagged below) onto each existing record by its known Firebase
# key, checks the pre-existing "Cobra Clutch" record for the same gaps,
# and adds the new Black Mountain Griddle record correctly from the
# start (num + real IG handle + real phone/address, all in one write).
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json"         -o crec.json
curl -s "$DB/dashboard_adv_crec.json"     -o adv.json
curl -s "$DB/dashboard/deleted.json"      -o deleted.json
curl -s "$DB/dashboard_adv_deleted.json"  -o advdeleted.json 2>/dev/null || echo 'null' > advdeleted.json

node <<'NODE'
const fs = require('fs');
const DB = "https://lvr-data-a60c1-default-rtdb.firebaseio.com";

function readJSON(f, fallback) {
  try { const d = JSON.parse(fs.readFileSync(f, 'utf8')); return d == null ? fallback : d; }
  catch { return fallback; }
}
const crec = readJSON('crec.json', {});
const adv = readJSON('adv.json', {});
const deleted = readJSON('deleted.json', {});
const advDeleted = readJSON('advdeleted.json', {});

function maxNum(obj) {
  let m = 0;
  if (obj && typeof obj === 'object') {
    for (const v of Object.values(obj)) {
      const n = v && typeof v === 'object' ? v.num : v;
      const num = typeof n === 'number' ? n : parseInt(n, 10);
      if (!isNaN(num) && num > m) m = num;
    }
  }
  return m;
}
function maxKeyNum(obj) {
  let m = 0;
  if (obj && typeof obj === 'object') {
    for (const k of Object.keys(obj)) { const n = parseInt(k, 10); if (!isNaN(n) && n > m) m = n; }
  }
  return m;
}

// Known static ranges from .github/db-task/fetched/seed-data.js (baked into the
// deployed site, not in Firebase) - RESTAURANTS_BASE max 1252, RESTAURANTS_STAGING
// max 20487, ADVERTISERS_STAGING max 17854. Stay clear of all of it with margin.
let restMax = Math.max(maxNum(crec), maxKeyNum(deleted), 1252, 20487, 60000);
let advMax = Math.max(maxNum(adv), maxKeyNum(advDeleted), 17854, 9000, 30000);

function nextRestNum() { return ++restMax; }
function nextAdvNum() { return ++advMax; }

// [firebase key, instagram handle or null, confidence note]
const RESTAURANT_PATCHES = [
  ["-P3D5Cxd2NWLmDQSo027", "@888sushiwagyu", ""],
  ["-P3D5CzCj8d_H6_RKw-B", "@cava", "brand-level account, not location-specific"],
  ["-P3D5CzvEvvWT9RHlaqF", null, "NOT FOUND - restaurant opened Oct 2026, too new for its own account yet"],
  ["-P3D5D-eyoVDuESZDUxx", null, "NOT FOUND - source says no website/social media yet"],
  ["-P3D5D0N21yDDWZWqcOH", "@doanburi", ""],
  ["-P3D5D15jKNf51nXQMlq", "@finneyscrafthouse", "brand-level account, not Summerlin-specific"],
  ["-P3D5D1nyhbF75SE8c6t", "@eatgiddyup", ""],
  ["-P3D5D2W_P5UY_-qoXOc", null, "NOT FOUND - no dedicated account located"],
  ["-P3D5D3Ew9ds6S_ilIjr", "@glassboxlasvegas", ""],
  ["-P3D5D3yqtBkroEB68VJ", "@hellokittycafevegas", ""],
  ["-P3D5D4f7Wf57WSyE_0i", "@jetspizza", "brand-level account, not location-specific"],
  ["-P3D5D5Otabi482O5Sye", "@durangosocialclub", "Mama's is a menu program inside Durango Social Club, not separately branded"],
  ["-P3D5D66FkdD-JnXpmva", "@mamatessartisankitchen", ""],
  ["-P3D5D6pHa5TBcMcVE4m", "@merilnola", "lower confidence - may be the original New Orleans location's account"],
  ["-P3D5D7XKDN8MuBhVAtj", null, "NOT FOUND - confirmed to have an Instagram but handle not resolved"],
  ["-P3D5D8EOpHeEctCSG7e", "@royale_frites", ""],
  ["-P3D5D8wuHxrVBo6YkXu", "@thecornerstore", "likely the shared brand account from the original SoHo location"],
  ["-P3D5D9e5EqNNfZmdJWh", "@VinylRoomLV", ""],
  ["-P3D5DAMl-8jtopknOvk", "@wagyu.factory", "brand-level account (Chubby Group), not location-specific"],
  ["-P3D5DB4p5k3QX3huIsN", "@wskybarandgrill", ""],
];

const ETHO_KEY = "-P3D5DBmIwlpOkej7Hza";
const ETHO_IG = "ethoclub";

(async () => {
  const report = { restaurantsPatched: [], restaurantsSkipped: [], ethoPatched: null, cobraClutch: null, blackMountain: null, failed: [] };

  // 1) Patch the 20 restaurant records: add num, and instagram where a real handle was found.
  for (const [key, ig, note] of RESTAURANT_PATCHES) {
    const existing = crec[key];
    if (!existing) { report.failed.push(`restaurant key ${key} not found in live crec.json`); continue; }
    const num = nextRestNum();
    const patch = { num };
    if (ig) patch.instagram = ig;
    try {
      const res = await fetch(`${DB}/dashboard_crec/${key}.json`, {
        method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(patch),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      report.restaurantsPatched.push(`${existing.name} -> num ${num}${ig ? ', ' + ig : ' (NO HANDLE - will not count as needs-DM until one is found)'}${note ? ' [' + note + ']' : ''}`);
    } catch (e) {
      report.failed.push(`${existing.name}: ${e.message}`);
    }
  }

  // 2) Fix Etho Wellness Club: wrong field name (instagram, empty) + no num.
  //    PATCH in the real `ig` field, a num, and null out the unused `instagram` field.
  const ethoExisting = adv[ETHO_KEY];
  if (ethoExisting) {
    const num = nextAdvNum();
    try {
      const res = await fetch(`${DB}/dashboard_adv_crec/${ETHO_KEY}.json`, {
        method: 'PATCH', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ num, ig: ETHO_IG, instagram: null, cat: "Spa" }),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      report.ethoPatched = `Etho Wellness Club -> num ${num}, ig: ${ETHO_IG}, cat: Spa`;
    } catch (e) { report.failed.push(`Etho Wellness Club: ${e.message}`); }
  } else {
    report.failed.push(`Etho Wellness Club key ${ETHO_KEY} not found in live adv.json`);
  }

  // 3) Check the pre-existing "Cobra Clutch" record (skipped as a dupe during the
  //    original add) for the same gaps - patch if it's missing num or instagram.
  const cobraEntry = Object.entries(crec).find(([, v]) => v && v.name && String(v.name).toLowerCase().trim() === 'cobra clutch');
  if (cobraEntry) {
    const [cobraKey, cobraVal] = cobraEntry;
    const patch = {};
    if (cobraVal.num == null) patch.num = nextRestNum();
    if (!cobraVal.instagram) patch.instagram = "@cobraclutch.lv";
    if (Object.keys(patch).length) {
      try {
        const res = await fetch(`${DB}/dashboard_crec/${cobraKey}.json`, {
          method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(patch),
        });
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        report.cobraClutch = `already existed, was missing ${Object.keys(patch).join(' & ')} - patched: ${JSON.stringify(patch)}`;
      } catch (e) { report.failed.push(`Cobra Clutch patch: ${e.message}`); }
    } else {
      report.cobraClutch = `already existed and already had both num (${cobraVal.num}) and instagram (${cobraVal.instagram}) - no patch needed`;
    }
  } else {
    report.cobraClutch = "NOT FOUND in live crec.json - name may differ from expected, needs manual check";
  }

  // 4) Add Black Mountain Griddle fresh, correctly, from a real IG screenshot
  //    (name, handle, phone, and address all read directly off the screenshot).
  const bmgName = "Black Mountain Griddle";
  const bmgExists = Object.values(crec).some(v => v && v.name && String(v.name).toLowerCase().trim() === bmgName.toLowerCase());
  if (bmgExists) {
    report.blackMountain = "already present in dashboard_crec - skipped";
  } else {
    const num = nextRestNum();
    const record = {
      num,
      name: bmgName,
      address: "72 W Horizon Ridge Pkwy, Henderson, NV 89012",
      cuisine: "Breakfast/Brunch",
      notes: "Manually added from IG profile screenshot. Modern breakfast and brunch spot in Henderson, NV - elevated comfort food, craft coffee. 1,530 followers, 76 posts.",
      owner: "",
      phone: "(702) 954-4704",
      email: "",
      instagram: "@black_mountain_griddle",
    };
    try {
      const res = await fetch(`${DB}/dashboard_crec.json`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(record),
      });
      const j = await res.json();
      if (j && j.name) report.blackMountain = `added -> dashboard_crec/${j.name}, num ${num}, @black_mountain_griddle`;
      else { report.failed.push(`Black Mountain Griddle: unexpected response ${JSON.stringify(j)}`); }
    } catch (e) { report.failed.push(`Black Mountain Griddle: ${e.message}`); }
  }

  console.log("=== RESTAURANTS PATCHED (" + report.restaurantsPatched.length + ") ===");
  report.restaurantsPatched.forEach(l => console.log("  " + l));
  console.log("\n=== ETHO WELLNESS CLUB ===");
  console.log("  " + report.ethoPatched);
  console.log("\n=== COBRA CLUTCH (pre-existing) ===");
  console.log("  " + report.cobraClutch);
  console.log("\n=== BLACK MOUNTAIN GRIDDLE (new) ===");
  console.log("  " + report.blackMountain);
  console.log("\n=== FAILED (" + report.failed.length + ") ===");
  report.failed.forEach(l => console.log("  " + l));
})();
NODE
