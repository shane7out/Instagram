#!/bin/bash
# READ-ONLY security probe (Shane, 2026-11-10: deep audit incl. security). Uses only GET with NO credentials, exactly what any stranger on the internet could do.
# Prints: can an unauthenticated visitor list/read the database root? top-level node names, child counts, and the FIELD NAMES (not values) of one sample record per node,
# flagging fields that look like personal data. Never prints values of personal fields. Writes nothing.
set +e
cat > /tmp/probe.js <<'NODE'
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const get = async p => { const r = await fetch(DB + p, { signal: AbortSignal.timeout(60000) }); return { s: r.status, t: await r.text() }; };
const PII = /(email|e-mail|phone|mobile|tel|address|street|zip|dob|birth|password|pin|token|secret|ssn|card|name|ip\b|userAgent)/i;
(async () => {
  const root = await get('/.json?shallow=true');
  console.log('ROOT shallow read (no credentials): HTTP ' + root.s + (root.s === 200 ? ' -> PUBLICLY LISTABLE' : ' -> denied'));
  if (root.s !== 200) return;
  const keys = Object.keys(JSON.parse(root.t) || {}).sort();
  console.log('top-level nodes (' + keys.length + '): ' + keys.join(', '));
  for (const k of keys) {
    const sh = await get('/' + encodeURIComponent(k) + '.json?shallow=true');
    if (sh.s !== 200) { console.log('  ' + k + ': HTTP ' + sh.s); continue; }
    let j; try { j = JSON.parse(sh.t); } catch (e) { j = null; }
    if (j === null) { console.log('  ' + k + ': empty'); continue; }
    if (typeof j !== 'object') { console.log('  ' + k + ': scalar'); continue; }
    const ck = Object.keys(j); let fields = '';
    if (ck.length) {
      const one = await get('/' + encodeURIComponent(k) + '/' + encodeURIComponent(ck[0]) + '.json?shallow=true');
      try { const o = JSON.parse(one.t); if (o && typeof o === 'object') { const f = Object.keys(o).slice(0, 14); fields = ' | sample fields: ' + f.join(',') + (f.some(x => PII.test(x)) ? '  <-- PERSONAL-LOOKING FIELDS' : ''); } } catch (e) {}
    }
    console.log('  ' + k + ': ' + ck.length + ' children' + fields);
  }
})().catch(e => console.log('ERROR ' + e.message));
NODE
node /tmp/probe.js
