#!/bin/bash
# READ-ONLY audit 10 (state of the live dashboard after the 37 handle adds: Need to DM list, duplicate handles, handle format) (Shane, 2026-11-09: "re-run the needs-a-DM check"). Runs the REAL live dashboard (now v474, which lists all records) in a throwaway headless Chromium with the
# live data, every write blocked (only GET/HEAD allowed, Firebase SDK and websockets blocked), unlocked WITHOUT a PIN by calling the page's own unlock function. Reports the
# page's own badges (Total, Need to DM) and, for the 196 records that used to be hidden (num 50802 and up), how many are DM-able, already DM'd, flagged bad IG, or have no
# Instagram handle (those can never show as needing a DM, standing rule 10). Nothing is written anywhere.
set +e
mkdir -p /tmp/pw && cd /tmp/pw && npm init -y >/dev/null 2>&1 && npm i playwright@1.49.1 >/dev/null 2>&1
npx playwright install chromium >/tmp/pwinstall.log 2>&1; tail -1 /tmp/pwinstall.log
cat > /tmp/pw/audit13.js <<'NODE'
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
    const out = {}; out.version = typeof APP_VERSION !== 'undefined' ? APP_VERSION : null;
    out.badges = [].map.call(document.querySelectorAll('.badge'), x => x.textContent.replace(/\s+/g, ' ').trim()).slice(0, 8);
    const dhs = _dmdHandleSet(); const R = RESTAURANTS.filter(x => !x._isStaging); out.total = R.length;
    const cls = x => { const n = x.num; if (dmMap[n] && dmMap[n] !== 'pending') return 'alreadyDM'; if (badIGMap[n]) return 'badIG'; if (!x.igHandle) return 'noIG'; if (dhs[_igKey(x)] && !dmMap[n]) return 'dupHandleDMd'; return 'needsDM'; };
    out.tally = R.reduce((a, x) => { const c = cls(x); a[c] = (a[c] || 0) + 1; return a; }, {});
    
    const by = {}; R.forEach(x => { const k = _igKey(x); if (k) (by[k] = by[k] || []).push(x.num + ' ' + String(x.name).slice(0, 20) + ' [' + cls(x) + ']'); });
    out.dupHandles = Object.entries(by).filter(([k, v]) => v.length > 1).map(([k, v]) => '@' + k + ': ' + v.join(' | '));
    out.badFormat = R.filter(x => x.igHandle && !/^[A-Za-z0-9._]{1,30}$/.test(x.igHandle)).map(x => x.num + ' ' + x.igHandle);
    out.noIGbyClass = R.filter(x => !x.igHandle).reduce((a, x) => { const k = badIGMap[x.num] ? 'flaggedBad' : 'unflagged'; a[k] = (a[k] || 0) + 1; return a; }, {});
    return out; });
  console.log('AUDIT13 ' + JSON.stringify(r, null, 1));
  console.log('page errors: ' + JSON.stringify(errs.slice(0, 4)) + ' | blocked requests: ' + blocked);
  await b.close();
})().catch(e => console.log('ERROR ' + (e.stack || e.message).slice(0, 500)));
NODE
node /tmp/pw/audit13.js
