#!/bin/bash
# READ-ONLY audit (2026-11-06 re-run with extra checks) of the restaurant database (dashboard_crec and the nodes that go with it). It only does GET requests: nothing is
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

  // ================= EXTRA CHECKS (2026-11-06) =================
  console.log('\n===== EXTRA CHECKS =====');
  // status values and attempts shape
  const stCount = {}; for (const [, v] of asList(status)) { const k = typeof v === 'string' ? v : JSON.stringify(v); stCount[k] = (stCount[k] || 0) + 1; }
  console.log('status values: ' + JSON.stringify(stCount));
  let badAtt = 0, attWithSend = 0, pendingButSent = [];
  for (const [k, v] of asList(attempts)) {
    const arr = Array.isArray(v) ? v : (v && typeof v === 'object' ? Object.values(v) : null);
    if (!arr) { badAtt++; continue; }
    if (arr.some(a => !a || typeof a !== 'object')) badAtt++;
    const sent = arr.some(a => a && a.date);
    if (sent) attWithSend++;
    if (sent && (asList(status).find(([sk]) => sk === k) || [])[1] === 'pending') pendingButSent.push(k);
  }
  console.log('attempts with a malformed shape: ' + badAtt + ' | restaurants with at least one logged attempt: ' + attWithSend + ' | marked pending but have a logged attempt date: ' + pendingButSent.length + (pendingButSent.length ? ' e.g. ' + pendingButSent.slice(0, 6).join(', ') : ''));
  // junk / test records
  const junk = recs.filter(x => /(^|\b)(test|zz|diagnostic|probe|asdf|lorem)(\b|$)/i.test(String(x.r.name || '')));
  console.log('records whose name looks like a test: ' + junk.length + (junk.length ? ' e.g. ' + junk.slice(0, 6).map(label).join(' | ') : ''));
  const oddName = recs.filter(x => typeof x.r === 'object' && (/^\s|\s$|\s{2,}/.test(String(x.r.name || '')) || /[<>{}]/.test(String(x.r.name || ''))));
  console.log('names with stray spaces or odd characters: ' + oddName.length + (oddName.length ? ' e.g. ' + oddName.slice(0, 6).map(label).join(' | ') : ''));
  const emailBad = recs.filter(x => typeof x.r === 'object' && String(x.r.email || '').trim() && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(x.r.email).trim()));
  console.log('email field present but not an email: ' + emailBad.length + (emailBad.length ? ' e.g. ' + emailBad.slice(0, 6).map(label).join(' | ') : ''));
  const mixed = recs.filter(x => typeof x.r === 'object' && (/@/.test(String(x.r.phone || '')) || /^\d[\d\s().+-]{6,}$/.test(handleOf(x.r))));
  console.log('phone/handle fields mixed up (an @ in the phone, or a number in the handle): ' + mixed.length + (mixed.length ? ' e.g. ' + mixed.slice(0, 6).map(label).join(' | ') : ''));
  const notLV = recs.filter(x => typeof x.r === 'object' && String(x.r.address || '').trim() && !/\b(NV|Nevada|Las Vegas|Henderson|North Las Vegas|Summerlin|Boulder City)\b/i.test(String(x.r.address)));
  console.log('addresses that do not mention Nevada or a Las Vegas-area city: ' + notLV.length + (notLV.length ? ' e.g. ' + notLV.slice(0, 5).map(label).join(' | ') : ''));
  // numbering: collisions across crec, staging, tombstones
  const stgNums = asList(stg).map(([k, v]) => String((v && v.num != null) ? v.num : k));
  const clash = stgNums.filter(n => crecNums.has(n));
  console.log('staging-queue records that share a num with a live record: ' + clash.length + (clash.length ? ' e.g. ' + clash.slice(0, 6).join(', ') : ''));
  const reused = [...crecNums].filter(n => deletedKeys.has(n));
  console.log('nums that are both live and tombstoned (deleted): ' + reused.length + (reused.length ? ' e.g. ' + reused.slice(0, 6).join(', ') : ''));
  const numsSorted = [...crecNums].map(Number).filter(n => !isNaN(n)).sort((a, b) => a - b);
  console.log('num range: ' + numsSorted[0] + ' to ' + numsSorted[numsSorted.length - 1]);
  // Instagram index vs records
  try {
    const idx = await get('/lvr_instagram_index');
    const keys = Object.keys(idx || {});
    const hset = new Set(Object.keys(byHandle));
    const norm2 = k => String(k).toLowerCase().replace(/^@/, '').replace(/[,]/g, '.');
    const idxSet = new Set(keys.map(norm2));
    const missing = [...hset].filter(h => !idxSet.has(h));
    const stale = [...idxSet].filter(h => !hset.has(h));
    console.log('Instagram index entries: ' + keys.length + ' | record handles not in the index: ' + missing.length + (missing.length ? ' e.g. ' + missing.slice(0, 6).join(', ') : '') + ' | index entries with no record: ' + stale.length + (stale.length ? ' e.g. ' + stale.slice(0, 6).join(', ') : ''));
  } catch (e) { console.log('Instagram index: ' + e.message); }
  // members of the rewards program (counts only, no personal details)
  try {
    const mem = await get('/lvr_rewards');
    const ms = asList(mem).map(([k, v]) => v).filter(v => v && typeof v === 'object');
    const byStatus = {}; ms.forEach(m => { const k = m.status || '(no status)'; byStatus[k] = (byStatus[k] || 0) + 1; });
    const noEmail = ms.filter(m => !String(m.email || '').trim()).length, noName = ms.filter(m => !String(m.name || '').trim()).length, noPhone = ms.filter(m => !String(m.phone || '').trim()).length, noToken = ms.filter(m => !m.token).length;
    const badPts = ms.filter(m => typeof m.points !== 'number' || m.points < 0).length;
    const em = {}, ph = {}; ms.forEach(m => { const e = String(m.email || '').trim().toLowerCase(); if (e) em[e] = (em[e] || 0) + 1; const p = String(m.phone || '').replace(/\D/g, ''); if (p) ph[p] = (ph[p] || 0) + 1; });
    console.log('REWARDS MEMBERS: ' + ms.length + ' | by status: ' + JSON.stringify(byStatus) + ' | missing name/email/phone/token: ' + [noName, noEmail, noPhone, noToken].join('/') + ' | points not a number or negative: ' + badPts + ' | duplicate emails: ' + Object.values(em).filter(c => c > 1).length + ' | duplicate phones: ' + Object.values(ph).filter(c => c > 1).length);
  } catch (e) { console.log('Rewards members: ' + e.message); }
  // website leads and the Key Technologies CRM (counts only)
  try {
    const leads = asList(await get('/key_leads/leads')).map(([k, v]) => v).filter(v => v && typeof v === 'object');
    const bySrc = {}; leads.forEach(l => { const k = l.source || '(no source)'; bySrc[k] = (bySrc[k] || 0) + 1; });
    console.log('WEBSITE LEADS: ' + leads.length + ' | by source: ' + JSON.stringify(bySrc) + ' | without an email: ' + leads.filter(l => !String(l.email || '').trim()).length + ' | without a phone: ' + leads.filter(l => !String(l.phone || '').trim()).length + ' | without a name: ' + leads.filter(l => !String(l.name || '').trim()).length + ' | with first/last name saved: ' + leads.filter(l => l.firstName).length);
  } catch (e) { console.log('Website leads: ' + e.message); }
  try {
    const pr = asList(await get('/kt_crm/prospects')).map(([k, v]) => v).filter(v => v && typeof v === 'object');
    console.log('KEY TECHNOLOGIES CRM prospects: ' + pr.length + ' | missing a name: ' + pr.filter(p => !String(p.name || p.business || '').trim()).length);
  } catch (e) { console.log('CRM prospects: ' + e.message); }
  console.log('\nAUDIT DONE (nothing was changed).');
})().catch(e => console.log('AUDIT ERROR: ' + e.message));
NODE
node /tmp/audit-restaurants.js
