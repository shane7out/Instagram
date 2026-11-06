#!/bin/bash
# ONE-SHOT (Shane, 2026-11-06: "take those 3 restaurants off the list so that they're deleted"): remove the three restaurants that are
# tombstoned (already in dashboard/deleted) but still live: #50801 Shook Shakery, #50809 CC Speakeasy, #50913 Oodle Noodle.
# Removes ONLY their live record in dashboard_crec and their copy in the dashboard/customrecords mirror. Tombstones, status and
# attempts entries are left alone. Safe-guards: each record's name must match; each must be tombstoned; nothing else is touched.
set +e
cat > /tmp/remove3.js <<'NODE'
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const get = async p => { const r = await fetch(DB + p + '.json'); if (!r.ok) throw new Error(p + ' HTTP ' + r.status); return r.json(); };
const del = async p => (await fetch(DB + p + '.json', { method: 'DELETE' })).status;
const WANT = { '50801': /shook\s*shak/i, '50809': /cc\s*speakeasy/i, '50913': /oodle\s*noodle/i };
const entries = o => !o ? [] : Array.isArray(o) ? o.map((v, i) => [String(i), v]).filter(([, v]) => v) : Object.entries(o).filter(([, v]) => v);
(async () => {
  const [crec, custom, deleted] = await Promise.all([get('/dashboard_crec'), get('/dashboard/customrecords'), get('/dashboard/deleted')]);
  const tomb = new Set(entries(deleted).map(([k, v]) => (v && typeof v === 'object' && v.num != null) ? String(v.num) : k));
  console.log('before: dashboard_crec ' + entries(crec).length + ' | mirror ' + entries(custom).length + ' | tombstones ' + tomb.size);
  for (const [num, rx] of Object.entries(WANT)) {
    const liveKeys = entries(crec).filter(([k, v]) => String((v && v.num != null) ? v.num : k) === num);
    const mirrorKeys = entries(custom).filter(([k, v]) => String((v && v.num != null) ? v.num : k) === num);
    const name = liveKeys.length ? String(liveKeys[0][1].name || '') : (mirrorKeys.length ? String(mirrorKeys[0][1].name || '') : '');
    if (!tomb.has(num)) { console.log('SKIP #' + num + ': not tombstoned, leaving it alone'); continue; }
    if (name && !rx.test(name)) { console.log('SKIP #' + num + ': name "' + name + '" is not the expected one'); continue; }
    for (const [k] of liveKeys) console.log('#' + num + ' ' + name + ': delete dashboard_crec/' + k + ' -> HTTP ' + await del('/dashboard_crec/' + encodeURIComponent(k)));
    for (const [k] of mirrorKeys) console.log('#' + num + ' ' + name + ': delete dashboard/customrecords/' + k + ' -> HTTP ' + await del('/dashboard/customrecords/' + encodeURIComponent(k)));
    if (!liveKeys.length && !mirrorKeys.length) console.log('#' + num + ': nothing live to remove');
  }
  const [crec2, custom2] = await Promise.all([get('/dashboard_crec'), get('/dashboard/customrecords')]);
  const still = Object.keys(WANT).filter(n => entries(crec2).some(([k, v]) => String((v && v.num != null) ? v.num : k) === n) || entries(custom2).some(([k, v]) => String((v && v.num != null) ? v.num : k) === n));
  console.log('after: dashboard_crec ' + entries(crec2).length + ' | mirror ' + entries(custom2).length + ' | of the three, still live: ' + (still.length ? still.join(', ') : 'none'));
  console.log('DONE');
})().catch(e => console.log('ERROR: ' + e.message));
NODE
node /tmp/remove3.js
