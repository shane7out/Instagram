#!/bin/bash
# One-shot: add two new Las Vegas restaurants (Instagram screenshots from Shane, 2026-11-04) to dashboard_crec with full
# DM-visibility per the standing rule (section 10 of LVR-PROJECT-STATUS.md): a proper non-colliding num computed from the
# LIVE data at write time, a real Instagram handle (both are on the screenshots), dashboard/status/<num> = "pending" and
# dashboard/attempts/<num> written. Dedup-checks first; aborts without writing if the live data cannot be read.
#   1. JP's Brasserie & Sports Den  @jps_brasserielv   (5781 W Sahara Ave, Spring Valley NV; "Family to @liamslasvegas")
#   2. Brothers Hibachi (food truck) @brothers_hibachi  (7460 W Cheyenne #110, Las Vegas NV 89129)
set +e
cat > /tmp/add-restaurants.js <<'NODE'
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const J = { 'Content-Type': 'application/json' };
async function get(p) {
  const r = await fetch(DB + p + '.json', { signal: AbortSignal.timeout(30000) });
  if (!r.ok) throw new Error('GET ' + p + ' -> HTTP ' + r.status);
  return r.json();
}
async function put(p, body) {
  const r = await fetch(DB + p + '.json', { method: 'PUT', headers: J, body: JSON.stringify(body), signal: AbortSignal.timeout(30000) });
  return r.status;
}
const NEW = [
  {
    key: 'jps', match: n => /jp'?s\s*brasserie/i.test(n) || /brasserie/i.test(n) && /jp/i.test(n), handle: 'jps_brasserielv',
    record: {
      name: "JP's Brasserie & Sports Den", instagram: '@jps_brasserielv', cuisine: 'European brasserie / Sports den',
      address: '5781 W Sahara Ave, Spring Valley, NV', phone: '', email: '', owner: 'Local Operators',
      notes: 'Added from Shane\'s Instagram screenshot 2026-11-04. 478 followers / 12 posts as of add date. Bio: European brasserie dining, sports, community; "Family to @liamslasvegas". ZIP and phone not on the profile.'
    }
  },
  {
    key: 'brothers', match: n => /brothers\s*hibachi/i.test(n), handle: 'brothers_hibachi',
    record: {
      name: 'Brothers Hibachi', instagram: '@brothers_hibachi', cuisine: 'Hibachi (food truck)',
      address: '7460 W Cheyenne #110, Las Vegas, NV 89129', phone: '', email: '', owner: 'Local Operators',
      notes: 'Added from Shane\'s Instagram screenshot 2026-11-04. Food truck, "Las Vegas\' new hibachi experience, made to order", est. 2026. 173 followers / 13 posts as of add date. Address from a post ("back out here on 7460 W Cheyenne #110, 5:00pm till we sell out"); the truck location may change.'
    }
  }
];
(async () => {
  let crec, custom, stg, deleted;
  try {
    crec = await get('/dashboard_crec'); custom = await get('/dashboard/customrecords');
    stg = await get('/dashboard_rest_stg_crec'); deleted = await get('/dashboard/deleted');
  } catch (e) { console.log('ABORT (could not read live data, nothing written): ' + e.message); process.exit(0); }
  if (!crec || typeof crec !== 'object') { console.log('ABORT (dashboard_crec empty/unreadable, nothing written)'); process.exit(0); }
  // next free num: scan num fields AND numeric keys of every place a restaurant number can live, floor 59999
  let max = 59999;
  const scan = obj => {
    if (!obj || typeof obj !== 'object') return;
    for (const [k, v] of Object.entries(obj)) {
      if (/^\d+$/.test(k) && Number(k) > max) max = Number(k);
      if (v && typeof v === 'object' && typeof v.num === 'number' && v.num > max) max = v.num;
    }
  };
  [crec, custom, stg, deleted].forEach(scan);
  const existing = [crec, custom, stg].flatMap(o => Object.values(o || {})).filter(r => r && typeof r === 'object');
  console.log('live restaurant records scanned: ' + existing.length + ', highest num in use: ' + max);
  let next = max;
  for (const item of NEW) {
    const dup = existing.find(r => String(r.instagram || '').toLowerCase().replace('@', '') === item.handle || item.match(String(r.name || '')));
    if (dup) { console.log('SKIP ' + item.key + ': already in the database -> ' + JSON.stringify({ num: dup.num, name: dup.name, instagram: dup.instagram })); continue; }
    next += 1;
    const num = next, rec = Object.assign({ num }, item.record);
    const s1 = await put('/dashboard_crec/' + num, rec);
    const s2 = await put('/dashboard/status/' + num, 'pending');
    const s3 = await put('/dashboard/attempts/' + num, [{ email: '', status: 'pending', date: null, note: '' }]);
    console.log('WRITE ' + item.key + ' num=' + num + ' -> record HTTP ' + s1 + ', status HTTP ' + s2 + ', attempts HTTP ' + s3);
    const back = await get('/dashboard_crec/' + num), st = await get('/dashboard/status/' + num), at = await get('/dashboard/attempts/' + num);
    const ok = back && back.num === num && back.instagram === item.record.instagram && st === 'pending' && Array.isArray(at) && at.length === 1;
    console.log((ok ? 'VERIFIED ' : 'VERIFY FAILED ') + item.key + ': ' + JSON.stringify(back));
  }
})().catch(e => console.log('ERROR: ' + e.message));
NODE
node /tmp/add-restaurants.js
