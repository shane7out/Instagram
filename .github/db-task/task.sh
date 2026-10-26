#!/bin/bash
# Routine check-in diagnostic: Deals site freshness (hasn't been checked in
# a few cycles) + confirm none of the pending key-room/points Mac deploys
# have landed yet (expected - just shipped, waiting on Shane).
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
  console.log('=== Deals site freshness (cars.json) ===');
  const r = await get('https://classiccarsforsale-co.web.app/cars.json', 20000);
  if (r.error || r.status !== 200) {
    console.log('fetch failed:', r.error || r.status);
  } else {
    try {
      const arr = JSON.parse(r.body);
      const cutoff = Date.now() - 30 * 24 * 60 * 60 * 1000;
      let newest = 0, fresh = 0;
      for (const item of arr) {
        const added = item && item.added ? Date.parse(item.added) : 0;
        if (added > newest) newest = added;
        if (added >= cutoff) fresh++;
      }
      console.log('total:', arr.length, '| newest added:', newest ? new Date(newest).toISOString().slice(0,10) : 'none', '| fresh(<=30d):', fresh);
    } catch (e) { console.log('parse failed:', e.message); }
  }

  console.log('\n=== Key Room / Points deploy status (expected: still 404, just shipped) ===');
  for (const page of ['key-room.html', 'lvr-wallet.html', 'lvr-points-admin.html', 'lvr-restaurant-portal.html']) {
    const r2 = await get('https://lvr-data-a60c1.web.app/' + page, 15000);
    console.log(page + ':', r2.status || r2.error);
  }
})();
NODE
