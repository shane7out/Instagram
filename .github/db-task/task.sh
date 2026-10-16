#!/bin/bash
# Read-only diagnostic: find records with no instagram handle (can't be
# DM'd at all) so we know the real size of the "stuck, needs a handle"
# backlog beyond the one we already know about (Wholesale Classic Cars).
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
  const raw = await get(DB + '/dashboard_crec.json');
  const recs = JSON.parse(raw) || {};
  const stuck = [];
  for (const [num, r] of Object.entries(recs)) {
    if (!r) continue;
    const ig = (r.instagram || '').trim();
    if (!ig) stuck.push({ num, name: r.name, notes: r.notes || '' });
  }
  console.log('total records: ' + Object.keys(recs).length);
  console.log('records with NO instagram handle: ' + stuck.length);
  stuck.forEach(s => console.log('  ' + s.num + ': ' + s.name + (s.notes ? '  [' + s.notes + ']' : '')));
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
NODE
