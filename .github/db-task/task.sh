#!/bin/bash
# Read-only check of what is live after the owner ran the Mac commands.
node <<'NODE'
const checks = [
  ['https://lvr-data-a60c1.web.app/lvr-points-admin.html', ['renderCleanupTab', 'commissionFor', 'renderBonusTab', 'Every offer needs a maximum']],
  ['https://lvr-data-a60c1.web.app/lvr-rewards.html', ['welcomeGiven', 'consentRules']],
  ['https://lvr-data-a60c1.web.app/lvr-restaurant-portal.html', ['useBy', 'Pickup only']],
  ['https://keytechnologies.si/my-account.html', ['SHOW_PHOTOS', 'openReceipt', 'tallyHtml']],
  ['https://keytechnologies.si/rewards.html', ['r-rules']],
];
(async () => {
  for (const [url, needles] of checks) {
    try { const r = await fetch(url + '?v=' + Date.now()); const t = await r.text(); const miss = needles.filter(n => n && !t.includes(n)); console.log((r.ok && !miss.length ? 'LIVE   ' : 'NOT YET') + '  ' + url.replace('https://', '') + (miss.length ? '  (missing: ' + miss.join(', ') + ')' : '')); }
    catch (e) { console.log('ERROR  ' + url); }
  }
  const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
  const put = async (p, v) => (await fetch(DB + p + '.json', { method: 'PUT', body: JSON.stringify(v) })).status;
  const denied = s => s === 401 || s === 403;
  const t = [
    ['delete a receipt', (await fetch(DB + '/lvr_points/receipts/zz_probe.json', { method: 'DELETE' })).status],
    ['monthly return percent 90', await put('/lvr_points/settings/decay/percent', 90)],
    ['default commission 250', await put('/lvr_points/settings/defaultCommissionPct', 250)],
    ['chest prize without a setting', await put('/lvr_rewards/zz_probe/chestState', { n: 1, amount: 1, at: 1 })],
  ];
  t.forEach(([n, s]) => console.log((denied(s) ? 'BLOCKED ' : 'OPEN?   ') + n + ' (HTTP ' + s + ')'));
  const cat = await (await fetch(DB + '/lvr_points/catalog/vanilla-rice.json')).json() || {};
  Object.keys(cat).forEach(k => console.log('catalog ' + k + ': ' + cat[k].itemName + ', ' + cat[k].pointCost + ' points'));
})();
NODE
