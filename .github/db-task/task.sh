#!/bin/bash
# One-shot: add Spaghetti Western / spaghettywesternlv1 (Instagram screenshot from Shane, 2026-11-13; Shane's standing rule:
# every restaurant screenshot goes into the LVR restaurant database) to dashboard_crec with full DM-visibility per the standing rule
# (section 10 of LVR-PROJECT-STATUS.md): a proper non-colliding num computed from the LIVE data at write time and CLAIMED ATOMICALLY,
# the real Instagram handle from the screenshot, dashboard/status/<num> = "pending" and dashboard/attempts/<num>.
# Dedup-checks first; aborts without writing if the live data cannot be read. ADD ONLY: nothing is changed or deleted.
set +e
cat > /tmp/add-restaurants.js <<'NODE'
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const J = { 'Content-Type': 'application/json' };
async function get(p) {
  const r = await fetch(DB + p + '.json', { signal: AbortSignal.timeout(30000) });
  if (!r.ok) throw new Error('GET ' + p + ' -> HTTP ' + r.status);
  return r.json();
}
async function put(p, body, onlyIfEmpty) {
  const h = Object.assign({}, J); if (onlyIfEmpty) h['if-match'] = 'null_etag';
  const r = await fetch(DB + p + '.json', { method: 'PUT', headers: h, body: JSON.stringify(body), signal: AbortSignal.timeout(30000) });
  return r.status;
}
const NEW = [
  {
    key: 'spaghettywesternlv1', match: n => /spaghetti\s*western/i.test(n), handle: 'spaghettywesternlv1',
    record: {
      name: 'Spaghetti Western', instagram: '@spaghettywesternlv1', cuisine: 'Italian',
      address: '10690 Southern Highlands Pkwy, Las Vegas, NV', phone: '', email: '', owner: '',
      notes: 'Added from Shane\'s Instagram screenshot 2026-11-13. Profile: "Spaghetty Western" (as shown on Instagram). Bio: "Experience the taste of true Italian comfort. Stop by to discover our chef\'s weekly specials. 10690 Southern Highlands Pkwy, Las Vegas, NV". Website starts www.spaghettywesternlv.co... (cut off in the screenshot, so not saved). 52 posts, 1,354 followers, 3,344 following. Followed by panevinolasvegas and marcocicione. Owner, phone and email not in the screenshot.'
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
    let num = 0, s1 = 0;
    for (let tries = 0; tries < 8; tries++) {
      next += 1;
      s1 = await put('/dashboard_crec/' + next, Object.assign({ num: next }, item.record), true); // only if that num is still empty
      if (s1 === 200) { num = next; break; }
      console.log('num ' + next + ' was taken (HTTP ' + s1 + '), trying the next one');
    }
    if (!num) { console.log('FAILED ' + item.key + ': could not claim a free num, nothing else written'); continue; }
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
