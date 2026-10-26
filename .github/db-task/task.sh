#!/bin/bash
# Read-only diagnostic: check whether any of the still-pending Mac deploy
# scripts have actually landed on the live dashboard site yet (kt-crm.html,
# key-leads.html, key-advertisers.html, and the dashboard-patches bundle's
# APP_VERSION/markers). Last checked before the Pages-launch work began.
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
  for (const page of ['kt-crm.html', 'key-leads.html', 'key-advertisers.html']) {
    const r = await get('https://lvr-data-a60c1.web.app/' + page, 15000);
    console.log(page + ':', r.status || r.error);
  }

  console.log('\n=== Dashboard APP_VERSION + KEYTECH markers ===');
  const dash = await get('https://lvr-data-a60c1.web.app/', 20000);
  if (dash.error || dash.status !== 200) {
    console.log('dashboard fetch failed:', dash.error || dash.status);
  } else {
    const body = dash.body;
    const vMatch = body.match(/APP_VERSION\s*=\s*['"]?(\d+)/);
    console.log('APP_VERSION:', vMatch ? vMatch[1] : 'not found');
    console.log('has KEYTECH-PIN-REDIRECT marker:', body.includes('KEYTECH-PIN-REDIRECT'));
    console.log('has KEYTECH-FLAG-BTN marker:', body.includes('KEYTECH-FLAG-BTN'));
    console.log('has rsLoadFirebaseStaging (dashboard-patches bundle):', body.includes('rsLoadFirebaseStaging'));
    console.log('has igSuggestAccept (dashboard-patches bundle):', body.includes('igSuggestAccept'));
    console.log('has ZACHPIN/223344 marker:', body.includes('223344'));
  }
})();
NODE
