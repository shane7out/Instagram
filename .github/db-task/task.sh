#!/bin/bash
# Read-only diagnostic: verify key-pageviews.html deployed live, fire a
# real test hit against the key_pageviews Firebase node (same path the
# site's own tracker script uses), and read it back to confirm the whole
# loop works end to end.
set -e
node <<'NODE'
const https = require('https');
function req(method, url, body, timeoutMs) {
  return new Promise((resolve) => {
    const r = new URL(url);
    const opts = { method, hostname: r.hostname, path: r.pathname + r.search, headers: {} };
    if (body) { opts.headers['Content-Type'] = 'application/json'; }
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
  console.log('=== key-pageviews.html reachability ===');
  const page = await req('GET', 'https://keytechnologies.si/key-pageviews.html', null, 15000);
  console.log('status:', page.status || page.error);
  if (page.body) {
    console.log('has PIN gate:', page.body.includes('pinInput'));
    console.log('has report app shell:', page.body.includes('id="app"'));
  }

  console.log('\n=== Firing a real test hit (mirrors the tracker script) ===');
  const testUrl = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com/key_pageviews/hits/diagnostic-test.json';
  const postBody = JSON.stringify({ t: Date.now(), ref: 'diagnostic-check', w: 0 });
  const post = await req('POST', testUrl, postBody, 15000);
  console.log('POST status:', post.status || post.error, '| body:', post.body);

  console.log('\n=== Reading it back ===');
  const read = await req('GET', 'https://lvr-data-a60c1-default-rtdb.firebaseio.com/key_pageviews/hits/diagnostic-test.json', null, 15000);
  console.log('GET status:', read.status || read.error, '| body:', (read.body || '').slice(0, 300));

  console.log('\n=== Existing real hits so far (from live traffic, if any) ===');
  const hits = await req('GET', 'https://lvr-data-a60c1-default-rtdb.firebaseio.com/key_pageviews/hits.json?shallow=true', null, 15000);
  console.log('status:', hits.status || hits.error, '| pages with hits:', hits.body);

  console.log('\n=== Cleaning up the diagnostic test entry ===');
  const del = await req('DELETE', testUrl, null, 15000);
  console.log('DELETE status:', del.status || del.error);
})();
NODE
