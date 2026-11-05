#!/bin/bash
# One-shot: add DTS Kitchen / dtskitchen (hibachi, Tiki and Latino influence, Instagram screenshot from Shane, 2026-11-05) to dashboard_crec with
# full DM-visibility per the standing rule (section 10 of LVR-PROJECT-STATUS.md): a proper non-colliding num computed from the LIVE
# data at write time and CLAIMED ATOMICALLY (the write only succeeds if that num is still empty, so two jobs can never take the
# same number), the real Instagram handle from the screenshot, dashboard/status/<num> = "pending" and dashboard/attempts/<num>.
# Dedup-checks first; aborts without writing if the live data cannot be read.
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
    key: 'dtskitchen', match: n => /dts\s*kitchen|down\s*the\s*street/i.test(n), handle: 'dtskitchen',
    record: {
      name: 'DTS Kitchen (Down The Street)', instagram: '@dtskitchen', cuisine: 'Hibachi / Tiki / Latino fusion',
      address: '', phone: '', email: '', owner: 'Chef OD (@odblendzz)',
      notes: 'Added from Shane\'s Instagram screenshot 2026-11-05. Bio: "Chef OD! @odblendzz. HIBACHI with Tiki and Latino influence! Guaranteed to satisfy your taste buds! There\'s only one way, the DTS WAY!" Est. 2020. Recent post: "Officially open for business." 283 followers / 18 posts as of add date. Phone starts 702-986-396 on a post image but the last digit is cut off in the screenshot, so no phone saved. City/address not on the profile (702 area code suggests Las Vegas); needs confirming.'
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
