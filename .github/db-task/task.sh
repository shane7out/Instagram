#!/bin/bash
# Read-only diagnostic: check whether the Deals site harvest fix
# (fix-deals-harvest.sh) actually completed - last check found it still
# stuck. Checks the live cars.json freshness window and looks for the
# fix's own completion/diag log.
set -e
node <<'NODE'
const https = require('https');
function get(url, timeoutMs) {
  return new Promise((resolve) => {
    const req = https.get(url, { timeout: timeoutMs || 20000 }, r => {
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
      const now = Date.now();
      const cutoff = now - 30 * 24 * 60 * 60 * 1000;
      let newest = 0;
      let fresh = 0;
      for (const item of arr) {
        const added = item && item.added ? Date.parse(item.added) : 0;
        if (added > newest) newest = added;
        if (added >= cutoff) fresh++;
      }
      console.log('total entries:', arr.length);
      console.log('newest added:', newest ? new Date(newest).toISOString().slice(0,10) : 'none');
      console.log('fresh (<=30d):', fresh);
    } catch (e) {
      console.log('parse failed:', e.message);
    }
  }

  console.log('\n=== _debug/diag.json (last deploy/fix log, if any) ===');
  const diag = await get('https://lvr-data-a60c1-default-rtdb.firebaseio.com/_debug/diag.json', 15000);
  console.log('status:', diag.status || diag.error);
  console.log('body (first 1500 chars):', (diag.body || '').slice(0, 1500));
})();
NODE
