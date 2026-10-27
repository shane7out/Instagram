#!/bin/bash
# Owner-requested one-off: add 10 points to the owner's own member account.
# The member is found by a SHA-256 of their email (no address is stored here
# or printed), and every printed value is non-identifying. Idempotent via a
# marker on the member record: running twice does not add twice.
node <<'NODE'
const crypto = require('crypto');
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const WANT = '55a046d8b6e0a17e7607518106c3a1143eee693c601a0543895d130e0222aaee';
const POINTS = 10, MARK = 'ownerGrant-2026-10-27';
const sha = s => crypto.createHash('sha256').update(String(s).trim().toLowerCase()).digest('hex');
(async () => {
  const all = await (await fetch(DB + '/lvr_rewards.json')).json() || {};
  const hits = Object.keys(all).filter(k => all[k] && all[k].email && sha(all[k].email) === WANT);
  console.log('members checked: ' + Object.keys(all).length + ', matches: ' + hits.length);
  if (hits.length !== 1) { console.log('Expected exactly one match - nothing changed.'); return; }
  const k = hits[0], m = all[k];
  console.log('points before: ' + (m.points || 0));
  if (m.lastAdjust && m.lastAdjust.mark === MARK) { console.log('Already granted - nothing changed.'); return; }
  const a = await fetch(DB + '/lvr_rewards/' + k + '/lastAdjust.json', { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ mark: MARK, points: POINTS, reason: 'owner test grant', at: { '.sv': 'timestamp' } }) });
  const b = a.ok && await fetch(DB + '/lvr_rewards/' + k + '/points.json', { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ '.sv': { increment: POINTS } }) });
  console.log('marker HTTP ' + a.status + ', points HTTP ' + (b && b.status));
  const after = await (await fetch(DB + '/lvr_rewards/' + k + '/points.json')).json();
  console.log('points after: ' + after);
})();
NODE
