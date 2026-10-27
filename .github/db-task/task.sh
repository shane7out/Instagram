#!/bin/bash
# Owner's instruction (2026-10-27): start the 8 existing Rewards members fresh.
# Backs up current balances INSIDE the database (this repo is public - no
# member data goes in git), then sets every member's points to 0. Members,
# phones, Instagram handles and personal links are left untouched.
set -e
node <<'NODE'
const https = require('https');
function req(method, url, body) {
  return new Promise(res => {
    const u = new URL(url), data = body !== undefined ? JSON.stringify(body) : undefined;
    const r = https.request(u, { method, headers: data ? { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(data) } : {} }, x => { let d = ''; x.on('data', c => d += c); x.on('end', () => res({ s: x.statusCode, b: d })); });
    r.on('error', e => res({ s: e.message, b: '' })); if (data) r.write(data); r.end();
  });
}
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
(async () => {
  const cur = JSON.parse((await req('GET', DB + '/lvr_rewards.json')).b || 'null') || {};
  const keys = Object.keys(cur);
  const backup = {};
  keys.forEach(k => { backup[k] = { name: cur[k].name, points: cur[k].points || 0 }; });
  const b = await req('PUT', DB + '/_backup/lvr_rewards_points_2026-10-27.json', backup);
  console.log('backup of', keys.length, 'balances written, status', b.s);
  if (b.s !== 200) { console.log('BACKUP FAILED - not resetting'); process.exit(1); }
  for (const k of keys) {
    const r = await req('PATCH', DB + '/lvr_rewards/' + encodeURIComponent(k) + '.json', { points: 0 });
    console.log('  reset', cur[k].name, ':', (cur[k].points || 0), '-> 0 (status', r.s + ')');
  }
  const after = JSON.parse((await req('GET', DB + '/lvr_rewards.json')).b || 'null') || {};
  console.log('verify: members', Object.keys(after).length, '| total points now', Object.values(after).reduce((s, m) => s + (m.points || 0), 0), '| all still have a link token:', Object.values(after).every(m => m.token));
})();
NODE
