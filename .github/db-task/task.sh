#!/bin/bash
# READ-ONLY: is the new visitor counter recording? Prints counts and times only (no personal data exists in these records).
set +e
cat > /tmp/pvcheck.js <<'NODE'
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com/key_pageviews';
const get = async p => { const r = await fetch(DB + p + '.json'); if (!r.ok) throw new Error(p + ' HTTP ' + r.status); return r.json(); };
(async () => {
  const hits = (await get('/hits')) || {}, evs = (await get('/events')) || {};
  const rows = []; let old = 0, neu = 0;
  for (const [page, o] of Object.entries(hits)) for (const r of Object.values(o || {})) { if (!r || typeof r.t !== 'number') continue; rows.push({ page, t: r.t, neu: !!r.v }); r.v ? neu++ : old++; }
  rows.sort((a, b) => b.t - a.t);
  console.log('page-view records: ' + rows.length + ' (from the new counter: ' + neu + ', older plain counter: ' + old + ')');
  console.log('newest view: ' + (rows[0] ? new Date(rows[0].t).toISOString() + ' on ' + rows[0].page : 'none'));
  const since = Date.now() - 24 * 3600e3;
  console.log('views in the last 24 h: ' + rows.filter(r => r.t >= since).length);
  const byKind = {}; for (const e of Object.values(evs)) if (e && e.k) byKind[e.k] = (byKind[e.k] || 0) + 1;
  console.log('events by kind (d=time/scroll, c=click, l=form sent, n=page not found): ' + JSON.stringify(byKind));
  const top = {}; rows.forEach(r => top[r.page] = (top[r.page] || 0) + 1);
  console.log('views by page: ' + JSON.stringify(Object.entries(top).sort((a, b) => b[1] - a[1]).slice(0, 15)));
  console.log('CHECK DONE (nothing was changed)');
})().catch(e => console.log('ERROR: ' + e.message));
NODE
node /tmp/pvcheck.js
