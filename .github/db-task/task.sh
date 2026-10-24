#!/bin/bash
# Read-only diagnostic: check the live Deals site (classiccarsforsale-co.web.app)
# cars.json freshness, same check as the 2026-10-24 diagnostic in
# LVR-PROJECT-STATUS.md section 15. Does not write anything.
set -e

node <<'NODE'
const https = require('https');

function get(url) {
  return new Promise((resolve, reject) => {
    https.get(url, r => { let d = ''; r.on('data', c => d += c); r.on('end', () => resolve(d)); }).on('error', reject);
  });
}

(async () => {
  const raw = await get('https://classiccarsforsale-co.web.app/cars.json');
  const data = JSON.parse(raw);
  const entries = Array.isArray(data) ? data : Object.values(data);
  console.log('Total entries:', entries.length);

  const now = Date.now();
  const THIRTY_DAYS = 30 * 24 * 60 * 60 * 1000;
  let freshCount = 0;
  let newestDate = null;
  let newestTs = 0;

  for (const e of entries) {
    const addedStr = e.added || e.addedDate || e.date;
    if (!addedStr) continue;
    const ts = new Date(addedStr).getTime();
    if (isNaN(ts)) continue;
    if (ts > newestTs) { newestTs = ts; newestDate = addedStr; }
    if (now - ts <= THIRTY_DAYS) freshCount++;
  }

  console.log('Newest added date found:', newestDate);
  console.log('Entries within last 30 days (fresh):', freshCount);
  console.log('Checked at (UTC):', new Date().toISOString());
})().catch(e => { console.error('ERROR:', e.message); process.exit(1); });
NODE
