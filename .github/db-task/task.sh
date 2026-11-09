#!/bin/bash
# READ-ONLY (2026-11-09): did Shane's Mac run of deploy-fix-customrecords-nulls.sh finish? Reads _debug/diag.json (the log the script posts) and checks the live page for
# the marker CRNULL01 and its version. GET only. Nothing is written.
set +e
cat > /tmp/chk.js <<'NODE'
(async () => {
  const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
  try { const d = await (await fetch(DB + '/_debug/diag.json', { cache: 'no-store' })).json(); console.log('--- _debug/diag.json (last log the Mac script posted) ---\n' + String(d).slice(-3500)); } catch (e) { console.log('diag read failed ' + e.message); }
  try { const r = await fetch('https://lvr-data-a60c1.web.app/?t=' + Date.now(), { cache: 'no-store' }); const t = await r.text(); console.log('--- live page ---\nHTTP ' + r.status + ' | version ' + ((t.match(/APP_VERSION\s*=\s*(\d+)/) || [])[1]) + ' | CRNULL01 marker count ' + (t.match(/CRNULL01/g) || []).length); } catch (e) { console.log('live read failed ' + e.message); }
  try { console.log('version.json -> ' + await (await fetch('https://lvr-data-a60c1.web.app/version.json?t=' + Date.now(), { cache: 'no-store' })).text()); } catch (e) {}
})();
NODE
node /tmp/chk.js
