#!/bin/bash
# READ-ONLY audit 4 (Shane, 2026-11-09: his Mac shows Total 1585; the database arithmetic gives 1,781). Runs the REAL live dashboard page in a throwaway
# headless Chromium with the live data, with EVERY write blocked (only GET/HEAD allowed, Firebase SDK and websockets blocked), unlocks it WITHOUT any PIN
# by calling the page's own unlock function in the throwaway browser, and reports how the page itself arrives at its Total. Nothing is written anywhere.
set +e
mkdir -p /tmp/pw && cd /tmp/pw && npm init -y >/dev/null 2>&1 && npm i playwright@1.49.1 >/dev/null 2>&1
npx playwright install chromium >/tmp/pwinstall.log 2>&1; tail -1 /tmp/pwinstall.log
cat > /tmp/pw/audit4.js <<'NODE'
const pw = require('/tmp/pw/node_modules/playwright');
(async () => {
  const b = await pw.chromium.launch(); const ctx = await b.newContext({ viewport: { width: 1280, height: 900 } });
  let blocked = 0, allowedGets = 0;
  await ctx.route('**/*', route => {
    const r = route.request(), m = r.method(), u = r.url();
    if (m !== 'GET' && m !== 'HEAD') { blocked++; console.log('BLOCKED ' + m + ' ' + u.slice(0, 110)); return route.abort(); }
    if (/gstatic\.com\/firebasejs|firebaseapp\.com|googleapis\.com\/identitytoolkit|securetoken/.test(u)) { blocked++; return route.abort(); }
    allowedGets++; return route.continue();
  });
  await ctx.routeWebSocket && ctx.routeWebSocket(/.*/, ws => ws.close());
  const p = await ctx.newPage(); const errs = [];
  p.on('pageerror', e => errs.push(String(e).slice(0, 160)));
  await p.goto('https://lvr-data-a60c1.web.app/', { waitUntil: 'load', timeout: 90000 }); await p.waitForTimeout(3000);
  await p.evaluate(() => { try { _coEditor = false; _applyCoEditorDmKey(); } catch (e) {} _bioUnlock(); });
  for (const t of [4000, 8000, 12000]) {
    await p.waitForTimeout(4000);
    const r = await p.evaluate(() => {
      const num = x => String(x.num), dm = typeof deletedMap !== 'undefined' ? deletedMap : {};
      const base = typeof RESTAURANTS_BASE !== 'undefined' ? RESTAURANTS_BASE : [];
      const R = typeof RESTAURANTS !== 'undefined' ? RESTAURANTS : [];
      const seen = {}; let dup = 0; R.forEach(x => { const k = num(x); if (seen[k]) dup++; seen[k] = 1; });
      const cr = typeof customRecords !== 'undefined' ? customRecords : [];
      const bn = new Set(base.map(num));
      return { sTotalBadge: (document.getElementById('s-total') || {}).textContent, RESTAURANTS: R.length, staging: R.filter(x => x._isStaging).length, duplicateNumsInRESTAURANTS: dup,
        RESTAURANTS_BASE: base.length, customRecords: cr.length, deletedMapKeys: Object.keys(dm).filter(k => dm[k]).length,
        baseTombstoned: base.filter(x => dm[x.num]).length, customTombstoned: cr.filter(x => x && dm[x.num]).length,
        customNumsAlsoInBase: cr.filter(x => x && bn.has(num(x))).length, customWithoutNum: cr.filter(x => !x || x.num == null).length,
        crecLoaded: typeof _prCrec !== 'undefined' && _prCrec ? Object.keys(_prCrec).length : 'n/a', fbStatus: (document.getElementById('fb-msg') || {}).textContent };
    });
    console.log('after ' + t + 'ms: ' + JSON.stringify(r));
  }
  console.log('page errors: ' + JSON.stringify(errs.slice(0, 6)) + ' | blocked requests: ' + blocked + ' | allowed GETs: ' + allowedGets);
  await b.close();
})().catch(e => console.log('ERROR ' + (e.stack || e.message).slice(0, 400)));
NODE
node /tmp/pw/audit4.js
