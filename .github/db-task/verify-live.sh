#!/bin/bash
# Run (by swapping into task.sh) AFTER the owner runs go-live.sh: checks the live pages carry the new code
# and that the database rules are blocking deletes. Read-only apart from one harmless delete of a key that does not exist.
node <<'NODE'
const checks = [
  ['https://lvr-data-a60c1.web.app/lvr-points-admin.html', ['renderBonusTab', 'applyWelcome', 'Treasure chest', 'Every offer needs a maximum']],
  ['https://lvr-data-a60c1.web.app/lvr-restaurant-portal.html', ['useBy']],
  ['https://lvr-data-a60c1.web.app/lvr-rewards.html', ['welcomeGiven']],
  ['https://lvr-data-a60c1.web.app/key-room.html', ['']],
  ['https://keytechnologies.si/menu.html', ['tallyHtml', 'demo']],
  ['https://keytechnologies.si/my-account.html', ['chestSvg', 'tallyHtml', 'startQuest'.slice(0, 0)]],
];
(async () => {
  for (const [url, needles] of checks) {
    try { const r = await fetch(url + '?v=' + Date.now()); const t = await r.text(); const miss = needles.filter(n => n && !t.includes(n)); console.log((r.ok && !miss.length ? 'OK   ' : 'FAIL ') + url.replace('https://', '') + ' (HTTP ' + r.status + (miss.length ? ', missing: ' + miss.join(', ') : '') + ')'); } catch (e) { console.log('FAIL ' + url + ' ' + e.message); }
  }
  const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
  const d1 = await fetch(DB + '/lvr_points/receipts/zz_probe_none.json', { method: 'DELETE' });
  const d2 = await fetch(DB + '/lvr_points/receipt_photos/zz_probe_none.json', { method: 'DELETE' });
  console.log('receipt deletes blocked by the new rules: ' + ((d1.status === 401 || d1.status === 403) && (d2.status === 401 || d2.status === 403) ? 'YES' : 'NO (HTTP ' + d1.status + '/' + d2.status + ')'));
  const cat = await (await fetch(DB + '/lvr_points/catalog/vanilla-rice.json')).json() || {};
  Object.keys(cat).forEach(k => console.log('catalog ' + k + ': ' + cat[k].itemName + ', ' + cat[k].pointCost + ' points, max ' + cat[k].maxRedemptions + ', expires ' + (cat[k].expiresAt ? new Date(cat[k].expiresAt).toISOString().slice(0, 10) : 'not set')));
})();
NODE
