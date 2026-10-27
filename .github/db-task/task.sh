#!/bin/bash
# Check whether the deploy-key-room.sh Mac script has run yet.
set -e
node <<'NODE'
const https = require('https');
function get(url, timeoutMs) {
  return new Promise((resolve) => {
    const req = https.get(url, { timeout: timeoutMs || 15000 }, r => {
      let d = ''; r.on('data', c => d += c); r.on('end', () => resolve({ status: r.statusCode, body: d }));
    });
    req.on('error', e => resolve({ error: e.message }));
    req.on('timeout', () => { req.destroy(); resolve({ error: 'timeout' }); });
  });
}

(async () => {
  console.log('=== Standalone tool reachability ===');
  for (const page of ['key-room.html', 'lvr-wallet.html', 'lvr-points-admin.html', 'lvr-restaurant-portal.html', 'kt-crm.html', 'key-leads.html', 'key-advertisers.html', 'lvr-coupons-admin.html']) {
    const r = await get('https://lvr-data-a60c1.web.app/' + page, 15000);
    console.log(page + ':', r.status || r.error);
  }

  console.log('\n=== Dashboard markers ===');
  const dash = await get('https://lvr-data-a60c1.web.app/', 20000);
  if (dash.error || dash.status !== 200) {
    console.log('dashboard fetch failed:', dash.error || dash.status);
  } else {
    const body = dash.body;
    const vMatch = body.match(/APP_VERSION\s*=\s*['"]?(\d+)/);
    console.log('APP_VERSION:', vMatch ? vMatch[1] : 'not found');
    console.log('has KEYROOM-SESSION-v1 marker:', body.includes('KEYROOM-SESSION-v1'));
    console.log('has KEYROOM-PILL-v1 marker:', body.includes('KEYROOM-PILL-v1'));
    console.log('has Key Tech pill text:', body.includes('Key Tech'));
  }

  console.log('\n=== Latest deploy log (_debug/diag.json) ===');
  const diag = await get('https://lvr-data-a60c1-default-rtdb.firebaseio.com/_debug/diag.json', 15000);
  console.log('status:', diag.status || diag.error);
  console.log('body (first 2000 chars):', (diag.body || '').slice(0, 2000));
})();
NODE
