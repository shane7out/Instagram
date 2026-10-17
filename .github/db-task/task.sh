#!/bin/bash
# Read-only diagnostic: igsuggest holds real, recent-looking IG
# verification entries (detailed notes, sources, timestamps) but keyed by
# small sequential IDs, not LVR nums. Some of its restaurant names (e.g.
# "Nellie's Live!", "Boba Cafe") sound like they could be LVR records
# under a different key. Pull the FULL igsuggest dataset (not truncated)
# and cross-reference its restaurant names against dashboard_crec by name
# match, to see if any verified handles there could resolve LVR no-handle
# or badig-flagged backlog items. No writes.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

node <<'NODE'
const https = require('https');
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';

function get(url) {
  return new Promise((resolve, reject) => {
    https.get(url, r => { let d = ''; r.on('data', c => d += c); r.on('end', () => resolve(d)); }).on('error', reject);
  });
}

function norm(s) {
  return (s || '').toLowerCase().replace(/[^a-z0-9]/g, '');
}

(async () => {
  const [igsuggestRaw, crecRaw] = await Promise.all([
    get(DB + '/dashboard/igsuggest.json'),
    get(DB + '/dashboard_crec.json'),
  ]);
  const igsuggest = JSON.parse(igsuggestRaw) || {};
  const crec = JSON.parse(crecRaw) || {};

  const sugKeys = Object.keys(igsuggest);
  console.log('igsuggest total entries: ' + sugKeys.length);

  // build a name-lookup index of dashboard_crec
  const byName = {};
  for (const [num, r] of Object.entries(crec)) {
    if (!r || !r.name) continue;
    byName[norm(r.name)] = { num, name: r.name, instagram: r.instagram || '' };
  }

  let matches = 0;
  for (const key of sugKeys) {
    const entry = igsuggest[key];
    if (!entry || !entry.ig) continue;
    // igsuggest doesn't carry a name field directly in the sample seen -
    // try matching the suggested ig handle itself against crec instagram
    // (exact or close), since that's the only reliable join key available.
    const sugIg = (entry.ig || '').toLowerCase().replace(/^@/, '');
    for (const [nName, rec] of Object.entries(byName)) {
      const curIg = rec.instagram.toLowerCase().replace(/^@/, '');
      if (curIg && curIg === sugIg) {
        matches++;
        console.log('MATCH key=' + key + ' -> crec num=' + rec.num + ' "' + rec.name + '" ig=' + rec.instagram + ' conf=' + entry.conf);
      }
    }
  }
  console.log('total ig-handle matches found: ' + matches);
  console.log('sample igsuggest keys (first 5 full entries): ' + JSON.stringify(sugKeys.slice(0,5).map(k => ({key:k, ...igsuggest[k]}))).slice(0, 3000));
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
NODE
