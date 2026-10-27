#!/bin/bash
# Read-only: business name / address / phone / cuisine / Instagram for the 12 demo restaurants only (no emails, owner names or notes).
node <<'NODE'
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const NAMES = ["Peru Chicken","Noodle King","Lester's Deli Las Vegas","The Beach House","Smoking Pig BBQ Company","Black Mountain Griddle","The Irish Spot","Sourdough & Co","Yu by Sijie","Finney's Crafthouse","Wagyu Factory","Royale Frites"];
(async () => {
  const crec = await (await fetch(DB + '/dashboard_crec.json')).json() || {};
  const all = Object.keys(crec).map(k => crec[k]).filter(Boolean);
  NAMES.forEach(n => {
    const r = all.find(x => String(x.name).trim().toLowerCase() === n.toLowerCase());
    if (!r) { console.log('NOT FOUND: ' + n); return; }
    console.log(JSON.stringify({ n: r.name, a: r.address || null, p: r.phone || null, cu: r.cuisine || null, cat: r.category || null, ig: r.instagram || null, igh: r.igHandle || null }));
  });
})();
NODE
