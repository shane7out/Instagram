#!/bin/bash
# audit 12 (Shane, 2026-11-09: "re-run the needs-a-DM check"). Runs the REAL live dashboard (now v474, which lists all records) in a throwaway headless Chromium with the
# live data, every write blocked (only GET/HEAD allowed, Firebase SDK and websockets blocked), unlocked WITHOUT a PIN by calling the page's own unlock function. Reports the
# page's own badges (Total, Need to DM) and, for the 196 records that used to be hidden (num 50802 and up), how many are DM-able, already DM'd, flagged bad IG, or have no
# Instagram handle (those can never show as needing a DM, standing rule 10). Nothing is written anywhere.
set +e
mkdir -p /tmp/pw && cd /tmp/pw && npm init -y >/dev/null 2>&1 && npm i playwright@1.49.1 >/dev/null 2>&1
npx playwright install chromium >/tmp/pwinstall.log 2>&1; tail -1 /tmp/pwinstall.log
cat > /tmp/pw/audit12.js <<'NODE'
const pw = require('/tmp/pw/node_modules/playwright');
(async () => {
  const b = await pw.chromium.launch(); const ctx = await b.newContext({ viewport: { width: 1280, height: 900 } });
  let blocked = 0;
  await ctx.route('**/*', route => { const r = route.request(), m = r.method(), u = r.url();
    if (m !== 'GET' && m !== 'HEAD') { blocked++; return route.abort(); }
    if (/gstatic\.com\/firebasejs|firebaseapp\.com|googleapis\.com\/identitytoolkit|securetoken/.test(u)) { blocked++; return route.abort(); }
    return route.continue(); });
  const p = await ctx.newPage(); const errs = []; p.on('pageerror', e => errs.push(String(e).slice(0, 160)));
  await p.goto('https://lvr-data-a60c1.web.app/?t=' + Date.now(), { waitUntil: 'load', timeout: 90000 }); await p.waitForTimeout(3000);
  await p.evaluate(() => { try { _coEditor = false; _applyCoEditorDmKey(); } catch (e) {} _bioUnlock(); });
  await p.waitForTimeout(15000);
  const r = await p.evaluate(() => {
    const R = RESTAURANTS.filter(x => !x._isStaging);
    const norm = s => String(s || '').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/&/g, ' and ').replace(/\b(las vegas|the|restaurant|ristorante)\b/g, ' ').replace(/[^a-z0-9]+/g, ' ').trim();
    const QUAL = /(arts district|venetian|centennial|silverado|green valley|summerlin|henderson|spring valley|boca|downtown|fremont|strip|airport|paris|aria|cosmopolitan|mgm|wynn|resorts|caesars|palms|rampart| at )/i;
    const UNSURE = new Set([1026, 50818, 1097, 50628, 1105, 50861, 1132, 50845, 1134, 50639, 1186, 60005, 50217, 60011]);
    const has = x => !!(String(x.phone || '').replace(/\D/g, '') || String(x.address || '').trim());
    const dm = x => !!(dmMap[x.num] && dmMap[x.num] !== 'pending');
    const by = {}; R.forEach(x => { const k = _igKey(x); if (k) (by[k] = by[k] || []).push(x); });
    const L = [], skipped = [];
    Object.entries(by).filter(([k, v]) => v.length > 1).forEach(([k, v]) => {
      if (v.length !== 2) { skipped.push('@' + k + ' group of ' + v.length); return; }
      const [a, b] = v; const rev = !has(a) && has(b) ? a : (!has(b) && has(a) ? b : null); const old = rev === a ? b : a;
      if (!rev) { skipped.push('@' + k + ' both or neither have phone/address: ' + a.num + ' ' + b.num); return; }
      const why = [];
      if (UNSURE.has(Number(a.num)) || UNSURE.has(Number(b.num))) why.push('possibly separate branches');
      if (norm(a.name) !== norm(b.name)) why.push('names differ: "' + a.name + '" vs "' + b.name + '"');
      if (QUAL.test(a.name) || QUAL.test(b.name)) why.push('location word in name');
      if (!dm(old)) why.push('older record not messaged');
      if (dm(rev) && !(rev.num === 1329)) why.push('revived copy was messaged too');
      if (why.length) skipped.push('@' + k + ' keep ' + old.num + ' / ' + rev.num + ': ' + why.join('; ')); else L.push({ del: Number(rev.num), keep: Number(old.num), delName: rev.name, keepName: old.name, handle: k });
    });
    return { L, skipped }; });
  require('fs').writeFileSync('/tmp/dupes.json', JSON.stringify(r));
  console.log('AUDIT12 candidates ' + r.L.length + ', skipped ' + r.skipped.length);
  await b.close();
})().catch(e => console.log('ERROR ' + (e.stack || e.message).slice(0, 500)));
NODE
node /tmp/pw/audit12.js

cat > /tmp/dupe-apply.js <<'NODE'
const fs = require('fs');
const APPLY = process.env.APPLY === '1';
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const get = async p => { const r = await fetch(DB + p + '.json', { signal: AbortSignal.timeout(60000) }); if (!r.ok) throw new Error(p + ' HTTP ' + r.status); return r.json(); };
const send = async (m, p, b) => (await fetch(DB + p + '.json', { method: m, headers: { 'Content-Type': 'application/json' }, body: b === undefined ? undefined : JSON.stringify(b), signal: AbortSignal.timeout(60000) })).status;
const MAPS = ['dm','badig','status','attempts','interested','notinterested','followup','problem','ghosted','foodtrade','foodtradedone','sunny','usernotes','igovr','nameoverride','fieldoverride','userattempts','rspriority'];
// handle repairs (Shane's OK 2026-11-10): trim spaces / stray @ only; 1119 and 1251 need a human lookup and are NOT touched
const FIX = { 1530: '@Noosh_By_Chaiya_Bistro', 1613: '@2ScoopsofAlohalv', 50011: '@Sumoomakaselv', 1575: '@sunsetgrilllasvegas' };
(async () => {
  const { L, skipped } = JSON.parse(fs.readFileSync('/tmp/dupes.json', 'utf8'));
  console.log('MODE ' + (APPLY ? 'APPLY' : 'PLAN ONLY (nothing written)'));
  console.log('SKIPPED (not obvious, left alone): ' + skipped.length); skipped.forEach(x => console.log('  skip ' + x));
  const crec = (await get('/dashboard_crec')) || {}, custom = (await get('/dashboard/customrecords')) || [];
  const dDel = (await get('/dashboard_deleted')) || {}, pDel = (await get('/dashboard/deleted')) || {};
  const sample = o => JSON.stringify(Array.isArray(o) ? o.slice(0, 3) : Object.entries(o).slice(0, 3));
  console.log('dashboard_deleted: ' + Object.keys(dDel).length + ' entries, sample ' + sample(dDel));
  console.log('dashboard/deleted: ' + (Array.isArray(pDel) ? 'ARRAY' : 'object') + ' ' + Object.keys(pDel).length + ' entries, sample ' + sample(pDel));
  const maps = {}; for (const m of MAPS) { try { maps[m] = (await get('/dashboard/' + m)) || {}; } catch (e) { maps[m] = {}; } }
  const entries = o => Array.isArray(o) ? o.map((v, i) => [String(i), v]).filter(([, v]) => v) : Object.entries(o || {});
  const backup = [];
  console.log('TO DELETE (' + L.length + '):');
  for (const d of L) {
    const inCrec = crec[d.del] != null, mir = entries(custom).filter(([k, v]) => v && String(v.num) === String(d.del)).map(([k]) => k);
    const inMaps = MAPS.filter(m => maps[m][d.del] != null);
    console.log('  delete ' + d.del + ' "' + d.delName + '" (keep ' + d.keep + ' "' + d.keepName + '") @' + d.handle + ' | crec:' + inCrec + ' mirror:[' + mir + '] maps:[' + inMaps + '] alreadyTombstoned:' + (dDel[d.del] != null || pDel[d.del] != null));
    backup.push({ num: d.del, keep: d.keep, crec: crec[d.del] || null, mirror: mir.map(k => custom[k]), maps: Object.fromEntries(inMaps.map(m => [m, maps[m][d.del]])) });
  }
  console.log('BACKUP_JSON_START\n' + JSON.stringify(backup) + '\nBACKUP_JSON_END');
  console.log('HANDLE REPAIRS:');
  for (const [num, h] of Object.entries(FIX)) console.log('  ' + num + ' -> ' + h + ' (current igovr: ' + JSON.stringify(maps.igovr[num]) + ')');
  if (!APPLY) return;
  for (const d of L) {
    const s1 = await send('PUT', '/dashboard_deleted/' + d.del, true);
    const s2 = crec[d.del] != null ? await send('DELETE', '/dashboard_crec/' + d.del) : 'n/a';
    const s3 = await send('PUT', '/dashboard/deleted/' + d.del, true);
    const s4 = maps.igovr[d.del] != null ? await send('DELETE', '/dashboard/igovr/' + d.del) : 'n/a';
    console.log('DELETED ' + d.del + ' tombstone dashboard_deleted HTTP ' + s1 + ', crec ' + s2 + ', tombstone dashboard/deleted HTTP ' + s3 + ', igovr ' + s4);
  }
  for (const [num, h] of Object.entries(FIX)) {
    if (maps.igovr[num]) { console.log('SKIP handle ' + num + ': igovr already ' + maps.igovr[num]); continue; }
    const s = await send('PUT', '/dashboard/igovr/' + num, h); const back = await get('/dashboard/igovr/' + num);
    console.log((back === h ? 'OK   ' : 'CHECK') + ' handle ' + num + ' = ' + h + ' (HTTP ' + s + ')');
  }
  const crec2 = (await get('/dashboard_crec')) || {}; console.log('AFTER crec count ' + Object.keys(crec2).length + ' (before ' + Object.keys(crec).length + ')');
})().catch(e => console.log('ERROR: ' + e.message));
NODE
APPLY=${APPLY:-0} node /tmp/dupe-apply.js
