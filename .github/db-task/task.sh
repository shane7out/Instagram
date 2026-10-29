#!/bin/bash
# Set Vanilla Rice's earn rate to 1 point for every $2 spent (0.5). Guarded: only if no rate is set yet.
node <<'NODE'
const https = require('https');
const DB = 'lvr-data-a60c1-default-rtdb.firebaseio.com';
const call = (method, path, body) => new Promise(res => {
  const data = body === undefined ? null : JSON.stringify(body);
  const req = https.request({ host: DB, path: path + '.json', method, headers: data ? { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(data) } : {} }, r => { let d = ''; r.on('data', c => d += c); r.on('end', () => { let j = null; try { j = JSON.parse(d); } catch (e) {} res({ status: r.statusCode, json: j }); }); });
  req.on('error', e => res({ status: 0, json: null })); if (data) req.write(data); req.end();
});
(async () => {
  const d = (await call('GET', '/lvr_points/directory/vanilla-rice')).json || {};
  console.log('before:', JSON.stringify({ bizName: d.bizName, active: d.active, category: d.category, earnRate: d.earnRate, creditRemaining: d.creditRemaining }));
  if (d.earnRate != null) { console.log('earn rate already set - not changing'); return; }
  const r = await call('PUT', '/lvr_points/directory/vanilla-rice/earnRate', 0.5);
  const a = (await call('GET', '/lvr_points/directory/vanilla-rice')).json || {};
  console.log('set earnRate 0.5 ->', r.status, '| now:', JSON.stringify({ earnRate: a.earnRate, creditRemaining: a.creditRemaining }));
})();
NODE
