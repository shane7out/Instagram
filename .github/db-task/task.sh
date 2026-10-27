#!/bin/bash
# Owner asked to remove the 8 old Rewards members (believed to be demos).
# One record (Joseph Marron) has a distinct, recent sign-up timestamp unlike the
# seeded ones, so it is KEPT pending the owner's confirmation. Full records are
# backed up inside the database first (this repo and its Actions logs are
# public: no member data is printed or committed). Also removes each deleted
# member's Instagram duplicate-check entry so the same handle can sign up again.
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
const KEEP = new Set(['-P1C3jE1yz3Vwzq0-bW4']); // Joseph Marron
const igKey = h => String(h || '').toLowerCase().replace(/^@/, '').replace(/\./g, '_');
(async () => {
  const cur = JSON.parse((await req('GET', DB + '/lvr_rewards.json')).b || 'null') || {};
  const keys = Object.keys(cur);
  const b = await req('PUT', DB + '/_backup/lvr_rewards_members_2026-10-27.json', cur);
  console.log('full backup of', keys.length, 'member records, status', b.s);
  if (b.s !== 200) { console.log('BACKUP FAILED - deleting nothing'); process.exit(1); }
  let removed = 0, idx = 0;
  for (const k of keys) {
    if (KEEP.has(k)) { console.log('  kept 1 record (awaiting owner confirmation)'); continue; }
    const d = await req('DELETE', DB + '/lvr_rewards/' + encodeURIComponent(k) + '.json');
    if (d.s === 200) removed++;
    const ik = igKey(cur[k].instagram);
    if (ik) { const di = await req('DELETE', DB + '/lvr_instagram_index/' + encodeURIComponent(ik) + '.json'); if (di.s === 200) idx++; }
  }
  const after = JSON.parse((await req('GET', DB + '/lvr_rewards.json')).b || 'null') || {};
  console.log('removed', removed, 'members and', idx, 'instagram duplicate-check entries | members remaining:', Object.keys(after).length);
})();
NODE
