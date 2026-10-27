#!/bin/bash
# Scan live public pages for the owner's email address (counts only - the
# address itself is never printed, this repo's logs are public).
set -e
node <<'NODE'
const https = require('https');
const get = url => new Promise(res => https.get(url, { timeout: 15000 }, r => { let d=''; r.on('data', c => d += c); r.on('end', () => res({ s: r.statusCode, b: d })); }).on('error', e => res({ s: String(e.message), b: '' })));
const pages = [
  'https://lvr-data-a60c1.web.app/', 'https://lvr-data-a60c1.web.app/lvr-rewards.html', 'https://lvr-data-a60c1.web.app/lvr-teams.html',
  'https://lvr-data-a60c1.web.app/lvr-coupon.html',
  'https://keytechnologies.si/', 'https://keytechnologies.si/rewards.html', 'https://keytechnologies.si/my-account.html',
  'https://keytechnologies.si/privacy.html', 'https://keytechnologies.si/terms.html', 'https://keytechnologies.si/law.html',
  'https://keytechnologies.si/marketplace-demo.html'
];
(async () => {
  for (const u of pages) {
    const r = await get(u);
    const b = r.b || '';
    const hits = (b.match(/lasvegasrestaurants\.net/gi) || []).length;
    const mailto = (b.match(/mailto:/gi) || []).length;
    console.log(u.replace('https://', ''), '| status', r.s, '| owner-domain mentions:', hits, '| mailto links:', mailto);
  }
})();
NODE
