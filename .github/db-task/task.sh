#!/bin/bash
# Read-only diagnostic: Shane just saved the 4 A records at Dynadot pointing
# keytechnologies.si at GitHub Pages - check whether DNS has propagated and
# whether the live site is actually reachable over the custom domain yet.
set -e
echo "=== A records (should be the 4 GitHub Pages IPs) ==="
dig +short keytechnologies.si A || true
echo ""
echo "=== HTTP check ==="
node <<'NODE'
const https = require('https');
function get(url) {
  return new Promise((resolve) => {
    const req = https.get(url, { timeout: 15000 }, r => {
      let d = ''; r.on('data', c => d += c); r.on('end', () => resolve({ status: r.statusCode, body: d }));
    });
    req.on('error', e => resolve({ error: e.message }));
    req.on('timeout', () => { req.destroy(); resolve({ error: 'timeout' }); });
  });
}
(async () => {
  const r = await get('https://keytechnologies.si/');
  if (r.error) { console.log('https://keytechnologies.si/ -> ERROR:', r.error); return; }
  console.log('https://keytechnologies.si/ -> HTTP', r.status, '| bytes', r.body.length, '| has "KEY TECHNOLOGIES":', r.body.includes('KEY TECHNOLOGIES'));
})();
NODE
