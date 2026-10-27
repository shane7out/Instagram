#!/bin/bash
# One-off (owner-approved): give the Vanilla Rice Free Chicken Bowl a maximum of 50 and a 60-day expiry
# (Dec 26, 2026, end of day Pacific). Only fills in values that are missing.
node <<'NODE'
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
(async () => {
  const cat = await (await fetch(DB + '/lvr_points/catalog/vanilla-rice.json')).json() || {};
  const ids = Object.keys(cat);
  console.log('items under vanilla-rice: ' + ids.length);
  const exp = new Date('2026-12-26T23:59:59-08:00').getTime();
  for (const id of ids) {
    const it = cat[id] || {};
    const patch = {};
    if (!it.maxRedemptions) patch.maxRedemptions = 50;
    if (!it.expiresAt) patch.expiresAt = exp;
    console.log(id + ' (' + (it.itemName || '?') + '): ' + (Object.keys(patch).length ? 'setting ' + Object.keys(patch).join(', ') : 'already has both'));
    if (Object.keys(patch).length) {
      const r = await fetch(DB + '/lvr_points/catalog/vanilla-rice/' + id + '.json', { method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(patch) });
      console.log('  HTTP ' + r.status);
    }
  }
})();
NODE
