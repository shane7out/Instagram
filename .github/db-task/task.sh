#!/bin/bash
# Read-only diagnostic: check whether Shane has run any of the pending Mac
# deploy scripts since they were handed to him - checks the live Deals site
# freshness, whether the 3 new standalone tools are reachable, and reads the
# most recent _debug/diag.json log any deploy script would have posted.
set -e

node <<'NODE'
const https = require('https');

function get(url) {
  return new Promise((resolve, reject) => {
    https.get(url, r => { let d = ''; r.on('data', c => d += c); r.on('end', () => resolve({status: r.statusCode, body: d})); }).on('error', reject);
  });
}

(async () => {
  // 1) Deals site freshness
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

  // 2) Standalone tools reachability
  for (const path of ['kt-crm.html', 'key-leads.html', 'key-advertisers.html']) {
    try {
      const r = await get('https://lvr-data-a60c1.web.app/' + path);
      console.log('TOOL', path, ':', r.status, '|', r.body.length, 'bytes');
    } catch (e) { console.log('TOOL', path, 'check failed:', e.message); }
  }

  // 3) Main dashboard - check for the new KEYTECH markers (confirms the dashboard patch landed)
  try {
    const r = await get('https://lvr-data-a60c1.web.app/');
    console.log('DASHBOARD has KEYTECH-PIN-REDIRECT marker:', r.body.includes('KEYTECH-PIN-REDIRECT-v1'));
    console.log('DASHBOARD has KEYTECH-FLAGQUEUE-BTN marker:', r.body.includes('KEYTECH-FLAGQUEUE-BTN-v1'));
    const vm = r.body.match(/APP_VERSION=(\d+)/);
    console.log('DASHBOARD APP_VERSION:', vm ? vm[1] : 'not found');
  } catch (e) { console.log('DASHBOARD check failed:', e.message); }

  // 4) Most recent diag log any deploy script would have posted
  try {
    const r = await get('https://lvr-data-a60c1-default-rtdb.firebaseio.com/_debug/diag.json');
    const body = r.body && r.body !== 'null' ? r.body.slice(-1500) : '(empty)';
    console.log('LATEST DIAG LOG (last 1500 chars):');
    console.log(body);
  } catch (e) { console.log('diag check failed:', e.message); }
})();
NODE
