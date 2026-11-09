#!/bin/bash
# READ-ONLY inspection (Shane OK'd adding the 22 strongest Instagram handles, 2026-11-09): show how each of the 22 records is stored today
# (dashboard_crec/<num>, its copy in dashboard/customrecords, dashboard/badig, dashboard/igovr, status) and whether the candidate handle is already used by another record.
set +e
cat > /tmp/insp.js <<'NODE'
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const get = async p => { const r = await fetch(DB + p + '.json', { signal: AbortSignal.timeout(60000) }); if (!r.ok) throw new Error(p + ' HTTP ' + r.status); return r.json(); };
const C = [[1429,"takumi_izakaya_lv"],[1436,"triplegeorgelv"],[1576,"parlourlv"],[50010,"olered"],[50400,"domakbbq"],[50816,"woktowalklv"],[50818,"daikonvegansushigroup"],[50819,"alexisparkresort"],[50820,"lucinospizzalv"],[50822,"vanderpumpparis"],[50825,"brooklynsbestlv"],[50826,"fishersdelilv"],[50827,"halgatteok_lv"],[50831,"birriabite"],[50832,"hellohibachi"],[50836,"thepinkyring"],[50847,"wabagrill"],[50860,"propereatslasvegas"],[50861,"luchinirestaurant"],[50862,"krispykrunchychicken"],[50887,"netflixbites"],[50888,"goldensteerlv"]];
(async () => {
  const crec = await get('/dashboard_crec'), custom = await get('/dashboard/customrecords'), badig = await get('/dashboard/badig'), igovr = await get('/dashboard/igovr'), status = await get('/dashboard/status');
  console.log('types: crec ' + (Array.isArray(crec) ? 'array' : typeof crec) + ' custom ' + (Array.isArray(custom) ? 'array' : typeof custom) + ' badig ' + (Array.isArray(badig) ? 'array' : JSON.stringify(badig).slice(0, 120)) + ' igovr ' + JSON.stringify(igovr).slice(0, 200));
  const all = [crec, custom].map(o => Object.values(o || {}).filter(r => r && typeof r === 'object'));
  const norm = s => String(s || '').toLowerCase().replace(/^@/, '').trim();
  for (const [num, h] of C) {
    const c = crec && crec[num]; const cu = (all[1] || []).filter(r => Number(r.num) === num);
    const dup = all.flat().filter(r => norm(r.instagram || r.igHandle) === h && Number(r.num) !== num).map(r => r.num + ' ' + String(r.name).slice(0, 25));
    console.log(num + ' crec=' + JSON.stringify(c ? { name: c.name, instagram: c.instagram, igHandle: c.igHandle, keys: Object.keys(c).length } : null) + ' custom=' + JSON.stringify(cu.map(r => ({ i: r.instagram, ih: r.igHandle }))) +
      ' badig=' + JSON.stringify(Array.isArray(badig) ? badig[num] : (badig || {})[num]) + ' igovr=' + JSON.stringify((igovr || {})[num]) + ' status=' + JSON.stringify((status || {})[num]) + ' dupHandle=' + JSON.stringify(dup));
  }
})().catch(e => console.log('ERROR ' + e.message));
NODE
node /tmp/insp.js
