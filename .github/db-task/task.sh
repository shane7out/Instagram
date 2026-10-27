#!/bin/bash
# Live-verify the marketplace demo page and the restaurant-only member app.
set -e
node <<'NODE'
const https = require('https');
const get = url => new Promise(res => https.get(url, { timeout: 15000 }, r => { let d=''; r.on('data', c => d += c); r.on('end', () => res({ s: r.statusCode, b: d })); }).on('error', e => res({ s: e.message, b: '' })));
(async () => {
  const m = await get('https://keytechnologies.si/marketplace-demo.html');
  console.log('marketplace-demo.html:', m.s, '| has LVR mode:', m.b.includes('modeLvr'), '| noindex:', m.b.includes('noindex'));
  const a = await get('https://keytechnologies.si/my-account.html');
  console.log('my-account.html:', a.s, '| has restaurant lock:', a.b.includes("VERTICAL = 'restaurants'"), '| has receipt form:', a.b.includes('earnCard'));
})();
NODE
