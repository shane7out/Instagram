#!/bin/bash
# Read-only diagnostic: re-check whether Shane has run any pending Mac deploy
# scripts since the last check-in cycle.
set -e

node <<'NODE'
const https = require('https');
function get(url) {
  return new Promise((resolve, reject) => {
    https.get(url, r => { let d = ''; r.on('data', c => d += c); r.on('end', () => resolve({status: r.statusCode, body: d})); }).on('error', reject);
  });
}
(async () => {
  for (const path of ['kt-crm.html', 'key-leads.html', 'key-advertisers.html']) {
    try {
      const r = await get('https://lvr-data-a60c1.web.app/' + path);
      console.log('TOOL', path, ':', r.status, '|', r.body.length, 'bytes');
    } catch (e) { console.log('TOOL', path, 'check failed:', e.message); }
  }
  try {
    const r = await get('https://lvr-data-a60c1.web.app/');
    console.log('DASHBOARD has KEYTECH-PIN-REDIRECT marker:', r.body.includes('KEYTECH-PIN-REDIRECT-v1'));
    const vm = r.body.match(/APP_VERSION=(\d+)/);
    console.log('DASHBOARD APP_VERSION:', vm ? vm[1] : 'not found');
  } catch (e) { console.log('DASHBOARD check failed:', e.message); }
  try {
    const r = await get('https://classiccarsforsale-co.web.app/cars.json');
    const data = JSON.parse(r.body);
    const entries = Array.isArray(data) ? data : Object.values(data);
    let newest = '', newestTs = 0;
    for (const e of entries) {
      const a = e.added || e.addedDate || e.date; if (!a) continue;
      const ts = new Date(a).getTime(); if (isNaN(ts)) continue;
      if (ts > newestTs) { newestTs = ts; newest = a; }
    }
    console.log('DEALS newest added:', newest);
  } catch (e) { console.log('DEALS check failed:', e.message); }
  try {
    const r = await get('https://lvr-data-a60c1-default-rtdb.firebaseio.com/_debug/diag.json');
    const body = r.body && r.body !== 'null' ? r.body.slice(-600) : '(empty)';
    console.log('LATEST DIAG (last 600 chars):', body);
  } catch (e) { console.log('diag check failed:', e.message); }
})();
NODE
