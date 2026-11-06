#!/bin/bash
# READ-ONLY audit 2 (Shane, 2026-11-06: "I thought I had like 1,750... go back and check"). Nothing is written or deleted.
# Rebuilds the dashboard's Total the way the dashboard does (page-code base list + customrecords, minus tombstones) for
# (a) the 2026-09-10 backup with the Sept base list, (b) the live data with the LIVE base list fetched from the live site.
set +e
cat > /tmp/audit2.js <<'NODE'
const fs = require('fs');
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const get = async p => { const r = await fetch(DB + p + '.json', { signal: AbortSignal.timeout(60000) }); if (!r.ok) throw new Error(p + ' HTTP ' + r.status); return r.json(); };
const rows = o => !o ? [] : Array.isArray(o) ? o.map((v, i) => [String(i), v]).filter(([, v]) => v) : Object.entries(o).filter(([, v]) => v);
const numOf = ([k, v]) => String((v && typeof v === 'object' && v.num != null) ? v.num : k);
const baseNums = txt => { const m = /RESTAURANTS_BASE\s*=\s*\[/.exec(txt); if (!m) return null; let d = 1, k = m.index + m[0].length; const j = k; while (d && k < txt.length) { const c = txt[k]; if (c === '[') d++; else if (c === ']') d--; k++; } return new Set([...txt.slice(j, k).matchAll(/\bnum\s*:\s*(\d+)/g)].map(x => x[1])); };
const delSet = o => new Set(rows(o).map(([k, v]) => (v && typeof v === 'object' && v.num != null) ? String(v.num) : k));
const total = (base, custom, del) => { const all = new Set([...base, ...custom]); return [...all].filter(n => !del.has(n)).length; };
(async () => {
  const sBase = baseNums(fs.readFileSync('.github/db-task/fetched/seed-data.js', 'utf8'));
  console.log('Sept base list (repo copy, seed-data.js of 2026-09-10): ' + sBase.size);
  let lBase = null, ver = '';
  for (const u of ['https://lvr-data-a60c1.web.app/seed-data.js?v=1', 'https://lvr-data-a60c1.web.app/seed-data.js']) {
    try { const r = await fetch(u, { signal: AbortSignal.timeout(60000) }); console.log('fetch ' + u + ' -> HTTP ' + r.status); if (r.ok) { const t = await r.text(); lBase = baseNums(t); if (lBase) break; } } catch (e) { console.log('fetch ' + u + ' failed: ' + e.message); }
  }
  try { const r = await fetch('https://lvr-data-a60c1.web.app/', { signal: AbortSignal.timeout(60000) }); const t = await r.text(); const m = t.match(/v\d{3}\b/g); ver = (m || []).slice(0, 5).join(','); console.log('live dashboard page HTTP ' + r.status + ', version strings: ' + ver); } catch (e) { console.log('dashboard page fetch failed: ' + e.message); }
  console.log('LIVE base list: ' + (lBase ? lBase.size : 'NOT FOUND'));
  const B = '.github/db-task/backups/', old = n => JSON.parse(fs.readFileSync(B + 'dashboard_' + n + '.20260910T184922Z.json', 'utf8'));
  const oCus = new Set(rows(old('customrecords')).map(numOf)), oDel = delSet(old('deleted'));
  const [cus, del] = await Promise.all([get('/dashboard/customrecords'), get('/dashboard/deleted')]);
  const nCus = new Set(rows(cus).map(numOf)), nDel = delSet(del);
  console.log('== Total as the dashboard builds it (base + customrecords - tombstones) ==');
  console.log('Sept 10 backup + Sept base : ' + total(sBase, oCus, oDel));
  console.log('LIVE data      + Sept base : ' + total(sBase, nCus, nDel));
  if (lBase) {
    console.log('LIVE data      + LIVE base : ' + total(lBase, nCus, nDel) + '   <- compare with the 1586 on Shane\'s screen');
    console.log('Sept backup    + LIVE base : ' + total(lBase, oCus, oDel));
    const gone = [...sBase].filter(n => !lBase.has(n)), added = [...lBase].filter(n => !sBase.has(n));
    console.log('base nums in the Sept copy but not in the live page: ' + gone.length + ' | in the live page but not in the Sept copy: ' + added.length);
    const goneVisible = gone.filter(n => !nDel.has(n));
    console.log('   of the ones gone from the live base, NOT tombstoned: ' + goneVisible.length);
    console.log('   sample: ' + goneVisible.slice(0, 40).join(','));
  }
  const seen = new Set([...(lBase || sBase), ...nCus]); console.log('unique nums in base+customrecords now: ' + seen.size + ' | tombstones that hit them: ' + [...seen].filter(n => nDel.has(n)).length);
})().catch(e => console.log('ERROR: ' + e.message));
NODE
node /tmp/audit2.js
