#!/bin/bash
# Read the deploy-overlay.js source Shane just sent via the _debug channel,
# to find out why it only ever uploads index.html + version.json instead of
# the other standalone tool files.
set -e
node <<'NODE'
const https = require('https');
function get(url) {
  return new Promise((resolve) => {
    https.get(url, { timeout: 15000 }, r => {
      let d = ''; r.on('data', c => d += c); r.on('end', () => resolve({ status: r.statusCode, body: d }));
    }).on('error', e => resolve({ error: e.message }));
  });
}
(async () => {
  const r = await get('https://lvr-data-a60c1-default-rtdb.firebaseio.com/_debug/deployoverlay.json');
  console.log('status:', r.status);
  if (r.status === 200) {
    const src = JSON.parse(r.body);
    console.log('bytes:', src.length);
    console.log('--- full source ---');
    console.log(src);
  } else {
    console.log('body:', r.body);
  }
})();
NODE
