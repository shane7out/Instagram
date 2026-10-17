#!/bin/bash
# Read-only diagnostic: an old session's dupes-and-badig.txt flagged 5
# "same name, different IG" groups. One (Viva) was already fixed. Another
# - "Oodle Noodle" - has an old record (key 1358, name "Oodle_Noodle")
# holding a real handle @oodle_noodle_lv, while the live num 50913 record
# (same restaurant, currently in the no-handle backlog) has a blank
# instagram field. Check live state of all 4 remaining groups before
# deciding whether any can be safely filled in. No writes.
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
  const [crecRaw, custRaw] = await Promise.all([
    get(DB + '/dashboard_crec.json'),
    get(DB + '/customrecords.json'),
  ]);
  const crec = JSON.parse(crecRaw) || {};
  const cust = JSON.parse(custRaw) || {};

  const checks = [
    { label: 'oodlenoodle', crecKey: '50913', custKey: '1358' },
    { label: 'aiponocafe', crecKey: '50164', custKey: '50164' },
    { label: 'mikiyawagyushabuhouse', crecKey: '50187', custKey: '50187' },
    { label: 'enzaramenkatsucurry', crecKey: '50266', custKey: '50266' },
  ];

  for (const c of checks) {
    console.log('--- ' + c.label + ' ---');
    console.log('crec[' + c.crecKey + ']: ' + JSON.stringify(crec[c.crecKey]));
    console.log('cust[' + c.custKey + ']: ' + JSON.stringify(cust[c.custKey]));
  }
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
NODE
