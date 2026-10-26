#!/bin/bash
# Seed the first real points-catalog item: Vanilla Rice Hibachi House, Free
# Chicken Bowl for 10 points (at $1/point, matching what Shane described).
# Same /lvr_points node the new admin tool (lvr-points-admin.html) and
# wallet page (lvr-wallet.html) read from - this mirrors exactly what
# creating it through the admin tool would write.
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
  const restaurant = { bizName: 'Vanilla Rice Hibachi House', pin: '5190' };
  const restUrl = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com/lvr_points/restaurants/vanilla-rice.json';
  const r1 = await req('PUT', restUrl, JSON.stringify(restaurant), 15000);
  console.log('restaurant PUT status:', r1.status || r1.error);

  const item = {
    itemName: 'Free Chicken Bowl',
    pointCost: 10,
    instructions: 'Show this code to your server at Vanilla Rice Hibachi House to redeem your free Chicken Bowl.',
    photoUrl: '',
    maxRedemptions: null,
    expiresAt: null,
    active: true,
    createdAt: { '.sv': 'timestamp' }
  };
  const itemUrl = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com/lvr_points/catalog/vanilla-rice/bowl1.json';
  const r2 = await req('PUT', itemUrl, JSON.stringify(item), 15000);
  console.log('catalog item PUT status:', r2.status || r2.error);

  const readRest = await req('GET', restUrl, null, 15000);
  const readItem = await req('GET', itemUrl, null, 15000);
  console.log('restaurant read back:', readRest.body);
  console.log('item read back:', readItem.body);

  console.log('\nRestaurant portal: https://lvr-data-a60c1.web.app/lvr-restaurant-portal.html (PIN 5190)');
  console.log('To give someone points, use lvr-points-admin.html -> Wallets -> + New Wallet.');
})();
NODE
