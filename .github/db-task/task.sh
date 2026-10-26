#!/bin/bash
# Read-only diagnostic: Pages deploy just succeeded for the first time -
# verify the custom domain and the raw github.io URL are both actually
# serving the real site content.
set -e

node <<'NODE'
const https = require('https');
function get(url) {
  return new Promise((resolve, reject) => {
    const req = https.get(url, { timeout: 15000 }, r => {
      let d = ''; r.on('data', c => d += c); r.on('end', () => resolve({ status: r.statusCode, body: d, headers: r.headers }));
    });
    req.on('error', e => resolve({ error: e.message }));
    req.on('timeout', () => { req.destroy(); resolve({ error: 'timeout' }); });
  });
}
(async () => {
  for (const url of ['https://keytechnologies.si/', 'https://shane7out.github.io/Instagram/']) {
    const r = await get(url);
    if (r.error) { console.log(url, '-> ERROR:', r.error); continue; }
    console.log(url, '-> HTTP', r.status, '| bytes', r.body.length, '| has "KEY TECHNOLOGIES":', r.body.includes('KEY TECHNOLOGIES'), '| has launch banner:', r.body.includes('Just Launched'));
  }
})();
NODE
