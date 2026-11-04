#!/bin/bash
# READ-ONLY count of what the database holds (counts only: no names, no emails, no contact details are printed). Only GET requests.
# Purpose: give Shane a verified number for "how many businesses does the CRM / outreach database track" for the website text.
set +e
cat > /tmp/count-db.js <<'NODE'
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
async function get(p) {
  const r = await fetch(DB + p + '.json', { signal: AbortSignal.timeout(90000) });
  if (!r.ok) throw new Error('GET ' + p + ' -> HTTP ' + r.status);
  return r.json();
}
const list = o => !o ? [] : Array.isArray(o) ? o.filter(Boolean) : Object.values(o).filter(Boolean);
const entries = o => !o ? [] : Array.isArray(o) ? o.map((v, i) => [String(i), v]).filter(([, v]) => v) : Object.entries(o).filter(([, v]) => v);
const numOf = (k, v) => (v && typeof v === 'object' && v.num != null) ? String(v.num) : k;
const hasIg = r => String((r && r.instagram) || '').trim().length > 0;
(async () => {
  console.log('DATABASE COUNT (read-only, counts only)');
  let top;
  try { top = await get('/?shallow=true'); } catch (e) { console.log('ABORT: ' + e.message); return; }
  const keys = Object.keys(top || {}).sort();
  console.log('top-level nodes: ' + keys.length);
  const sizes = [];
  for (const k of keys) {
    try {
      const s = await get('/' + encodeURIComponent(k) + '?shallow=true');
      const n = s && typeof s === 'object' ? Object.keys(s).length : (s == null ? 0 : 1);
      sizes.push([k, n]);
    } catch (e) { sizes.push([k, 'unreadable']); }
  }
  console.log('children per top-level node (name: count):');
  for (const [k, n] of sizes.sort((a, b) => (typeof b[1] === 'number' ? b[1] : -1) - (typeof a[1] === 'number' ? a[1] : -1))) console.log('  ' + k + ': ' + n);
  // restaurants: union of dashboard_crec and the dashboard/customrecords mirror, minus tombstoned numbers
  const [crec, custom, del1, del2] = await Promise.all([get('/dashboard_crec'), get('/dashboard/customrecords'), get('/dashboard/deleted'), get('/dashboard_deleted').catch(() => null)]);
  const deleted = new Set([...entries(del1).map(([k, v]) => numOf(k, v)), ...entries(del2).map(([k, v]) => numOf(k, v))]);
  const byNum = new Map();
  for (const [k, v] of [...entries(custom), ...entries(crec)]) { const n = numOf(k, v); if (!deleted.has(n)) byNum.set(n, v); }
  const rest = [...byNum.values()];
  console.log('\nRESTAURANTS (dashboard_crec + customrecords mirror, tombstoned removed): ' + rest.length + ' | with an Instagram handle: ' + rest.filter(hasIg).length);
  for (const [label, node] of [['experiences (dashboard_exp_crec)', '/dashboard_exp_crec'], ['advertisers approved (dashboard_adv_crec)', '/dashboard_adv_crec'], ['advertisers in staging (dashboard_adv_stg_crec)', '/dashboard_adv_stg_crec'], ['influencers (dashboard_infl_crec)', '/dashboard_infl_crec'], ['Key Technologies CRM prospects (kt_crm/prospects)', '/kt_crm/prospects'], ['website leads (key_leads/leads)', '/key_leads/leads']]) {
    try { const l = list(await get(node)); console.log(label + ': ' + l.length + (l.length && typeof l[0] === 'object' ? ' | with an Instagram handle: ' + l.filter(hasIg).length : '')); }
    catch (e) { console.log(label + ': ' + e.message); }
  }
  try {
    const idx = await get('/lvr_instagram_index?shallow=true');
    console.log('lvr_instagram_index (Instagram handle index): ' + (idx && typeof idx === 'object' ? Object.keys(idx).length : 0) + ' entries');
  } catch (e) { console.log('lvr_instagram_index: ' + e.message); }
  console.log('\nCOUNT DONE (nothing was changed).');
})().catch(e => console.log('ERROR: ' + e.message));
NODE
node /tmp/count-db.js
