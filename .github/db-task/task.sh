#!/bin/bash
# Read-only diagnostic: Shane just ran setup-deals-auto.sh on the Mac to fix
# the Deals site (classiccarsforsale-co.web.app), which has had a fully empty
# listing grid since 2026-10-21 (nothing scraped since Sept 21, everything
# aged past the 30-day freshness window the site's client-side display rule
# uses). The Mac terminal output only showed an image-upload/dedup step
# (25,223 car images checked, only 1 new upload needed), which does NOT by
# itself prove new listings were actually scraped - that's consistent with
# either "nothing new to scrape" (deploy just re-synced the stale manifest)
# or "Craigslist is blocking the scraper" per the known risk already logged
# in LVR-PROJECT-STATUS.md section 14. Check the live cars.json directly
# instead of guessing. No writes.
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
  const cars = JSON.parse(raw);
  const list = Array.isArray(cars) ? cars : Object.values(cars);
  console.log('total entries in live cars.json: ' + list.length);

  const now = Date.now();
  const THIRTY_DAYS = 30 * 24 * 60 * 60 * 1000;
  let fresh = 0;
  let newestTs = 0;
  let newestDate = null;
  const dateCounts = {};

  for (const c of list) {
    const d = c.added;
    if (!d) continue;
    const ts = new Date(d).getTime();
    if (isNaN(ts)) continue;
    if (ts > newestTs) { newestTs = ts; newestDate = d; }
    if (now - ts <= THIRTY_DAYS) fresh++;
    const day = String(d).slice(0, 10);
    dateCounts[day] = (dateCounts[day] || 0) + 1;
  }

  console.log('entries within the 30-day freshness window (would show on the live grid): ' + fresh);
  console.log('newest "added" date found: ' + newestDate);

  const days = Object.keys(dateCounts).sort().reverse().slice(0, 8);
  console.log('most recent dates present, with counts:');
  for (const d of days) console.log('  ' + d + ': ' + dateCounts[d]);
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
NODE
