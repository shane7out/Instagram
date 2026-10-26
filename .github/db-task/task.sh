#!/bin/bash
# Seed the first real coupon program: Vanilla Rice Hibachi House, 50 free
# Chicken & Rice Bowls, capped. This mirrors exactly what the admin tool
# (lvr-coupons-admin.html) would write - same /lvr_coupons/programs node -
# just done here since Shane already gave the real numbers (50, capped) in
# conversation rather than needing to re-enter them once the Mac deploy
# runs. No expiration date was given, so none is set (unlimited time,
# capped only by count) - easy to add later in the admin tool.
set -e
node <<'NODE'
const https = require('https');
function req(method, url, body, timeoutMs) {
  return new Promise((resolve) => {
    const r = new URL(url);
    const opts = { method, hostname: r.hostname, path: r.pathname + r.search, headers: {} };
    if (body) opts.headers['Content-Type'] = 'application/json';
    const request = https.request(opts, res => {
      let d = ''; res.on('data', c => d += c); res.on('end', () => resolve({ status: res.statusCode, body: d }));
    });
    request.on('error', e => resolve({ error: e.message }));
    request.on('timeout', () => { request.destroy(); resolve({ error: 'timeout' }); });
    request.setTimeout(timeoutMs || 15000);
    if (body) request.write(body);
    request.end();
  });
}

(async () => {
  const program = {
    bizName: 'Vanilla Rice Hibachi House',
    offer: 'Free Chicken & Rice Bowl',
    instructions: 'Show this code to your server at Vanilla Rice Hibachi House to redeem your free Chicken & Rice Bowl.',
    photoUrl: '',
    maxClaims: 50,
    expiresAt: null,
    active: true,
    createdAt: { '.sv': 'timestamp' }
  };
  const url = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com/lvr_coupons/programs/vanilla-rice.json';
  const put = await req('PUT', url, JSON.stringify(program), 15000);
  console.log('PUT status:', put.status || put.error);

  const read = await req('GET', url, null, 15000);
  console.log('Read back:', read.body);

  console.log('\nClaim link (works once lvr-coupon.html is deployed):');
  console.log('  https://lvr-data-a60c1.web.app/lvr-coupon.html?biz=vanilla-rice');
})();
NODE
