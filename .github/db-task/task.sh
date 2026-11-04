#!/bin/bash
# Safe clean-up of the restaurant database (dashboard_crec) found by the read-only audit of 2026-11-04. Three fixes, each logged
# with before/after, each skipped if the data is not exactly as the audit saw it:
#   A. Instagram handles saved without the leading "@" get the "@" (same format as the other ~850 records).
#   B. #50281 Mura Japanese BBQ & Shabu has its Instagram handle (@mura_lv) in the PHONE field: move it to the instagram field.
#   C. Records saved under a random push key (-P3D5...) instead of their own num (#60001-#60020) are moved to dashboard_crec/<num>
#      (the dashboard writes edits to that key): copy -> verify -> delete the old key, only if the num key is still empty.
# Nothing else is touched. Aborts without writing if the live data cannot be read or the plan looks wrong (too many changes).
set +e
cat > /tmp/clean-restaurants.js <<'NODE'
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const J = { 'Content-Type': 'application/json' };
const T = () => AbortSignal.timeout(60000);
async function get(p) { const r = await fetch(DB + p + '.json', { signal: T() }); if (!r.ok) throw new Error('GET ' + p + ' -> HTTP ' + r.status); return r.json(); }
async function send(method, p, body, extra) {
  const r = await fetch(DB + p + '.json', { method, headers: Object.assign({}, J, extra || {}), body: body === undefined ? undefined : JSON.stringify(body), signal: T() });
  return r.status;
}
const handleOf = r => String((r && r.instagram) || '').trim();
(async () => {
  let crec;
  try { crec = await get('/dashboard_crec'); } catch (e) { console.log('ABORT (could not read live data, nothing written): ' + e.message); return; }
  if (!crec || typeof crec !== 'object') { console.log('ABORT (dashboard_crec empty/unreadable, nothing written)'); return; }
  const entries = Object.entries(crec).filter(([, v]) => v && typeof v === 'object');
  // ---- plan
  const addAt = entries.filter(([, r]) => { const h = handleOf(r); return h && !/^@/.test(h) && /^[A-Za-z0-9._]+$/.test(h); });
  const mura = entries.find(([, r]) => r.num === 50281 && !handleOf(r) && String(r.phone || '').trim() === '@mura_lv');
  const moves = entries.filter(([k, r]) => typeof r.num === 'number' && String(r.num) !== k && /^-/.test(k));
  console.log('PLAN: add "@" to ' + addAt.length + ' handles | fix Mura phone/handle: ' + (mura ? 'yes' : 'no') + ' | move ' + moves.length + ' records to their own key');
  if (addAt.length > 60 || moves.length > 40) { console.log('ABORT (plan is bigger than the audit showed, nothing written)'); return; }
  // ---- A. add the leading @
  let aOk = 0;
  for (const [k, r] of addAt) {
    const before = handleOf(r), after = '@' + before;
    const s = await send('PUT', '/dashboard_crec/' + encodeURIComponent(k) + '/instagram', after);
    const back = await get('/dashboard_crec/' + encodeURIComponent(k) + '/instagram');
    const ok = s === 200 && back === after; if (ok) aOk++;
    console.log((ok ? 'FIXED  ' : 'FAILED ') + '#' + r.num + ' ' + String(r.name).slice(0, 34) + ': "' + before + '" -> "' + after + '"');
  }
  // ---- B. Mura
  if (mura) {
    const [k, r] = mura;
    const s = await send('PATCH', '/dashboard_crec/' + encodeURIComponent(k), { instagram: '@mura_lv', phone: '' });
    const back = await get('/dashboard_crec/' + encodeURIComponent(k));
    console.log((s === 200 && back.instagram === '@mura_lv' && back.phone === '' ? 'FIXED  ' : 'FAILED ') + '#50281 ' + r.name + ': phone "@mura_lv" -> instagram "@mura_lv", phone empty');
  }
  // ---- C. move records stored under random keys to their own num key
  let cOk = 0;
  for (const [oldKey, r0] of moves) {
    const fresh = await get('/dashboard_crec/' + encodeURIComponent(oldKey)); // pick up fix A if it applied
    if (!fresh || fresh.num !== r0.num) { console.log('SKIP   #' + r0.num + ': record changed since the audit'); continue; }
    const newKey = String(fresh.num);
    const s1 = await send('PUT', '/dashboard_crec/' + newKey, fresh, { 'if-match': 'null_etag' }); // only if that key is still empty
    if (s1 !== 200) { console.log('SKIP   #' + fresh.num + ': key ' + newKey + ' is already in use (HTTP ' + s1 + '), left where it is'); continue; }
    const back = await get('/dashboard_crec/' + newKey);
    if (JSON.stringify(back) !== JSON.stringify(fresh)) { console.log('FAILED #' + fresh.num + ': copy did not match, old copy kept'); continue; }
    const s2 = await send('DELETE', '/dashboard_crec/' + encodeURIComponent(oldKey));
    const gone = (await get('/dashboard_crec/' + encodeURIComponent(oldKey))) === null;
    if (s2 === 200 && gone) { cOk++; console.log('MOVED  #' + fresh.num + ' ' + String(fresh.name).slice(0, 34) + ': key ' + oldKey + ' -> ' + newKey); }
    else console.log('FAILED #' + fresh.num + ': copy is in place but the old key was not removed (HTTP ' + s2 + ')');
  }
  // ---- recount from the live data
  const after = Object.entries(await get('/dashboard_crec')).filter(([, v]) => v && typeof v === 'object');
  const left = {
    'handles still missing the @': after.filter(([, r]) => { const h = handleOf(r); return h && !/^@/.test(h) && /^[A-Za-z0-9._]+$/.test(h); }).length,
    'records still under a random key': after.filter(([k, r]) => typeof r.num === 'number' && String(r.num) !== k && /^-/.test(k)).length,
    'records with no handle': after.filter(([, r]) => !handleOf(r)).length,
    'total records': after.length
  };
  console.log('\nRESULT: @ added ' + aOk + '/' + addAt.length + ' | moved ' + cOk + '/' + moves.length + ' | after the clean-up: ' + JSON.stringify(left));
})().catch(e => console.log('ERROR: ' + e.message));
NODE
node /tmp/clean-restaurants.js
