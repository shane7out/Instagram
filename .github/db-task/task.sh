#!/bin/bash
# Read-only check after the owner ran rr-pin-setup.sh on the Mac: reads the setup report and shows whether the ledger rules are live. Changes nothing.
node <<'NODE'
const DB='https://lvr-data-a60c1-default-rtdb.firebaseio.com';
(async()=>{
 for(const p of ['_debug/rrpin','rr_ledger/meta','rr_ledger/entries','rr_ledger/wallets']){
  try{const r=await fetch(DB+'/'+p+'.json?shallow=true');const t=await r.text();console.log('GET '+p+' -> HTTP '+r.status+' '+t.slice(0,3000));}catch(e){console.log('GET '+p+' failed '+e.message);}
 }
 for(const u of ['https://keytechnologies.si/key-platform/rr-auth.js','https://keytechnologies.si/restaurant-rewards-treasury.html']){
  try{const r=await fetch(u+'?v='+Date.now());const t=await r.text();console.log(u+' HTTP '+r.status+' faceid='+t.includes('rrBio')+' key-modern='+t.includes('key-modern'));}catch(e){console.log(u+' failed')}
 }
})();
NODE
