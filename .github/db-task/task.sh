#!/bin/bash
# Read-only look at what the LVR restaurant list holds (business name/address/Instagram only, no contact details).
node <<'NODE'
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
(async () => {
  const crec = await (await fetch(DB + '/dashboard_crec.json')).json() || {};
  const ks = Object.keys(crec);
  console.log('records: ' + ks.length);
  const freq = {};
  ks.forEach(k => Object.keys(crec[k] || {}).forEach(f => freq[f] = (freq[f] || 0) + 1));
  console.log('fields: ' + Object.keys(freq).map(f => f + '=' + freq[f]).join(', '));
  const ok = ks.filter(k => { const r = crec[k] || {}; return r.name && r.instagram && (r.address || r.addr || r.street); });
  console.log('with name+instagram+address: ' + ok.length);
  ok.slice(0, 400).sort(() => 0.5 - Math.random()).slice(0, 30).forEach(k => { const r = crec[k]; console.log('- ' + r.name + ' | ' + (r.address || r.addr || r.street) + ' | ' + r.instagram + (r.category ? ' | ' + r.category : '') + (r.cuisine ? ' | ' + r.cuisine : '')); });
})();
NODE
