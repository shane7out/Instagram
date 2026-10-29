#!/bin/bash
# Vanilla Rice: bowl now 20 points (credit topped up so 50 bowls still fit), and every new member starts with 21 welcome points.
# Guarded: only changes things if the data looks exactly as expected. Prints business info and settings only.
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
  const fund = (await call('GET', '/lvr_points/fundings/' + slug)).json || {};
  const red = (await call('GET', '/lvr_points/redemptions/' + slug)).json || {};
  const ids = Object.keys(cat);
  const funded = Object.values(fund).reduce((s, f) => s + (Number(f.amount) || 0), 0);
  console.log('before: items', JSON.stringify(ids.map(i => ({ id: i, cost: cat[i].pointCost, max: cat[i].maxRedemptions }))), '| funded', funded, '| redemptions', Object.keys(red).length);
  if (ids.length !== 1 || cat[ids[0]].pointCost !== 13 || funded !== 650 || Object.keys(red).length !== 0) { console.log('NOT CHANGING ANYTHING: not the expected starting point.'); return; }
  const id = ids[0];
  const r1 = await call('PATCH', '/lvr_points/catalog/' + slug + '/' + id, { pointCost: 20 });
  console.log('bowl cost 20 ->', r1.status);
  const r2 = await call('POST', '/lvr_points/fundings/' + slug, { amount: 350, note: 'Top-up: bowl is now 20 points, so 50 bowls = $1,000 total (650 + 350)', at: { '.sv': 'timestamp' } });
  console.log('credit top-up +350 ->', r2.status);
  const r3 = await call('PUT', '/lvr_points/directory/' + slug + '/creditRemaining', 1000);
  console.log('credit remaining = 1000 ->', r3.status);
  const r4 = await call('PUT', '/lvr_points/settings/welcome', { enabled: true, amount: 21, when: 'signup' });
  console.log('welcome bonus 21 at sign-up ->', r4.status);
  const a = (await call('GET', '/lvr_points/catalog/' + slug + '/' + id)).json || {};
  const d = (await call('GET', '/lvr_points/directory/' + slug)).json || {};
  const w = (await call('GET', '/lvr_points/settings/welcome')).json;
  console.log('NOW: bowl', a.pointCost, 'pts, max', a.maxRedemptions, '| credit left', d.creditRemaining, '| welcome', JSON.stringify(w));
})();
NODE
