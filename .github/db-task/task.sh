#!/bin/bash
# Verify the latest Mac deploy actually shipped each change (marker checks on live pages).
set -e
node <<'NODE'
const https = require('https');
const get = url => new Promise(res => https.get(url, { timeout: 20000 }, r => { let d=''; r.on('data', c => d += c); r.on('end', () => res({ s: r.statusCode, b: d })); }).on('error', e => res({ s: String(e.message), b: '' })));
const L = 'https://lvr-data-a60c1.web.app/';
const checks = [
  [L, 'dashboard: version', /APP_VERSION=(\d+)/, null],
  [L, 'dashboard: Key Tech pill', /KEYROOM-PILL-v1/, null],
  [L, 'dashboard: member-link button', /KEYROOM-MEMBERLINK-v1/, null],
  [L, 'dashboard: "Award Points" wording', /Award Points/, null],
  [L + 'lvr-points-admin.html', 'points admin: Receipts + Businesses + Earnings tabs', /data-v="receipts"[\s\S]*data-v="restaurants">Businesses[\s\S]*data-v="earnings"/, null],
  [L + 'lvr-points-admin.html', 'points admin: delete photos', /delphotos/, null],
  [L + 'lvr-restaurant-portal.html', 'restaurant portal: code check + mark used', /lookupBtn[\s\S]*markUsed/, null],
  [L + 'lvr-coupons-admin.html', 'coupon admin: restaurant code field', /fFixedCode/, null],
  [L + 'lvr-coupon.html', 'coupon claim page', /program\.fixedCode/, null],
  [L + 'lvr-rewards.html', 'sign-up page: contact form', /id="contactForm"/, null],
  [L + 'lvr-rewards.html', 'sign-up page: owner email removed', /mailto:/, 'ABSENT'],
  [L + 'lvr-wallet.html', 'old wallet page redirects', /keytechnologies\.si\/my-account/, null],
  [L + 'key-leads.html', 'key leads: LVR Rewards tab', /lvr-rewards-contact/, null],
  [L + 'key-room.html', 'key room hub', /Points Program/, null],
  ['https://keytechnologies.si/my-account.html', 'KT account page: two-photo receipts', /ePhotoClose/, null],
  ['https://keytechnologies.si/', 'KT home: See it working block', /class="proof"/, null],
];
(async () => {
  const cache = {};
  for (const [url, label, re, mode] of checks) {
    cache[url] = cache[url] || await get(url);
    const r = cache[url]; const m = re.exec(r.b || '');
    const ok = mode === 'ABSENT' ? !m : !!m;
    console.log((ok ? 'PASS' : 'FAIL') + '  ' + label + (m && m[1] ? ' (' + m[1] + ')' : '') + (r.s !== 200 ? '  [HTTP ' + r.s + ']' : ''));
  }
})();
NODE
