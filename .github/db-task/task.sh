#!/bin/bash
# Read-only: Milk Cow and The Parlor entries in the LVR list (business info only).
node <<'NODE'
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
(async () => {
  const crec = await (await fetch(DB + '/dashboard_crec.json')).json() || {};
  const hit = Object.keys(crec).map(k => crec[k]).filter(r => r && /milk\s*cow|milkcow|parlo/i.test(String(r.name)));
  console.log('matches: ' + hit.length);
  hit.forEach(r => console.log(JSON.stringify({ n: r.name, a: r.address || null, p: r.phone || null, ig: r.instagram || null, igh: r.igHandle || null, cu: r.cuisine || r.category || null, city: r.city || null })));
})();
NODE
