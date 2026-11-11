#!/bin/bash
# READ-ONLY probe (nothing is written anywhere): how does the Craigslist search API answer for Lamborghini / Ferrari near Las Vegas?
set +e
cat > /tmp/probe.js <<'NODE'
const UA = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)';
async function get(url) { const r = await fetch(url, { headers: { 'user-agent': UA, accept: 'application/json' } }); const t = await r.text(); return { s: r.status, t }; }
(async () => {
  const a = await get('https://reference.craigslist.org/Areas'); console.log('areas HTTP', a.s);
  const areas = JSON.parse(a.t);
  const near = areas.filter(x => /^(lasvegas|mohave|stgeorge|bakersfield|inlandempire|palmsprings|kingman|prescott|flagstaff|reno|cedarcity|modesto)$/i.test(x.Hostname || ''));
  console.log('nearby areas:', near.map(x => x.Hostname + '=' + x.AreaID + ' (' + x.Description + ')').join(' | '));
  const lv = areas.find(x => x.Hostname === 'lasvegas'); console.log('lasvegas:', JSON.stringify(lv));
  const variants = [
    ['plain', ''],
    ['postal+distance100', '&postal=89101&search_distance=100'],
    ['latlon+distance100', '&lat=36.1716&lon=-115.1391&search_distance=100'],
    ['postal+distance30', '&postal=89101&search_distance=30'],
  ];
  for (const q of ['lamborghini', 'ferrari']) for (const [name, extra] of variants) {
    const url = 'https://sapi.craigslist.org/web/v8/postings/search/full?batch=' + lv.AreaID + '-0-360-0-0&cc=' + lv.Country + '&lang=en&searchPath=cta&query=' + q + extra;
    const r = await get(url); let n = '?', first = '';
    try { const d = JSON.parse(r.t).data; n = d.items.length; first = JSON.stringify(d.items.slice(0, 2)).slice(0, 420); if (name === 'plain' && q === 'ferrari') console.log('DECODE keys:', Object.keys(d).join(','), JSON.stringify(d.decode || d.locations || '').slice(0, 300)); } catch (e) { first = r.t.slice(0, 150); }
    console.log(q + ' | ' + name + ' | HTTP ' + r.s + ' | items ' + n + ' | ' + first);
    await new Promise(x => setTimeout(x, 1500));
  }
})().catch(e => console.log('ERR ' + e.message));
NODE
node /tmp/probe.js
