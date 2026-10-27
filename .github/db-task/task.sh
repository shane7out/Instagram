#!/bin/bash
# Routine check-in: any Mac deploy progress on the key-room/points bundle?
# Plus a Deals freshness re-check (hasn't been checked in a few cycles).
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
  console.log('=== Mac deploy status (key-room/points bundle) ===');
  for (const page of ['key-room.html', 'lvr-wallet.html', 'lvr-points-admin.html', 'lvr-restaurant-portal.html', 'kt-crm.html', 'key-leads.html', 'key-advertisers.html', 'lvr-coupons-admin.html']) {
    const r = await get('https://lvr-data-a60c1.web.app/' + page, 15000);
    console.log(page + ':', r.status || r.error);
  }

  console.log('\n=== Deals site freshness ===');
  const r2 = await get('https://classiccarsforsale-co.web.app/cars.json', 20000);
  if (r2.error || r2.status !== 200) {
    console.log('fetch failed:', r2.error || r2.status);
  } else {
    try {
      const arr = JSON.parse(r2.body);
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
})();
NODE
