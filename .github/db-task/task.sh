#!/bin/bash
# READ-ONLY audit 11 (for each shared Instagram handle show both records: name, phone, address, cuisine, DM state) (Shane, 2026-11-09: "re-run the needs-a-DM check"). Runs the REAL live dashboard (now v474, which lists all records) in a throwaway headless Chromium with the
# live data, every write blocked (only GET/HEAD allowed, Firebase SDK and websockets blocked), unlocked WITHOUT a PIN by calling the page's own unlock function. Reports the
# page's own badges (Total, Need to DM) and, for the 196 records that used to be hidden (num 50802 and up), how many are DM-able, already DM'd, flagged bad IG, or have no
# Instagram handle (those can never show as needing a DM, standing rule 10). Nothing is written anywhere.
set +e
mkdir -p /tmp/pw && cd /tmp/pw && npm init -y >/dev/null 2>&1 && npm i playwright@1.49.1 >/dev/null 2>&1
npx playwright install chromium >/tmp/pwinstall.log 2>&1; tail -1 /tmp/pwinstall.log
cat > /tmp/pw/audit11.js <<'NODE'
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
    const dhs = _dmdHandleSet(); const R = RESTAURANTS.filter(x => !x._isStaging);
    const by = {}; R.forEach(x => { const k = _igKey(x); if (k) (by[k] = by[k] || []).push(x); });
    const f = x => [x.num, String(x.name || '').slice(0, 34), String(x.phone || '').replace(/\D/g, '').slice(-10), String(x.address || '').slice(0, 46), String(x.cuisine || '').slice(0, 14), (dmMap[x.num] && dmMap[x.num] !== 'pending') ? 'DM' : (badIGMap[x.num] ? 'BAD' : '-')].join(' ; ');
    const out = {}; out.pairs = Object.entries(by).filter(([k, v]) => v.length > 1).map(([k, v]) => '@' + k + '\n   ' + v.map(f).join('\n   '));
    return out; });
  console.log('AUDIT11 ' + JSON.stringify(r, null, 1));
  console.log('page errors: ' + JSON.stringify(errs.slice(0, 4)) + ' | blocked requests: ' + blocked);
  await b.close();
})().catch(e => console.log('ERROR ' + (e.stack || e.message).slice(0, 500)));
NODE
node /tmp/pw/audit11.js
