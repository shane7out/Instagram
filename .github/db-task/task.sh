#!/bin/bash
# Read the full database rules the owner saved from the Mac (already masked of
# emails on the Mac, and masked again here), print them, then delete the copy.
set -e
node <<'NODE'
const https = require('https');
const mask = s => String(s).replace(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g, '[EMAIL]');
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const get = p => new Promise(res => https.get(DB + p, r => { let d = ''; r.on('data', c => d += c); r.on('end', () => res(d)); }).on('error', () => res('null')));
const del = p => new Promise(res => { const r = https.request(DB + p, { method: 'PUT', headers: { 'Content-Type': 'application/json', 'Content-Length': 4 } }, x => { x.on('data', () => {}); x.on('end', () => res(x.statusCode)); }); r.on('error', () => res('error')); r.write('null'); r.end(); });
(async () => {
  let rules = ''; try { rules = JSON.parse(await get('/_debug/rules.json')); } catch (e) {}
  console.log(rules ? mask(rules) : 'NO RULES SAVED');
  console.log('--- deleted rules copy:', await del('/_debug/rules.json'), '| deleted summary copy:', await del('/_debug/recon.json'));
})();
NODE
