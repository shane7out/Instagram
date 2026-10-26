#!/bin/bash
# Read-only diagnostic: the previous check matched the raw string "223344"
# in the live dashboard, which could be a coincidence (any ID/number) and
# not actually Zach's PIN patch. Confirm against the patch's real,
# distinctive marker (ZACHPIN01/ZACHPIN02) instead before reporting it as
# deployed.
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
  const dash = await get('https://lvr-data-a60c1.web.app/', 20000);
  if (dash.error || dash.status !== 200) {
    console.log('dashboard fetch failed:', dash.error || dash.status);
    return;
  }
  const body = dash.body;
  console.log('has ZACHPIN01 marker:', body.includes('ZACHPIN01'));
  console.log('has ZACHPIN02 marker:', body.includes('ZACHPIN02'));
  console.log('has "223344" raw string:', body.includes('223344'));
  // show surrounding context of any raw 223344 match so we know what it actually is
  const idx = body.indexOf('223344');
  if (idx !== -1) {
    console.log('context around first 223344 match:', JSON.stringify(body.slice(Math.max(0, idx - 80), idx + 80)));
  }
})();
NODE
