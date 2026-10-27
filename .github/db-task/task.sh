#!/bin/bash
# (1) Read the read-only Firebase inventory the owner ran on the Mac.
# (2) Verify the latest deploy shipped the safety switches / receipt archive.
set -e
node <<'NODE'
const https = require('https');
const get = url => new Promise(res => https.get(url, { timeout: 20000 }, r => { let d=''; r.on('data', c => d += c); r.on('end', () => res({ s: r.statusCode, b: d })); }).on('error', e => res({ s: String(e.message), b: '' })));
(async () => {
  console.log('===== FIREBASE INVENTORY =====');
  const r = await get('https://lvr-data-a60c1-default-rtdb.firebaseio.com/_debug/recon.json');
  try { console.log(JSON.parse(r.b)); } catch (e) { console.log('no inventory found (status ' + r.s + ')'); }

  console.log('\n===== DEPLOY CHECK =====');
  const L = 'https://lvr-data-a60c1.web.app/';
  const checks = [
    [L, 'dashboard version', /APP_VERSION=(\d+)/, null],
    [L + 'lvr-points-admin.html', 'admin: Audit + Settings tabs', /data-v="audit"[\s\S]*data-v="settings"/, null],
    [L + 'lvr-points-admin.html', 'admin: Delete photos button is GONE', /Delete photos/, 'ABSENT'],
    [L + 'lvr-points-admin.html', 'admin: pause switches', /sPauseSignups/, null],
    [L + 'lvr-points-admin.html', 'admin: referral payout code', /applyReferrals/, null],
    [L + 'lvr-restaurant-portal.html', 'portal: verified receipts + flag', /Receipts verified for your restaurant[\s\S]*flagReceipt/, null],
    [L + 'lvr-rewards.html', 'LVR sign-up: pause support + referral', /signupsPaused[\s\S]*refCode/, null],
    [L + 'lvr-coupon.html', 'coupon page: Built by footer', /kt-built-by/, null],
    [L + 'key-room.html', 'key room: Built by footer', /kt-built-by/, null],
    ['https://keytechnologies.si/my-account.html', 'KT account: emailed receipts + receipt date', /eType[\s\S]*eDate/, null],
    ['https://keytechnologies.si/my-account.html', 'KT account: referral card off by default', /enabled: false, l1Pct/, null],
    ['https://keytechnologies.si/rewards.html', 'KT sign-up: waitlist when paused', /showWaitlist/, null],
    ['https://keytechnologies.si/privacy.html', 'KT privacy page: Built by footer', /kt-built-by/, null],
  ];
  const cache = {};
  for (const [url, label, re, mode] of checks) {
    cache[url] = cache[url] || await get(url);
    const m = re.exec(cache[url].b || '');
    const ok = mode === 'ABSENT' ? !m : !!m;
    console.log((ok ? 'PASS' : 'FAIL') + '  ' + label + (m && m[1] ? ' (' + m[1] + ')' : '') + (cache[url].s !== 200 ? '  [HTTP ' + cache[url].s + ']' : ''));
  }
})();
NODE
