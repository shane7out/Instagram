#!/bin/bash
# Verify cross-origin PUT works from keytechnologies.si to the Firebase
# RTDB - the new rewards.html signup form uses PUT (not POST, which was
# already confirmed to work cross-origin for lead forms) to write a wallet
# at a specific key. Confirming before wiring it into the live nav.
set -e
node <<'NODE'
const https = require('https');
function req(method, url, body, origin, timeoutMs) {
  return new Promise((resolve) => {
    const r = new URL(url);
    const opts = { method, hostname: r.hostname, path: r.pathname + r.search, headers: { 'Origin': origin } };
    if (body) opts.headers['Content-Type'] = 'application/json';
    const request = https.request(opts, res => {
      let d = ''; res.on('data', c => d += c); res.on('end', () => resolve({ status: res.statusCode, headers: res.headers, body: d }));
    });
    request.on('error', e => resolve({ error: e.message }));
    request.on('timeout', () => { request.destroy(); resolve({ error: 'timeout' }); });
    request.setTimeout(timeoutMs || 15000);
    if (body) request.write(body);
    request.end();
  });
}

function preflight(url, origin, timeoutMs) {
  return new Promise((resolve) => {
    const r = new URL(url);
    const opts = {
      method: 'OPTIONS', hostname: r.hostname, path: r.pathname + r.search,
      headers: {
        'Origin': origin,
        'Access-Control-Request-Method': 'PUT',
        'Access-Control-Request-Headers': 'content-type'
      }
    };
    const request = https.request(opts, res => {
      let d = ''; res.on('data', c => d += c); res.on('end', () => resolve({ status: res.statusCode, headers: res.headers, body: d }));
    });
    request.on('error', e => resolve({ error: e.message }));
    request.on('timeout', () => { request.destroy(); resolve({ error: 'timeout' }); });
    request.setTimeout(timeoutMs || 15000);
    request.end();
  });
}

(async () => {
  const testKey = 'diagnostic-cors-put-test';
  const url = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com/lvr_points/wallets/' + testKey + '.json';

  console.log('=== CORS preflight (OPTIONS) a real browser sends before the PUT ===');
  const pre = await preflight(url, 'https://keytechnologies.si', 15000);
  console.log('OPTIONS status:', pre.status || pre.error);
  console.log('access-control-allow-origin:', pre.headers && pre.headers['access-control-allow-origin']);
  console.log('access-control-allow-methods:', pre.headers && pre.headers['access-control-allow-methods']);
  console.log('access-control-allow-headers:', pre.headers && pre.headers['access-control-allow-headers']);

  console.log('\n=== Cross-origin PUT test (Origin: https://keytechnologies.si) ===');
  const put = await req('PUT', url, JSON.stringify({ name: 'diag', email: 'diag@test.com', balance: 0 }), 'https://keytechnologies.si', 15000);
  console.log('PUT status:', put.status || put.error);
  console.log('access-control-allow-origin:', put.headers && put.headers['access-control-allow-origin']);

  const read = await req('GET', url, null, 'https://keytechnologies.si', 15000);
  console.log('read-back status:', read.status, '| body:', read.body);

  console.log('\n=== Cleaning up the test wallet ===');
  const del = await req('DELETE', url, null, 'https://keytechnologies.si', 15000);
  console.log('DELETE status:', del.status || del.error);
})();
NODE
