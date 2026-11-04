#!/bin/bash
# READ-ONLY count of what the database holds (counts only: no names, no emails, no contact details are printed). Only GET requests.
# Purpose: give Shane a verified number for "how many businesses does the CRM / outreach database track" for the website text.
set +e
cat > /tmp/count-db.js <<'NODE'
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
async function get(p, q) {
  // Firebase REST form: <path>.json?<query>  (the root is /.json)
  const r = await fetch(DB + (p === '/' ? '/' : p) + '.json' + (q ? '?' + q : ''), { signal: AbortSignal.timeout(90000) });
  if (!r.ok) throw new Error('GET ' + p + ' -> HTTP ' + r.status);
  return r.json();
}
const list = o => !o ? [] : Array.isArray(o) ? o.filter(Boolean) : Object.values(o).filter(Boolean);
const entries = o => !o ? [] : Array.isArray(o) ? o.map((v, i) => [String(i), v]).filter(([, v]) => v) : Object.entries(o).filter(([, v]) => v);
const numOf = (k, v) => (v && typeof v === 'object' && v.num != null) ? String(v.num) : k;
const hasIg = r => String((r && r.instagram) || '').trim().length > 0;
(async () => {
  console.log('DATABASE COUNT (read-only, counts only)');
  // The database root cannot be listed (HTTP 401, which is the right setting), so count the known nodes one by one (keys only, no data).
  const KNOWN = ['dashboard_crec', 'dashboard_exp_crec', 'dashboard_adv_crec', 'dashboard_adv_stg_crec', 'dashboard_infl_crec', 'dashboard_rest_stg_crec', 'dashboard_deleted', 'kt_crm', 'key_leads', 'lvr_instagram_index', 'lvr_points', 'lvr_rewards', 'lvr_coupons'];
  console.log('children per known node (name: count):');
  for (const k of KNOWN) {
    try { const sh = await get('/' + k, 'shallow=true'); console.log('  ' + k + ': ' + (sh && typeof sh === 'object' ? Object.keys(sh).length : (sh == null ? 0 : 1))); }
    catch (e) { console.log('  ' + k + ': not readable (' + e.message.replace(/^GET \S+ -> /, '') + ')'); }
  }
  try {
    const dash = await get('/dashboard', 'shallow=true');
    const names = Object.keys(dash || {}).sort();
    console.log('\nchildren of /dashboard (' + names.length + ' lists), name: count:');
    for (const nme of names.slice(0, 70)) {
      try { const sh = await get('/dashboard/' + encodeURIComponent(nme), 'shallow=true'); console.log('  ' + nme + ': ' + (sh && typeof sh === 'object' ? Object.keys(sh).length : (sh == null ? 0 : 1))); }
      catch (e) { console.log('  ' + nme + ': not readable'); }
    }
  } catch (e) { console.log('/dashboard: ' + e.message); }
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
    const idx = await get('/lvr_instagram_index', 'shallow=true');
    console.log('lvr_instagram_index (Instagram handle index): ' + (idx && typeof idx === 'object' ? Object.keys(idx).length : 0) + ' entries');
  } catch (e) { console.log('lvr_instagram_index: ' + e.message); }
  console.log('\nCOUNT DONE (nothing was changed).');
})().catch(e => console.log('ERROR: ' + e.message));
NODE
node /tmp/count-db.js
