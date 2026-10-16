#!/bin/bash
# Read-only diagnostic: how many DM-able restaurants have never been
# contacted yet (status=pending, attempts=0, has an instagram handle) -
# i.e. the real "ready to DM today" queue size. No writes.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

node <<'NODE'
const https = require('https');
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';

function get(url) {
  return new Promise((resolve, reject) => {
    https.get(url, r => { let d = ''; r.on('data', c => d += c); r.on('end', () => resolve(d)); }).on('error', reject);
  });
}

(async () => {
  const [crecRaw, statusRaw, attemptsRaw] = await Promise.all([
    get(DB + '/dashboard_crec.json'),
    get(DB + '/dashboard/status.json'),
    get(DB + '/dashboard/attempts.json'),
  ]);
  const crec = JSON.parse(crecRaw) || {};
  const status = JSON.parse(statusRaw) || {};
  const attempts = JSON.parse(attemptsRaw) || {};

  let neverContacted = 0, dmdAtLeastOnce = 0, otherStatus = 0, noHandleSkipped = 0;
  const statusCounts = {};

  for (const [num, r] of Object.entries(crec)) {
    if (!r) continue;
    const ig = (r.instagram || '').trim();
    const st = status[num];
    statusCounts[st] = (statusCounts[st] || 0) + 1;
    if (!ig) { noHandleSkipped++; continue; }
    const att = attempts[num];
    const attCount = (typeof att === 'number') ? att : 0;
    if (st === 'pending' && attCount === 0) neverContacted++;
    else if (attCount > 0 || st === 'dmd' || st === 'contacted') dmdAtLeastOnce++;
    else otherStatus++;
  }

  console.log('total records: ' + Object.keys(crec).length);
  console.log('status breakdown: ' + JSON.stringify(statusCounts));
  console.log('--- outreach queue ---');
  console.log('never contacted yet (has handle, status=pending, attempts=0): ' + neverContacted);
  console.log('DM\'d at least once already: ' + dmdAtLeastOnce);
  console.log('has handle but other status/edge case: ' + otherStatus);
  console.log('no instagram handle (can\'t be DM\'d): ' + noHandleSkipped);
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
NODE
