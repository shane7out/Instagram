#!/bin/bash
# Read-only diagnostic: the GH Actions runner can reach instagram.com
# directly (confirmed by an earlier session's log in
# fetched/dupes-and-badig.txt - http=200 on a real profile fetch). Use
# that to check the HTTP status of the 15 badig-flagged handles that DO
# have something on file, to see which are genuinely broken/unreachable
# vs maybe mis-flagged. No writes, no guessing at corrected handles.
set -e

node <<'NODE'
const https = require('https');

function headCheck(handle) {
  return new Promise((resolve) => {
    const url = 'https://www.instagram.com/' + handle.replace(/^@/, '') + '/';
    const req = https.request(url, { method: 'GET', headers: { 'User-Agent': 'Mozilla/5.0' }, timeout: 10000 }, r => {
      resolve({ handle, status: r.statusCode });
      r.resume();
    });
    req.on('error', e => resolve({ handle, status: 'ERR:' + e.message }));
    req.on('timeout', () => { req.destroy(); resolve({ handle, status: 'TIMEOUT' }); });
    req.end();
  });
}

(async () => {
  const handles = [
    'nanas_house_of_soul_food', 'whiskfulthinkingcakes', 'baackyardbbqvillage',
    'bowltasticfood', 'teriyaakimadnesslv', 'sonrisagrill.nv',
    'eathlyplantbased', 'aguas_el_chaavo', 'eatsnooze',
    'laflordemichoacanicecrea', 'korehouselv', 'domdemarcos',
    'gabrielskitchenlasvegas', 'tensecondsyunnanricenoodlelv', 'banhmihouselv',
  ];
  for (const h of handles) {
    const r = await headCheck(h);
    console.log(r.handle + ': ' + r.status);
  }
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
NODE
