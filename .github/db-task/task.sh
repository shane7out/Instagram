#!/bin/bash
# Read-only diagnostic: Shane just set the custom domain in GitHub Pages
# settings - check whether the HTTPS certificate has been issued and the
# site is fully reachable over keytechnologies.si yet.
set -e
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
  console.log('https://keytechnologies.si/ -> HTTP', r.status, '| bytes', r.body.length, '| has "KEY TECHNOLOGIES":', r.body.includes('KEY TECHNOLOGIES'), '| has launch banner:', r.body.includes('Just Launched'));
})();
NODE
