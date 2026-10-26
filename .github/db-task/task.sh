#!/bin/bash
# Read-only diagnostic: check whether the new page-view counter has picked
# up any real (non-diagnostic-test) traffic since it shipped.
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

(async () => {
  const r = await get('https://lvr-data-a60c1-default-rtdb.firebaseio.com/key_pageviews/hits.json', 15000);
  if (r.error || r.status !== 200) {
    console.log('fetch failed:', r.error || r.status);
    return;
  }
  const data = JSON.parse(r.body || 'null') || {};
  let total = 0;
  for (const page of Object.keys(data)) {
    if (page === 'diagnostic-test') continue;
    const hits = data[page] || {};
    const count = Object.keys(hits).length;
    total += count;
    console.log(page + ':', count);
  }
  console.log('TOTAL real hits:', total);
})();
NODE
