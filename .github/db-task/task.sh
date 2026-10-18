#!/bin/bash
# Read-only diagnostic: basic health check on the live dashboard site
# itself (lvr-data-a60c1.web.app) - confirm it's up, serving the expected
# version, and the follow-up feature is still not live (as expected,
# since the owner hasn't approved the wording yet). No writes.
set -e

node <<'NODE'
const https = require('https');

function get(url) {
  return new Promise((resolve, reject) => {
    https.get(url, r => { let d = ''; r.on('data', c => d += c); r.on('end', () => resolve({status: r.statusCode, body: d})); }).on('error', reject);
  });
}

(async () => {
  const r = await get('https://lvr-data-a60c1.web.app/');
  console.log('dashboard http: ' + r.status + '  bytes: ' + r.body.length);
  const vm = r.body.match(/APP_VERSION\s*=\s*(\d+)/);
  console.log('APP_VERSION: ' + (vm ? vm[1] : 'not found'));
  console.log('has openFollowupDM (should be NO - not deployed yet): ' + (r.body.includes('openFollowupDM')));
  console.log('has openDM (core DM feature, should be YES): ' + (r.body.includes('openDM')));
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
NODE
