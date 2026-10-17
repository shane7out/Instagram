#!/bin/bash
# Add new restaurant: Frank's Pizza (@frankspizzalv), New York style
# pizza, Las Vegas NV (no street address shown in source screenshot -
# bio only has a "Locations" button, left address blank rather than
# guess). Standard DM-visibility flow: allocate num, write customrecord,
# set dashboard/status + dashboard/attempts.
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
function put(url, body) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const u = new URL(url);
    const req = https.request(u, { method: 'PUT', headers: { 'Content-Type': 'application/json' } }, r => {
      let d = ''; r.on('data', c => d += c); r.on('end', () => resolve({ status: r.statusCode, body: d }));
    });
    req.on('error', reject); req.write(data); req.end();
  });
}

(async () => {
  const dupCheckRaw = await get(DB + '/dashboard_crec.json');
  const existing = JSON.parse(dupCheckRaw) || {};
  const dupe = Object.values(existing).find(r => r && (/frank.?s pizza/i.test(r.name || '') || (r.instagram || '').toLowerCase() === 'frankspizzalv'));
  if (dupe) {
    console.log('ALREADY IN DATABASE - no duplicate created: ' + JSON.stringify(dupe));
    return;
  }

  const [crecRaw, custRaw, delRaw] = await Promise.all([
    get(DB + '/dashboard_crec.json?shallow=true'),
    get(DB + '/customrecords.json?shallow=true'),
    get(DB + '/dashboard_deleted.json?shallow=true'),
  ]);
  const nums = [];
  [crecRaw, custRaw, delRaw].forEach(raw => {
    const obj = JSON.parse(raw) || {};
    Object.keys(obj).forEach(k => { const n = parseInt(k, 10); if (!isNaN(n)) nums.push(n); });
  });
  let maxNum = nums.length ? Math.max(...nums) : 59999;
  const num = Math.max(maxNum + 1, 60000);
  console.log('allocated num: ' + num);

  const record = {
    num,
    name: "Frank's Pizza",
    instagram: 'frankspizzalv',
    category: 'Restaurant',
    city: 'Las Vegas',
    address: '',
    status: 'pending',
  };

  const r1 = await put(DB + '/dashboard_crec/' + num + '.json', record);
  console.log('dashboard_crec write: ' + r1.status);
  const r2 = await put(DB + '/dashboard/status/' + num + '.json', 'pending');
  console.log('dashboard/status write: ' + r2.status);
  const r3 = await put(DB + '/dashboard/attempts/' + num + '.json', 0);
  console.log('dashboard/attempts write: ' + r3.status);

  console.log('DONE: added num ' + num + ' - Frank\'s Pizza (@frankspizzalv)');
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
NODE
