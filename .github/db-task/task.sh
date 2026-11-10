#!/bin/bash
# No task queued. (Last: read-only re-check 2026-11-10 23:23, run 497: strangers REFUSED (401) on key_leads, key_pageviews, kt_crm. Owner lockdown done. Script in git history, commit 9bc039d.)
# Prints: can an unauthenticated visitor list/read the database root? top-level node names, child counts, and the FIELD NAMES (not values) of one sample record per node,
# flagging fields that look like personal data. Never prints values of personal fields. Writes nothing.
set +e
cat > /tmp/probe.js <<'NODE'
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const get = async p => { const r = await fetch(DB + p, { signal: AbortSignal.timeout(60000) }); return { s: r.status, t: await r.text() }; };
const PII = /(email|e-mail|phone|mobile|tel|address|street|zip|dob|birth|password|pin|token|secret|ssn|card|name|ip\b|userAgent)/i;
(async () => {
  const NODES = ['ownerAuth/apiKey','key_leads','key_pageviews','kt_crm','lvr_rewards','lvr_points','key_rewards','dashboard','dashboard_crec','dashboard_adv_crec','dashboard_exp_crec','dashboard_infl_crec','dashboard_deleted','lvr_points/settings'];
  for (const k of NODES) {
    const sh = await get('/' + k + '.json?shallow=true');
    if (sh.s !== 200) { console.log(k + ': HTTP ' + sh.s + ' (stranger refused)'); continue; }
    let j; try { j = JSON.parse(sh.t); } catch (e) { j = null; }
    if (j === null) { console.log(k + ': stranger can read it; empty/missing'); continue; }
    if (typeof j !== 'object') { console.log(k + ': stranger can read it; scalar'); continue; }
    const ck = Object.keys(j); let fields = '';
    if (ck.length) {
      const one = await get('/' + k + '/' + encodeURIComponent(ck[0]) + '.json?shallow=true');
      try { const o = JSON.parse(one.t); if (o && typeof o === 'object') { const f = Object.keys(o).slice(0, 14); fields = ' | sample fields: ' + f.join(',') + (f.some(x => PII.test(x)) ? '  <-- PERSONAL-LOOKING FIELDS' : ''); } } catch (e) {}
    }
    console.log(k + ': STRANGER CAN READ it, ' + ck.length + ' children' + fields);
  }
})().catch(e => console.log('ERROR ' + e.message));
NODE
node /tmp/probe.js
