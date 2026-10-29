#!/bin/bash
# Vanilla Rice launch setup: 50 free chicken bowls, good for 30 days, with $650 of funded credit (50 x 13 points).
# Guarded: only changes things if the catalog and ledger look exactly as expected. Prints business info only.
export TZ=America/Los_Angeles
node <<'NODE'
const https = require('https');
const DB = 'lvr-data-a60c1-default-rtdb.firebaseio.com';
const call = (method, path, body) => new Promise(res => {
  const data = body === undefined ? null : JSON.stringify(body);
  const req = https.request({ host: DB, path: path + '.json', method, headers: data ? { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(data) } : {} }, r => { let d = ''; r.on('data', c => d += c); r.on('end', () => { let j = null; try { j = JSON.parse(d); } catch (e) {} res({ status: r.statusCode, json: j }); }); });
  req.on('error', e => res({ status: 0, json: null })); if (data) req.write(data); req.end();
});
(async () => {
  const slug = 'vanilla-rice';
  const cat = (await call('GET', '/lvr_points/catalog/' + slug)).json || {};
  const dir = (await call('GET', '/lvr_points/directory/' + slug)).json || {};
  const fund = (await call('GET', '/lvr_points/fundings/' + slug)).json || {};
  const red = (await call('GET', '/lvr_points/redemptions/' + slug)).json || {};
  console.log('catalog items:', JSON.stringify(Object.keys(cat).map(id => ({ id, name: cat[id].itemName, cost: cat[id].pointCost, active: cat[id].active, max: cat[id].maxRedemptions, expiresAt: cat[id].expiresAt }))));
  console.log('directory:', JSON.stringify({ bizName: dir.bizName, active: dir.active, creditRemaining: dir.creditRemaining }));
  console.log('fundings so far:', Object.keys(fund).length, ' redemptions so far:', Object.keys(red).length);
  const ids = Object.keys(cat);
  if (ids.length !== 1 || cat[ids[0]].pointCost !== 13 || Object.keys(fund).length !== 0 || Object.keys(red).length !== 0) { console.log('NOT CHANGING ANYTHING: it does not look like the expected starting point.'); return; }
  const id = ids[0];
  const end = new Date(); end.setDate(end.getDate() + 30); end.setHours(23, 59, 59, 0);
  const expiresAt = end.getTime();
  console.log('expires (Las Vegas time):', end.toString());
  const r1 = await call('PATCH', '/lvr_points/catalog/' + slug + '/' + id, { maxRedemptions: 50, expiresAt, active: true });
  console.log('set max 50 + expiry ->', r1.status);
  const r2 = await call('POST', '/lvr_points/fundings/' + slug, { amount: 650, note: 'Vanilla Rice funds 50 free chicken bowls (50 x 13 points)', at: { '.sv': 'timestamp' } });
  console.log('add $650 funded credit ->', r2.status);
  const r3 = await call('PUT', '/lvr_points/directory/' + slug + '/creditRemaining', 650);
  console.log('credit remaining = 650 ->', r3.status);
  const after = (await call('GET', '/lvr_points/catalog/' + slug + '/' + id)).json || {};
  const dAfter = (await call('GET', '/lvr_points/directory/' + slug)).json || {};
  console.log('NOW: max', after.maxRedemptions, '| expires', new Date(after.expiresAt).toString(), '| credit left', dAfter.creditRemaining);
})();
NODE
