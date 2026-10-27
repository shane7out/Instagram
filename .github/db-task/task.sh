#!/bin/bash
# Clean up: remove the inventory result that contained email addresses from the
# open database (the matching public log was deleted separately).
set -e
node <<'NODE'
const https = require('https');
function del(path) {
  return new Promise(res => {
    const r = https.request('https://lvr-data-a60c1-default-rtdb.firebaseio.com' + path, { method: 'PUT', headers: { 'Content-Type': 'application/json', 'Content-Length': 4 } }, x => { x.on('data', () => {}); x.on('end', () => res(x.statusCode)); });
    r.on('error', () => res('error')); r.write('null'); r.end();
  });
}
const get = path => new Promise(res => https.get('https://lvr-data-a60c1-default-rtdb.firebaseio.com' + path, r => { let d = ''; r.on('data', c => d += c); r.on('end', () => res(d)); }).on('error', () => res('error')));
(async () => {
  console.log('delete _debug/recon.json ->', await del('/_debug/recon.json.json'.replace('.json.json', '.json')));
  console.log('now reads as:', (await get('/_debug/recon.json')).slice(0, 40));
})();
NODE
