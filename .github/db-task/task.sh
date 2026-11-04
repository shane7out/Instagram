#!/bin/bash
# READ-ONLY audit of the restaurant database (dashboard_crec and the nodes that go with it). It only does GET requests: nothing is
# written, changed or deleted. It prints counts and a few examples per problem (never email addresses) so Shane can decide what to fix.
set +e
cat > /tmp/audit-restaurants.js <<'NODE'
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
async function get(p) {
  const r = await fetch(DB + p + '.json', { signal: AbortSignal.timeout(60000) });
  if (!r.ok) throw new Error('GET ' + p + ' -> HTTP ' + r.status);
  return r.json();
}
const asList = o => !o ? [] : Array.isArray(o) ? o.map((v, i) => [String(i), v]).filter(([, v]) => v) : Object.entries(o).filter(([, v]) => v);
const handleOf = r => String((r && r.instagram) || '').trim();
const norm = s => String(s || '').toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
const ex = (arr, n = 8) => arr.slice(0, n).join('\n      ');
(async () => {
  let crec, custom, stg, deleted, status, attempts, badig;
  try {
    [crec, custom, stg, deleted, status, attempts, badig] = await Promise.all([
      get('/dashboard_crec'), get('/dashboard/customrecords'), get('/dashboard_rest_stg_crec'), get('/dashboard/deleted'),
      get('/dashboard/status'), get('/dashboard/attempts'), get('/dashboard/badig')]);
  } catch (e) { console.log('AUDIT ABORTED (could not read live data): ' + e.message); return; }
  const recs = asList(crec).map(([k, v]) => ({ key: k, r: v }));
  console.log('RESTAURANT AUDIT (read-only)');
  console.log('dashboard_crec records: ' + recs.length + ' | dashboard/customrecords: ' + asList(custom).length + ' | staging queue: ' + asList(stg).length + ' | deleted tombstones: ' + asList(deleted).length);
  console.log('status entries: ' + asList(status).length + ' | attempts entries: ' + asList(attempts).length + ' | flagged bad-IG: ' + asList(badig).length);
  const issues = {};
  const add = (k, line) => { (issues[k] = issues[k] || []).push(line); };
  const label = x => '#' + (x.r.num != null ? x.r.num : x.key) + ' ' + String(x.r.name || '(no name)').slice(0, 40) + (handleOf(x.r) ? ' ' + handleOf(x.r).slice(0, 30) : '');
  const byHandle = {}, byName = {}, byNum = {};
  const statusKeys = new Set(asList(status).map(([k]) => k)), attemptKeys = new Set(asList(attempts).map(([k]) => k));
  const deletedKeys = new Set(asList(deleted).map(([k, v]) => (v && typeof v === 'object' && v.num != null) ? String(v.num) : k));
  for (const x of recs) {
    const r = x.r;
    if (typeof r !== 'object') { add('not a proper record', 'key ' + x.key); continue; }
    if (typeof r.num !== 'number') add('missing a numeric num (invisible to the dashboard maps)', label(x));
    else if (String(r.num) !== x.key) add('num does not match its database key', label(x) + ' (key ' + x.key + ')');
    const num = String(r.num != null ? r.num : x.key);
    byNum[num] = (byNum[num] || 0) + 1;
    if (!String(r.name || '').trim()) add('missing a name', label(x));
    const h = handleOf(r);
    if (!h) add('no Instagram handle (can never show in "needs a DM")', label(x));
    else {
      if (/\s/.test(h)) add('Instagram handle contains spaces', label(x));
      if (/instagram\.com|https?:/i.test(h)) add('Instagram field holds a link instead of a handle', label(x));
      if (!/^@/.test(h) && !/instagram\.com|https?:/i.test(h)) add('Instagram handle missing the leading @', label(x));
      if (/[^A-Za-z0-9._@]/.test(h) && !/\s|instagram\.com|https?:/i.test(h)) add('Instagram handle has unusual characters', label(x));
      const hk = h.toLowerCase().replace(/^@/, '').replace(/.*instagram\.com\//, '').replace(/[/?].*$/, '');
      (byHandle[hk] = byHandle[hk] || []).push(x);
    }
    if (!statusKeys.has(num)) add('no status entry (dashboard shows it blank)', label(x));
    if (!attemptKeys.has(num)) add('no attempts entry', label(x));
    if (deletedKeys.has(num)) add('marked deleted but still in dashboard_crec', label(x));
    if (!String(r.address || '').trim()) add('no address', label(x));
    const digits = String(r.phone || '').replace(/\D/g, '');
    if (String(r.phone || '').trim() && digits.length !== 10 && !(digits.length === 11 && digits[0] === '1')) add('phone number looks malformed', label(x) + ' "' + String(r.phone).slice(0, 20) + '"');
    if (!String(r.cuisine || '').trim()) add('no cuisine', label(x));
    const nk = norm(r.name) + '|' + norm(r.address).slice(0, 18);
    if (norm(r.name)) (byName[nk] = byName[nk] || []).push(x);
  }
  for (const [n, c] of Object.entries(byNum)) if (c > 1) add('two records share one num', 'num ' + n + ' x' + c);
  for (const [h, xs] of Object.entries(byHandle)) if (h && xs.length > 1) add('same Instagram handle on more than one record', '@' + h + ': ' + xs.map(label).join(' / ').slice(0, 150));
  for (const [k, xs] of Object.entries(byName)) if (xs.length > 1) add('same name and address twice', xs.map(label).join(' / ').slice(0, 150));
  const crecNums = new Set(recs.map(x => String(x.r.num != null ? x.r.num : x.key)));
  const orphanStatus = [...statusKeys].filter(k => !crecNums.has(k) && !asList(custom).some(([, v]) => String(v.num) === k) && !deletedKeys.has(k));
  const orphanAttempts = [...attemptKeys].filter(k => !crecNums.has(k) && !asList(custom).some(([, v]) => String(v.num) === k) && !deletedKeys.has(k));
  const customNums = new Set(asList(custom).map(([, v]) => String(v.num)));
  const inCrecNotMirror = [...crecNums].filter(n => !customNums.has(n));
  const inMirrorNotCrec = [...customNums].filter(n => !crecNums.has(n) && !deletedKeys.has(n));
  const order = Object.keys(issues).sort((a, b) => issues[b].length - issues[a].length);
  console.log('\nPROBLEMS FOUND IN dashboard_crec (count, then up to 8 examples):');
  if (!order.length) console.log('  none');
  for (const k of order) console.log('  [' + issues[k].length + '] ' + k + '\n      ' + ex(issues[k]));
  console.log('\nOTHER CHECKS:');
  console.log('  status entries for restaurants that no longer exist anywhere: ' + orphanStatus.length + (orphanStatus.length ? ' e.g. ' + orphanStatus.slice(0, 8).join(', ') : ''));
  console.log('  attempts entries for restaurants that no longer exist anywhere: ' + orphanAttempts.length + (orphanAttempts.length ? ' e.g. ' + orphanAttempts.slice(0, 8).join(', ') : ''));
  console.log('  restaurants in dashboard_crec but missing from the dashboard/customrecords mirror: ' + inCrecNotMirror.length + (inCrecNotMirror.length ? ' e.g. ' + inCrecNotMirror.slice(0, 8).join(', ') : ''));
  console.log('  records in the mirror but not in dashboard_crec (and not deleted): ' + inMirrorNotCrec.length + (inMirrorNotCrec.length ? ' e.g. ' + inMirrorNotCrec.slice(0, 8).join(', ') : ''));
  const noHandle = recs.filter(x => typeof x.r === 'object' && !handleOf(x.r));
  const newest = recs.filter(x => typeof x.r.num === 'number').sort((a, b) => b.r.num - a.r.num).slice(0, 5).map(label);
  console.log('  newest records (highest num): ' + newest.join(' | '));
  console.log('  records with no handle, the top 12 by name: ' + noHandle.slice(0, 12).map(label).join(' | '));
  console.log('\nAUDIT DONE (nothing was changed).');
})().catch(e => console.log('AUDIT ERROR: ' + e.message));
NODE
node /tmp/audit-restaurants.js
