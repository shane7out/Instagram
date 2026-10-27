#!/bin/bash
# Investigate the pre-existing LVR Rewards system (lvr_rewards node,
# lvr-rewards.html) that Shane just revealed exists already, separate from
# the new /lvr_points system built this session. Need to understand it
# before building anything else.
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
  console.log('=== lvr-rewards.html live ===');
  const page = await get('https://lvr-data-a60c1.web.app/lvr-rewards.html', 15000);
  console.log('status:', page.status || page.error);
  console.log('bytes:', page.body ? page.body.length : 0);
  if (page.body) {
    console.log('--- first 3000 chars ---');
    console.log(page.body.slice(0, 3000));
  }

  console.log('\n=== lvr_rewards data (real members) ===');
  const data = await get('https://lvr-data-a60c1-default-rtdb.firebaseio.com/lvr_rewards.json', 15000);
  console.log('status:', data.status || data.error);
  console.log('body (first 2000 chars):', (data.body || '').slice(0, 2000));
})();
NODE
