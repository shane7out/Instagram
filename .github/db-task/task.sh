#!/bin/bash
# Read-only: restaurants in the LVR list that have address + phone + Instagram (business info only; no emails, owners or notes).
node <<'NODE'
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
(async () => {
  const crec = await (await fetch(DB + '/dashboard_crec.json')).json() || {};
  const all = Object.keys(crec).map(k => crec[k]).filter(Boolean);
  const ok = all.filter(r => r.name && r.instagram && r.address && r.phone && /\d{3}.*\d{4}/.test(String(r.address) + '') === false || (r.name && r.instagram && r.address && r.phone));
  const withStreet = ok.filter(r => /^\d+\s/.test(String(r.address).trim()) && /NV/i.test(String(r.address)));
  console.log('address+phone+instagram: ' + ok.length + ', with a street number in NV: ' + withStreet.length);
  withStreet.sort((a, b) => (a.name > b.name ? 1 : -1)).slice(0, 60).forEach(r => console.log(JSON.stringify({ n: r.name, a: r.address, p: r.phone, cu: r.cuisine || r.category || null, ig: r.instagram })));
})();
NODE
