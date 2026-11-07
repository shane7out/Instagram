#!/bin/bash
# READ-ONLY audit 3 (Shane, 2026-11-07: "the database should hold 1,781, I don't know why I'm only reading 1,586"). Nothing is written to the database.
# (1) saves the LIVE dashboard page (code only) into the repo so the Total logic of the live version can be read; (2) looks for a group of ~195 records the screen may be leaving out.
set +e
cat > /tmp/audit3.js <<'NODE'
const fs = require('fs');
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const get = async p => { const r = await fetch(DB + p + '.json', { signal: AbortSignal.timeout(90000) }); if (!r.ok) throw new Error(p + ' HTTP ' + r.status); return r.json(); };
const rows = o => !o ? [] : Array.isArray(o) ? o.map((v, i) => [String(i), v]).filter(([, v]) => v) : Object.entries(o).filter(([, v]) => v);
const numOf = ([k, v]) => String((v && typeof v === 'object' && v.num != null) ? v.num : k);
(async () => {
  for (const u of ['https://lvr-data-a60c1.web.app/', 'https://lvr-data-a60c1.web.app/index.html']) {
    try { const r = await fetch(u + '?t=' + Date.now(), { signal: AbortSignal.timeout(90000), cache: 'no-store' }); const t = await r.text(); console.log('fetch ' + u + ' -> HTTP ' + r.status + ', ' + t.length + ' chars, APP_VERSION ' + ((t.match(/APP_VERSION\s*=\s*(\d+)/) || [])[1])); if (r.ok && t.length > 100000) { fs.writeFileSync('.github/db-task/fetched/live-dashboard.html', t); console.log('saved live-dashboard.html'); break; } } catch (e) { console.log('fetch ' + u + ' failed ' + e.message); }
  }
  const [cus, del, crec] = await Promise.all([get('/dashboard/customrecords'), get('/dashboard/deleted'), get('/dashboard_crec')]);
  const C = rows(cus), D = new Set(rows(del).map(([k, v]) => (v && typeof v === 'object' && v.num != null) ? String(v.num) : k)), R = rows(crec);
  const live = C.filter(x => !D.has(numOf(x)));
  console.log('customrecords ' + C.length + ', tombstones ' + D.size + ', customrecords not tombstoned ' + live.length + ', dashboard_crec ' + R.length);
  const cn = new Set(C.map(numOf)); console.log('dashboard_crec nums not in customrecords: ' + R.filter(x => !cn.has(numOf(x))).length + ' | crec nums in customrecords: ' + R.filter(x => cn.has(numOf(x))).length);
  const props = {}; live.forEach(([, v]) => { if (v && typeof v === 'object') Object.keys(v).forEach(k => { props[k] = (props[k] || 0) + 1; }); });
  console.log('fields in live customrecords: ' + Object.entries(props).sort((a, b) => b[1] - a[1]).map(([k, n]) => k + ':' + n).join(' '));
  Object.keys(props).forEach(k => { const d = {}; live.forEach(([, v]) => { const x = v && v[k]; if (typeof x === 'string' || typeof x === 'boolean' || typeof x === 'number') d[x] = (d[x] || 0) + 1; }); const keys = Object.keys(d); if (keys.length > 1 && keys.length <= 14) console.log('  ' + k + ' = ' + keys.map(z => z + ':' + d[z]).join(', ')); });
  const ig = {}; live.forEach(([, v]) => { const h = String((v && (v.instagram || v.ig || v.igHandle)) || '').replace(/^@/, '').toLowerCase().trim(); if (h) ig[h] = (ig[h] || 0) + 1; });
  const dupExtra = Object.values(ig).filter(n => n > 1).reduce((a, n) => a + n - 1, 0);
  console.log('no instagram handle: ' + live.filter(([, v]) => !String((v && (v.instagram || v.ig || v.igHandle)) || '').trim()).length + ' | extra records sharing an Instagram handle: ' + dupExtra);
  const nm = {}; live.forEach(([, v]) => { const h = String((v && v.name) || '').toLowerCase().replace(/[^a-z0-9]/g, ''); if (h) nm[h] = (nm[h] || 0) + 1; });
  console.log('extra records sharing a name: ' + Object.values(nm).filter(n => n > 1).reduce((a, n) => a + n - 1, 0) + ' | no name: ' + live.filter(([, v]) => !(v && v.name)).length);
  const nums = live.map(numOf).map(Number).filter(n => !isNaN(n)).sort((a, b) => a - b);
  const bucket = {}; nums.forEach(n => { const b = Math.floor(n / 1000) * 1000; bucket[b] = (bucket[b] || 0) + 1; });
  console.log('live customrecords by num range: ' + Object.entries(bucket).map(([b, n]) => b + 's:' + n).join(' '));
})().catch(e => console.log('ERROR: ' + e.message));
NODE
node /tmp/audit3.js
git config user.name "db-task-bot"
git config user.email "db-task-bot@users.noreply.github.com"
git add .github/db-task/fetched/live-dashboard.html 2>/dev/null
if git diff --cached --quiet; then echo "nothing new to commit"; else git commit -m "fetch: live dashboard page (code only) for the Total audit" && git push origin HEAD:claude/master-file-e6ofy0 && echo pushed; fi
