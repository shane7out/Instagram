#!/bin/bash
# Read-only diagnostic: Shane was actively running fix-deals-harvest.sh last
# we spoke - check whether it actually completed and produced fresh listings.
set -e

node <<'NODE'
const https = require('https');
function get(url) {
  return new Promise((resolve, reject) => {
    https.get(url, r => { let d = ''; r.on('data', c => d += c); r.on('end', () => resolve({status: r.statusCode, body: d})); }).on('error', reject);
  });
}
(async () => {
  try {
    const r = await get('https://classiccarsforsale-co.web.app/cars.json');
    const data = JSON.parse(r.body);
    const entries = Array.isArray(data) ? data : Object.values(data);
    const now = Date.now(), THIRTY = 30*24*60*60*1000;
    let newest = '', newestTs = 0, fresh = 0;
    for (const e of entries) {
      const a = e.added || e.addedDate || e.date; if (!a) continue;
      const ts = new Date(a).getTime(); if (isNaN(ts)) continue;
      if (ts > newestTs) { newestTs = ts; newest = a; }
      if (now - ts <= THIRTY) fresh++;
    }
    console.log('DEALS: total', entries.length, '| newest added', newest, '| fresh(<=30d)', fresh);
  } catch (e) { console.log('DEALS check failed:', e.message); }

  try {
    const r = await get('https://lvr-data-a60c1-default-rtdb.firebaseio.com/_debug/diag.json');
    const body = r.body && r.body !== 'null' ? r.body.slice(-1800) : '(empty)';
    console.log('LATEST DIAG LOG (last 1800 chars):');
    console.log(body);
  } catch (e) { console.log('diag check failed:', e.message); }

  for (const path of ['kt-crm.html', 'key-leads.html', 'key-advertisers.html']) {
    try {
      const r = await get('https://lvr-data-a60c1.web.app/' + path);
      console.log('TOOL', path, ':', r.status);
    } catch (e) { console.log('TOOL', path, 'check failed:', e.message); }
  }
})();
NODE
