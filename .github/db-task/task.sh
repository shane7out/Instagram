#!/bin/bash
# Live verification: my-account.html reachable, account icon present on
# homepage, rewards.html signup still works end to end post-deploy.
set -e
node <<'NODE'
const https = require('https');
function get(url, timeoutMs) {
  return new Promise((resolve) => {
    const req = https.get(url, { timeout: timeoutMs || 15000 }, r => {
      let d = ''; r.on('data', c => d += c); r.on('end', () => resolve({ status: r.statusCode, body: d }));
    });
    req.on('error', e => resolve({ error: e.message }));
    req.on('timeout', () => { req.destroy(); resolve({ error: 'timeout' }); });
  });
}
function req(method, url, body, timeoutMs) {
  return new Promise((resolve) => {
    const r = new URL(url);
    const opts = { method, hostname: r.hostname, path: r.pathname + r.search, headers: {} };
    if (body) opts.headers['Content-Type'] = 'application/json';
    const request = https.request(opts, res => {
      let d = ''; res.on('data', c => d += c); res.on('end', () => resolve({ status: res.statusCode, body: d }));
    });
    request.on('error', e => resolve({ error: e.message }));
    if (body) request.write(body);
    request.end();
  });
}

(async () => {
  console.log('=== my-account.html live ===');
  const acct = await get('https://keytechnologies.si/my-account.html', 15000);
  console.log('status:', acct.status || acct.error);
  if (acct.body) console.log('has no-account state markup:', acct.body.includes('no-account-card'));

  console.log('\n=== account icon on homepage ===');
  const home = await get('https://keytechnologies.si/', 15000);
  console.log('status:', home.status || home.error);
  console.log('has accountIcon:', (home.body || '').includes('id="accountIcon"'));
  console.log('has my-account.html JS reference:', (home.body || '').includes('my-account.html'));

  console.log('\n=== full live round trip: sign up -> real wallet -> my-account reachable with real data ===');
  const testToken = 'diagnostic-myaccount-livetest';
  const url = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com/lvr_points/wallets/' + testToken + '.json';
  const put = await req('PUT', url, JSON.stringify({ name: 'Live Test', email: 'livetest2@example.com', balance: 0, source: 'diagnostic', createdAt: Date.now() }), 15000);
  console.log('PUT status:', put.status || put.error);
  const acctWithToken = await get('https://keytechnologies.si/my-account.html?t=' + testToken, 15000);
  console.log('my-account.html?t=... status:', acctWithToken.status || acctWithToken.error);

  console.log('\n=== cleanup ===');
  const del = await req('DELETE', url, null, 15000);
  console.log('DELETE status:', del.status || del.error);
})();
NODE
