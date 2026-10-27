#!/bin/bash
# Find page-view log entries whose saved referrer contains a member's personal
# account link (?t=<hex>), and scrub the query string out of them. Prints
# counts only - never the tokens themselves.
set -e
node <<'NODE'
const https = require('https');
function req(method, url, body) {
  return new Promise(res => {
    const u = new URL(url), data = body ? JSON.stringify(body) : undefined;
    const r = https.request(u, { method, headers: data ? { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(data) } : {} }, x => { let d = ''; x.on('data', c => d += c); x.on('end', () => res({ s: x.statusCode, b: d })); });
    r.on('error', e => res({ s: e.message, b: '' })); if (data) r.write(data); r.end();
  });
}
const BASE = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com/key_pageviews/hits';
(async () => {
  const r = await req('GET', BASE + '.json');
  const hits = JSON.parse(r.b || 'null') || {};
  let total = 0, leaked = 0, scrubbed = 0;
  for (const page of Object.keys(hits)) {
    for (const id of Object.keys(hits[page] || {})) {
      total++;
      const ref = (hits[page][id] || {}).ref || '';
      if (/[?&]t=[a-f0-9]{16,}/i.test(ref)) {
        leaked++;
        const p = await req('PATCH', BASE + '/' + encodeURIComponent(page) + '/' + encodeURIComponent(id) + '.json', { ref: ref.split(/[?#]/)[0] });
        if (p.s === 200) scrubbed++;
      }
    }
  }
  console.log('page-view entries scanned:', total, '| containing a personal link:', leaked, '| scrubbed:', scrubbed);
})();
NODE
