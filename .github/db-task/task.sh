#!/bin/bash
# READ-ONLY diagnostic (Shane, 2026-11-08: the CRM PIN pad ignores taps on his iPhone). Loads the LIVE page in iPhone-style WebKit and Chromium,
# taps fake digits (1,2,3: never a real PIN), and reports dots filled, overlays over the keys, page errors, failed requests and version.json.
# Nothing is written to the database or to the live site.
set +e
mkdir -p /tmp/pw && cd /tmp/pw && npm init -y >/dev/null 2>&1 && npm i playwright@latest >/dev/null 2>&1; npx playwright --version; cat /etc/os-release | head -2
sudo apt-get update -y >/tmp/apt.log 2>&1; tail -2 /tmp/apt.log
npx playwright install-deps webkit >/tmp/pwdeps.log 2>&1; tail -3 /tmp/pwdeps.log
npx playwright install webkit >/tmp/pwinstall.log 2>&1; tail -3 /tmp/pwinstall.log
cat > /tmp/pw/diag.js <<'NODE'
const pw = require('/tmp/pw/node_modules/playwright');
const URL = 'https://lvr-data-a60c1.web.app/';
(async () => {
  try { const r = await fetch(URL + 'version.json?t=' + Date.now(), { cache: 'no-store' }); console.log('version.json -> HTTP ' + r.status + ' ' + (await r.text()).slice(0, 200)); } catch (e) { console.log('version.json failed ' + e.message); }
  for (const [label, type, devName] of [['iPhone WebKit', pw.webkit, 'iPhone 15'], ['iPhone-size Chromium', pw.chromium, 'iPhone 15'], ['Desktop Chromium', pw.chromium, null]]) {
    let b; try { b = await type.launch(); } catch (e) { console.log(label + ': cannot launch ' + e.message.slice(0, 120)); continue; }
    const ctx = await b.newContext(devName ? { ...pw.devices[devName] } : { viewport: { width: 1280, height: 800 } });
    const p = await ctx.newPage(); const errs = [], bad = [];
    p.on('pageerror', e => errs.push(String(e).slice(0, 200)));
    p.on('console', m => { if (m.type() === 'error') errs.push('console: ' + m.text().slice(0, 160)); });
    p.on('requestfailed', r => bad.push(r.url().slice(0, 90) + ' ' + (r.failure() || {}).errorText));
    p.on('response', r => { if (r.status() >= 400) bad.push(r.status() + ' ' + r.url().slice(0, 90)); });
    try {
      await p.goto(URL, { waitUntil: 'load', timeout: 60000 }); await p.waitForTimeout(4000);
      const info = await p.evaluate(() => {
        const k = document.querySelector('.pin-key'); const r = k && k.getBoundingClientRect(); let top = null;
        if (r) { const el = document.elementFromPoint(r.left + r.width / 2, r.top + r.height / 2); top = el ? (el.tagName + '#' + el.id + '.' + String(el.className).slice(0, 40)) : null; }
        return { pinVisible: !!document.getElementById('pin-screen') && !document.getElementById('pin-screen').classList.contains('hidden'), firstKeyTopElement: top, entryType: typeof _pinEntry, pinKeyType: typeof pinKey, version: typeof APP_VERSION !== 'undefined' ? APP_VERSION : null, locked: typeof _pinLocked !== 'undefined' ? _pinLocked : null };
      });
      console.log(label + ' state: ' + JSON.stringify(info));
      for (const d of ['1', '2', '3']) { try { if (devName) await p.tap('.pin-key:has-text("' + d + '")', { timeout: 5000 }); else await p.click('.pin-key:has-text("' + d + '")', { timeout: 5000 }); } catch (e) { console.log(label + ' tap ' + d + ' failed: ' + e.message.split('\n')[0].slice(0, 160)); } }
      await p.waitForTimeout(500);
      console.log(label + ': dots filled after tapping 1,2,3 = ' + await p.locator('.pin-dot.filled').count() + ' | entry now: ' + (await p.evaluate(() => typeof _pinEntry === 'string' ? _pinEntry.length + ' digits' : typeof _pinEntry)));
      if (label === 'iPhone WebKit') await p.screenshot({ path: '/tmp/pw/webkit.png' });
    } catch (e) { console.log(label + ' ERROR ' + e.message.split('\n')[0].slice(0, 200)); }
    console.log(label + ' page errors: ' + JSON.stringify(errs.slice(0, 8)));
    console.log(label + ' failed/4xx requests: ' + JSON.stringify(bad.slice(0, 10)));
    await b.close();
  }
})();
NODE
node /tmp/pw/diag.js
[ -f /tmp/pw/webkit.png ] && cp /tmp/pw/webkit.png /home/runner/work/Instagram/Instagram/.github/db-task/fetched/crm-pin-webkit.png
cd /home/runner/work/Instagram/Instagram 2>/dev/null || true
git config user.name "db-task-bot"; git config user.email "db-task-bot@users.noreply.github.com"
git add .github/db-task/fetched/crm-pin-webkit.png 2>/dev/null
if git diff --cached --quiet; then echo "nothing new to commit"; else git commit -m "fetch: CRM PIN screen as iPhone WebKit sees it (diagnostic)" && git push origin HEAD:claude/master-file-e6ofy0 && echo pushed; fi
