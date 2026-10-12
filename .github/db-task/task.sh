#!/bin/bash
# Fix the stuck "AlohaMulans" advertiser - it's been sitting in the database
# with no confirmed Instagram handle (couldn't verify via web search, per
# LVR-PROJECT-STATUS.md section 11). Owner just sent the real IG screenshot:
# @alohamulans. Find the existing record and patch it with the handle +
# full DM-visibility, rather than creating a duplicate.
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
  // Check both live and staging advertiser nodes (per the standing DM-visibility rule)
  const [advRaw, advStgRaw] = await Promise.all([
    get(DB + '/dashboard_adv_crec.json'),
    get(DB + '/dashboard_adv_stg_crec.json'),
  ]);
  const adv = JSON.parse(advRaw) || {};
  const advStg = JSON.parse(advStgRaw) || {};

  function findMulan(obj) {
    for (const k of Object.keys(obj)) {
      const r = obj[k];
      if (r && /mulan/i.test(r.name || '')) return { key: k, rec: r };
    }
    return null;
  }

  let hit = findMulan(adv);
  let node = 'dashboard_adv_crec';
  if (!hit) { hit = findMulan(advStg); node = 'dashboard_adv_stg_crec'; }

  if (!hit) {
    console.log('NOT FOUND in either adv node - will create a fresh staging record instead');
    const shallowAdv = await get(DB + '/dashboard_adv_crec.json?shallow=true');
    const shallowStg = await get(DB + '/dashboard_adv_stg_crec.json?shallow=true');
    const nums = [];
    [shallowAdv, shallowStg].forEach(raw => {
      const obj = JSON.parse(raw) || {};
      Object.keys(obj).forEach(k => { const n = parseInt(k, 10); if (!isNaN(n)) nums.push(n); });
    });
    const num = Math.max(nums.length ? Math.max(...nums) : 29999, 30000);
    const record = { num, name: 'AlohaMulans', ig: 'alohamulans', phone: '', email: '', cat: 'Retail', status: 'pending', defaultStatus: 'pending', notes: 'Hawaiian-themed merch/apparel shop (bags, leis, backpacks)' };
    const r = await put(DB + '/dashboard_adv_stg_crec/' + num + '.json', record);
    console.log('created fresh staging record num ' + num + ': ' + r.status);
    return;
  }

  console.log('FOUND existing record in ' + node + ', key=' + hit.key + ': ' + JSON.stringify(hit.rec));
  const num = hit.rec.num != null ? hit.rec.num : hit.key;
  const updated = Object.assign({}, hit.rec, { ig: 'alohamulans', instagram: 'alohamulans' });
  const r1 = await put(DB + '/' + node + '/' + hit.key + '.json', updated);
  console.log('updated record write: ' + r1.status);

  // Live advertisers (dashboard_adv_crec) need status/attempts in dashboard/*; staging
  // records carry status directly on the object (already set above if it had one).
  if (node === 'dashboard_adv_crec') {
    const r2 = await put(DB + '/dashboard/status/' + num + '.json', 'pending');
    console.log('dashboard/status write: ' + r2.status);
    const r3 = await put(DB + '/dashboard/attempts/' + num + '.json', 0);
    console.log('dashboard/attempts write: ' + r3.status);
  }

  console.log('DONE: AlohaMulans now has confirmed handle @alohamulans, DM-visible');
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
NODE
