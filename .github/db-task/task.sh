#!/bin/bash
# READ-ONLY audit (Shane, 2026-11-06: "What happened to the database? I thought we had like 1,700 records."). Nothing is written or deleted.
# Compares the live restaurant data with the 2026-09-10 backup in .github/db-task/backups and with the counts in LVR-PROJECT-STATUS.md section 4.
set +e
cat > /tmp/audit.js <<'NODE'
const fs = require('fs');
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const get = async p => { const r = await fetch(DB + p + '.json', { signal: AbortSignal.timeout(60000) }); if (!r.ok) throw new Error(p + ' HTTP ' + r.status); return r.json(); };
const rows = o => !o ? [] : Array.isArray(o) ? o.map((v, i) => [String(i), v]).filter(([, v]) => v) : Object.entries(o).filter(([, v]) => v);
const numOf = ([k, v]) => String((v && typeof v === 'object' && v.num != null) ? v.num : k);
const nameOf = v => (v && v.name) || '';
(async () => {
  const B = '.github/db-task/backups/';
  const old = n => JSON.parse(fs.readFileSync(B + 'dashboard_' + n + '.20260910T184922Z.json', 'utf8'));
  const oCrec = old('crec'), oCus = old('customrecords'), oDel = old('deleted');
  const [crec, cus, del, stg] = await Promise.all([get('/dashboard_crec'), get('/dashboard/customrecords'), get('/dashboard/deleted'), get('/dashboard_rest_stg_crec')]);
  const delSet = o => new Set(rows(o).map(([k, v]) => (v && typeof v === 'object' && v.num != null) ? String(v.num) : k));
  const nowDel = delSet(del), oldDel = delSet(oDel);
  const map = (a, b) => { const m = new Map(); rows(a).concat(rows(b)).forEach(e => { m.set(numOf(e), nameOf(e[1])); }); return m; };
  const oldAll = map(oCrec, oCus), nowAll = map(crec, cus);
  const oldLive = [...oldAll.keys()].filter(k => !oldDel.has(k)), nowLive = [...nowAll.keys()].filter(k => !nowDel.has(k));
  console.log('== COUNTS ==');
  console.log('2026-09-10 backup: dashboard_crec ' + rows(oCrec).length + ' | customrecords ' + rows(oCus).length + ' | tombstones ' + oldDel.size + ' | unique nums in crec+customrecords ' + oldAll.size + ' | of those not tombstoned ' + oldLive.length);
  console.log('LIVE now         : dashboard_crec ' + rows(crec).length + ' | customrecords ' + rows(cus).length + ' | tombstones ' + nowDel.size + ' | unique nums in crec+customrecords ' + nowAll.size + ' | of those not tombstoned ' + nowLive.length + ' | staging ' + rows(stg).length);
  const gone = [...oldAll.keys()].filter(k => !nowAll.has(k));
  const goneUntomb = gone.filter(k => !nowDel.has(k));
  console.log('== nums in the Sept backup that are NOT in live crec+customrecords now: ' + gone.length + ' (of which NOT tombstoned: ' + goneUntomb.length + ')');
  goneUntomb.slice(0, 60).forEach(k => console.log('   MISSING num ' + k + ' ' + oldAll.get(k)));
  const newTomb = [...nowDel].filter(k => !oldDel.has(k));
  console.log('== tombstones added since Sept: ' + newTomb.length);
  newTomb.slice(0, 60).forEach(k => console.log('   tombstoned num ' + k + ' ' + (nowAll.get(k) || oldAll.get(k) || '(name unknown)')));
  const added = [...nowAll.keys()].filter(k => !oldAll.has(k));
  console.log('== nums added since Sept: ' + added.length);
  const inCrecNotCus = rows(crec).map(numOf).filter(k => !rows(cus).some(e => numOf(e) === k)).length;
  console.log('crec records that are not in the mirror: ' + inCrecNotCus);
  console.log('== OTHER NODES (doc snapshot: adv 541, exp 29, infl 74, badig 235) ==');
  for (const n of ['dashboard_adv_crec', 'dashboard_exp_crec', 'dashboard_infl_crec', 'dashboard/badig', 'dashboard/status', 'dashboard/attempts']) {
    try { const v = await get('/' + n); console.log('   ' + n + ': ' + rows(v).length); } catch (e) { console.log('   ' + n + ': ERROR ' + e.message); }
  }
})().catch(e => console.log('ERROR: ' + e.message));
NODE
node /tmp/audit.js
