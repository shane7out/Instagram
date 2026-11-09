#!/bin/bash
# ONE-SHOT, Shane's OK (2026-11-09: "yes" = add only the 22 strongest Instagram handles): put the candidate handle for each record into dashboard/igovr/<num> (the dashboard's own
# Instagram-override map: igHandle = igOverrideMap[num] || record.instagram) and clear that record's Bad-IG flag (dashboard/badig/<num>) so it can show as "Need to DM", as in the
# earlier approved handle fixes. Per-key writes only; never overwrites an existing igovr entry; skips a record whose handle is already used by another record (50831 = Birria Bite 50433,
# already in the database). 50818 keeps its earlier-approved @daikonvegansushi. Nothing is deleted except the Bad-IG flag; before-values are logged for undo.
set +e
cat > /tmp/apply.js <<'NODE'
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const get = async p => { const r = await fetch(DB + p + '.json', { signal: AbortSignal.timeout(60000) }); if (!r.ok) throw new Error(p + ' HTTP ' + r.status); return r.json(); };
const send = async (m, p, b) => (await fetch(DB + p + '.json', { method: m, headers: { 'Content-Type': 'application/json' }, body: b === undefined ? undefined : JSON.stringify(b), signal: AbortSignal.timeout(60000) })).status;
const C = [[1429,"takumi_izakaya_lv"],[1436,"triplegeorgelv"],[1576,"parlourlv"],[50010,"olered"],[50400,"domakbbq"],[50816,"woktowalklv"],[50818,"daikonvegansushi"],[50819,"alexisparkresort"],[50820,"lucinospizzalv"],[50822,"vanderpumpparis"],[50825,"brooklynsbestlv"],[50826,"fishersdelilv"],[50827,"halgatteok_lv"],[50832,"hellohibachi"],[50836,"thepinkyring"],[50847,"wabagrill"],[50860,"propereatslasvegas"],[50861,"luchinirestaurant"],[50862,"krispykrunchychicken"],[50887,"netflixbites"],[50888,"goldensteerlv"]];
(async () => {
  let igovr, badig, crec, custom;
  try { igovr = (await get('/dashboard/igovr')) || {}; badig = (await get('/dashboard/badig')) || {}; crec = (await get('/dashboard_crec')) || {}; custom = (await get('/dashboard/customrecords')) || []; }
  catch (e) { console.log('ABORT (could not read live data, nothing written): ' + e.message); return; }
  console.log('BEFORE igovr: ' + JSON.stringify(igovr) + ' | badig count ' + Object.keys(badig).length);
  const norm = s => String(s || '').toLowerCase().replace(/^@/, '').trim();
  const used = new Map();
  [crec, custom].forEach(o => Object.values(o).forEach(r => { if (r && typeof r === 'object') { const h = norm(r.instagram); if (h) used.set(h, r.num + ' ' + r.name); } }));
  Object.entries(igovr).forEach(([n, v]) => { if (norm(v)) used.set(norm(v), 'igovr ' + n); });
  for (const [num, h] of C) {
    if (igovr[num]) { console.log('SKIP ' + num + ': igovr already set to ' + igovr[num]); continue; }
    const other = used.get(h);
    if (other && num !== 50818) { console.log('SKIP ' + num + ': @' + h + ' already used by ' + other); continue; }
    const s1 = await send('PUT', '/dashboard/igovr/' + num, '@' + h);
    let s2 = 'n/a'; const hadBad = badig[num] === true || badig[num] != null;
    if (hadBad) s2 = await send('DELETE', '/dashboard/badig/' + num);
    const back = await get('/dashboard/igovr/' + num), bb = await get('/dashboard/badig/' + num);
    console.log((back === '@' + h && bb == null ? 'OK   ' : 'CHECK') + ' ' + num + ' @' + h + ' (igovr HTTP ' + s1 + ', badig was ' + JSON.stringify(badig[num]) + ' -> cleared HTTP ' + s2 + ')');
  }
  const ig2 = await get('/dashboard/igovr'); console.log('AFTER igovr entries: ' + Object.keys(ig2).length);
})().catch(e => console.log('ERROR: ' + e.message));
NODE
node /tmp/apply.js
