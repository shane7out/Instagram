#!/bin/bash
# READ-ONLY audit 5 (Shane, 2026-11-09: Rebellion Market (num 60063, added today) is not visible in his dashboard; Total still ~1585). Runs the REAL live dashboard
# in a throwaway headless Chromium WITH the live Firebase sync, but every non-GET HTTP request is blocked and every WebSocket frame from the page to Firebase is
# DROPPED unless it is a plain listen/unlisten request (a:"q"/"n") or a keep-alive, so nothing can be written. No PIN is used (the page's own unlock function is
# called). Reports the Total over time and whether the newest records (Significant Other 60062, Rebellion Market 60063) are in the page's list.
set +e
mkdir -p /tmp/pw && cd /tmp/pw && npm init -y >/dev/null 2>&1 && npm i playwright@1.49.1 >/dev/null 2>&1
npx playwright install chromium >/tmp/pwinstall.log 2>&1; tail -1 /tmp/pwinstall.log
cat > /tmp/pw/audit5.js <<'NODE'
const pw = require('/tmp/pw/node_modules/playwright');
(async () => {
  const b = await pw.chromium.launch(); const ctx = await b.newContext({ viewport: { width: 1280, height: 900 } });
  let blockedHttp = 0, passedFrames = 0, droppedFrames = 0; const droppedKinds = {};
  await ctx.route('**/*', route => {
    const r = route.request(), m = r.method(), u = r.url();
    if (m !== 'GET' && m !== 'HEAD') { blockedHttp++; return route.abort(); }
    if (/\.lp\?|firebaseio\.com\/\.lp/.test(u)) { blockedHttp++; return route.abort(); } // no long-polling (it can carry writes in GET params)
    return route.continue();
  });
  const SAFE = /^\{"t":"d","d":\{"r":\d+,"a":"[qn]","b":\{"p":"[^"]*"(,"h":"[^"]*")?(,"q":\{[^}]*\})?\}\}\}$/;
  await ctx.routeWebSocket(/firebaseio\.com/, ws => {
    const server = ws.connectToServer();
    ws.onMessage(msg => { const s = typeof msg === 'string' ? msg : ''; if (s === '0' || SAFE.test(s)) { passedFrames++; server.send(msg); } else { droppedFrames++; const k = (s.match(/"a":"(\w+)"/) || [0, s.slice(0, 12)])[1]; droppedKinds[k] = (droppedKinds[k] || 0) + 1; } });
    server.onMessage(msg => ws.send(msg));
    ws.onClose(() => server.close()); server.onClose(() => ws.close());
  });
  const p = await ctx.newPage(); const errs = []; const reqs = [];
  p.on('requestfailed', r => reqs.push('FAILED ' + r.method() + ' ' + r.url().slice(0, 100) + ' ' + ((r.failure() || {}).errorText || '')));
  p.on('response', async r => { if (/firebaseio\.com\/dashboard\.json/.test(r.url())) { let n = -1; try { n = (await r.body()).length; } catch (e) {} reqs.push('RESPONSE ' + r.status() + ' ' + r.url().slice(0, 90) + ' bytes=' + n); } });
  p.on('pageerror', e => errs.push(String(e).slice(0, 160)));
  await p.goto('https://lvr-data-a60c1.web.app/', { waitUntil: 'load', timeout: 90000 }); await p.waitForTimeout(3000);
  await p.evaluate(() => { try { _coEditor = false; _applyCoEditorDmKey(); } catch (e) {} _bioUnlock(); });
  for (const t of [5, 10, 20, 30]) {
    await p.waitForTimeout(t === 5 ? 5000 : t === 10 ? 5000 : 10000);
    const r = await p.evaluate(() => {
      const find = (re) => RESTAURANTS.filter(x => re.test(String(x.name))).map(x => x.num + ' ' + String(x.name).slice(0, 40));
      return { sTotalBadge: (document.getElementById('s-total') || {}).textContent, RESTAURANTS: RESTAURANTS.length, customRecords: customRecords.length, crecLoaded: typeof _prCrec !== 'undefined' && _prCrec ? Object.keys(_prCrec).length : 'none', prOn: typeof _prOn === 'function' ? _prOn() : 'n/a', initialLoadDone: typeof _fbInitialLoadDone !== 'undefined' ? _fbInitialLoadDone : 'n/a', significantInList: find(/significant other/i), rebellionInList: find(/rebellion market/i), fbStatus: (document.getElementById('fb-msg') || {}).textContent };
    });
    console.log('after ' + t + 's: ' + JSON.stringify(r));
  }
  console.log('dashboard.json requests: ' + JSON.stringify(reqs.slice(0, 12)));
  console.log('page errors: ' + JSON.stringify(errs.slice(0, 5)) + ' | blocked HTTP writes: ' + blockedHttp + ' | websocket frames passed (listen/keep-alive only): ' + passedFrames + ' | dropped: ' + droppedFrames + ' ' + JSON.stringify(droppedKinds));
  await b.close();
})().catch(e => console.log('ERROR ' + (e.stack || e.message).slice(0, 500)));
NODE
node /tmp/pw/audit5.js
