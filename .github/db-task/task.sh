#!/bin/bash
# ONE-SHOT (Shane, 2026-11-05: "I don't need the old records kept"): delete the page-view records saved by the OLD plain counter
# (before the new counter went live at 2026-11-05 21:09 UTC and without the new "v" field). New-counter records and all events
# are never touched. Safe-guards: aborts if it would delete more than 400 records; reads the node back to verify.
set +e
cat > /tmp/pvclean.js <<'NODE'
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com/key_pageviews';
const LAUNCH = Date.UTC(2026, 10, 5, 21, 9, 0);
const get = async p => { const r = await fetch(DB + p + '.json'); if (!r.ok) throw new Error(p + ' HTTP ' + r.status); return r.json(); };
(async () => {
  const hits = (await get('/hits')) || {};
  const del = [], keep = [];
  for (const [page, o] of Object.entries(hits)) for (const [id, r] of Object.entries(o || {})) {
    const old = !r || typeof r.t !== 'number' || (r.t < LAUNCH && !r.v);
    (old ? del : keep).push(page + '/' + id);
  }
  console.log('records: ' + (del.length + keep.length) + ' | old (to delete): ' + del.length + ' | new counter (kept): ' + keep.length);
  if (del.length > 400) { console.log('ABORT: more than 400 to delete, expected about 134. Nothing deleted.'); return; }
  let ok = 0, bad = 0;
  for (let i = 0; i < del.length; i += 10) {
    const res = await Promise.all(del.slice(i, i + 10).map(k => fetch(DB + '/hits/' + k + '.json', { method: 'DELETE' }).then(r => r.status)));
    res.forEach(s => s === 200 ? ok++ : bad++);
  }
  console.log('deleted: ' + ok + ' | failed: ' + bad);
  const after = (await get('/hits')) || {}; let n = 0, old = 0;
  for (const o of Object.values(after)) for (const r of Object.values(o || {})) { n++; if (!r || (r.t < LAUNCH && !r.v)) old++; }
  console.log('AFTER: ' + n + ' page-view records left, old ones left: ' + old + ' (should be 0)');
  const ev = (await get('/events')) || {}; console.log('events untouched: ' + Object.keys(ev).length);
})().catch(e => console.log('ERROR: ' + e.message));
NODE
node /tmp/pvclean.js
