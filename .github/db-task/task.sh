#!/bin/bash
# READ-ONLY inventory of the points program data. Prints counts and masked summaries only. No names, emails, phones or tokens are printed.
node <<'NODE'
const https = require('https');
const get = p => new Promise(res => https.get('https://lvr-data-a60c1-default-rtdb.firebaseio.com' + p, r => { let d=''; r.on('data', c => d += c); r.on('end', () => { try { res(JSON.parse(d)); } catch (e) { res(null); } }); }).on('error', () => res(null)));
const mask = s => { s = String(s || ''); return s ? s[0].toUpperCase() + '*'.repeat(Math.max(1, Math.min(6, s.length - 1))) : '(none)'; };
(async () => {
  const m = await get('/lvr_rewards.json') || {};
  const keys = Object.keys(m);
  console.log('MEMBERS:', keys.length);
  keys.forEach((k, i) => { const r = m[k] || {}; console.log(' #' + (i + 1), 'id=' + k.slice(0, 5) + '…', 'name=' + mask(r.name), 'points=' + (r.points || 0), 'joined=' + (r.joinedAt ? new Date(r.joinedAt).toISOString().slice(0, 10) : 'n/a'), 'source=' + (r.source || 'n/a'), 'token=' + (r.token ? 'yes' : 'no'), 'ig=' + (r.instagram ? 'yes' : 'no'), 'email=' + (r.email ? 'yes' : 'no'), 'phone=' + (r.phone ? 'yes' : 'no'), 'referredBy=' + (r.referredBy ? 'yes' : 'no')); });
  const rc = await get('/lvr_points/receipts.json') || {};
  console.log('RECEIPTS:', Object.keys(rc).length, JSON.stringify(Object.values(rc).reduce((a, r) => { a[r.status] = (a[r.status] || 0) + 1; return a; }, {})));
  const rd = await get('/lvr_points/redemptions.json') || {};
  let n = 0; Object.values(rd).forEach(b => n += Object.keys(b || {}).length);
  console.log('REDEMPTIONS:', n, 'across', Object.keys(rd).length, 'restaurants');
  const cat = await get('/lvr_points/catalog.json') || {};
  console.log('CATALOG restaurants:', Object.keys(cat).join(', ') || 'none');
  const dir = await get('/lvr_points/directory.json') || {};
  console.log('DIRECTORY:', Object.keys(dir).join(', ') || 'none');
  const rs = await get('/lvr_points/restaurants.json?shallow=true') || {};
  console.log('RESTAURANT LOGINS (slugs only):', Object.keys(rs).join(', ') || 'none');
  const bo = await get('/lvr_points/bonuses.json?shallow=true') || {};
  console.log('BONUS RECORDS:', Object.keys(bo).length);
  const fd = await get('/lvr_points/fundings.json') || {};
  console.log('FUNDINGS:', Object.keys(fd).map(s => s + ':' + Object.keys(fd[s] || {}).length).join(', ') || 'none');
  const cp = await get('/lvr_coupons/claims.json?shallow=true') || {};
  console.log('COUPON CLAIM GROUPS:', Object.keys(cp).join(', ') || 'none');
})();
NODE
# inventory again 2026-10-29
