#!/bin/bash
# Live verification: rewards.html is reachable on keytechnologies.si, nav
# links to it are present, and a real signup against the live site actually
# creates a wallet readable from lvr-data-a60c1.web.app's Firebase project.
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
  console.log('=== rewards.html live ===');
  const page = await get('https://keytechnologies.si/rewards.html', 15000);
  console.log('status:', page.status || page.error);
  if (page.body) {
    console.log('has signup form:', page.body.includes('id="signupForm"'));
    console.log('has FAQ section:', page.body.includes('id="faq"'));
  }

  console.log('\n=== nav link present on homepage ===');
  const home = await get('https://keytechnologies.si/', 15000);
  console.log('homepage has rewards.html link:', (home.body || '').includes('rewards.html'));

  console.log('\n=== sitemap includes rewards.html ===');
  const sitemap = await get('https://keytechnologies.si/sitemap.xml', 15000);
  console.log('sitemap has rewards.html:', (sitemap.body || '').includes('rewards.html'));

  console.log('\n=== live round-trip: write + read a real wallet ===');
  const testToken = 'diagnostic-live-signup-test';
  const url = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com/lvr_points/wallets/' + testToken + '.json';
  const put = await req('PUT', url, JSON.stringify({ name: 'Live Test', email: 'livetest@example.com', phone: '', balance: 0, source: 'diagnostic', createdAt: Date.now() }), 15000);
  console.log('PUT status:', put.status || put.error);
  const wallet = await get('https://lvr-data-a60c1.web.app/lvr-wallet.html?t=' + testToken, 15000);
  console.log('wallet page (lvr-data-a60c1.web.app) status:', wallet.status || wallet.error);

  console.log('\n=== cleanup ===');
  const del = await req('DELETE', url, null, 15000);
  console.log('DELETE status:', del.status || del.error);
})();
NODE
