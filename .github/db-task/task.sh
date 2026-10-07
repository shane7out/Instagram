#!/bin/bash
# 3-hour check-in (2026-10-07 ~18:36 UTC). Holding off on the GitHub Pages /
# keytechnologies.si re-check this cycle since it's been identical ("404" /
# "000") across 4 straight checks - no reason to think it changed.
#
# New angle this cycle: proactively audit the standing DM-visibility rule
# (every new business must show up in the "needs DM" pill, not just "in the
# database") instead of waiting for Shane to notice a miss again like on
# 2026-10-05. Scans both live Firebase nodes for any record that would be
# silently invisible per the dashboard's own merge logic:
#   - dashboard_crec (restaurants): invisible if `num` is missing/null
#     (_prOnRemote only merges when r.num != null), or not DM-able if
#     `instagram` is empty (needsDM needs a derived igHandle).
#   - dashboard_adv_crec (advertisers): not DM-able if `ig` is empty
#     (separate field from restaurants - easy to miss).
set +e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

echo "=== DM-visibility health check ==="
curl -s "$DB/dashboard_crec.json" -o /tmp/crec.json --max-time 20
curl -s "$DB/dashboard_adv_crec.json" -o /tmp/adv_crec.json --max-time 20

node <<'NODE'
const fs = require('fs');
function load(p){ try { return JSON.parse(fs.readFileSync(p,'utf8')) || {}; } catch(e){ return {}; } }
const crec = load('/tmp/crec.json');
const advCrec = load('/tmp/adv_crec.json');

let noNum = [], noIg = [];
for (const [k,r] of Object.entries(crec)) {
  if (!r || typeof r !== 'object') continue;
  if (r.num === null || r.num === undefined) noNum.push(r.name || k);
  else if (!r.instagram || !String(r.instagram).trim()) noIg.push(r.name || k);
}
let advNoIg = [];
for (const [k,r] of Object.entries(advCrec)) {
  if (!r || typeof r !== 'object') continue;
  if (!r.ig || !String(r.ig).trim()) advNoIg.push(r.name || k);
}

console.log('restaurants in dashboard_crec: ' + Object.keys(crec).length);
console.log('  -> missing num (INVISIBLE, not just non-DM-able): ' + noNum.length + (noNum.length ? ' : ' + noNum.join(', ') : ''));
console.log('  -> has num but no instagram (visible, never DM-able): ' + noIg.length + (noIg.length ? ' : ' + noIg.join(', ') : ''));
console.log('advertisers in dashboard_adv_crec: ' + Object.keys(advCrec).length);
console.log('  -> missing ig (never DM-able): ' + advNoIg.length + (advNoIg.length ? ' : ' + advNoIg.join(', ') : ''));

const dirty = noNum.length || noIg.length || advNoIg.length;
console.log('\nRESULT: ' + (dirty ? 'ISSUES FOUND - see above' : 'all clean, nothing silently missing the DM queue'));
NODE
