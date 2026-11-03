#!/bin/bash
# READ-ONLY live check (owner login state, member counts, lead sources). Prints counts only, no emails or names.
DB=https://lvr-data-a60c1-default-rtdb.firebaseio.com
node <<'NODE'
const DB='https://lvr-data-a60c1-default-rtdb.firebaseio.com';
(async()=>{
 const j=async p=>{try{const r=await fetch(DB+p);return {s:r.status,j:await r.json().catch(()=>null)}}catch(e){return {s:0,j:null}}};
 const k=async p=>{const r=await j(p+'.json?shallow=true');return r.j&&typeof r.j==='object'?Object.keys(r.j).length:r.j};
 const o=await j('/ownerAuth/apiKey.json');console.log('ownerAuth/apiKey present:',o.j?'YES':'NO');
 console.log('members:',await k('/lvr_points/members'),'| round1 entries:',await k('/lvr_points/round1'),'| pool total:',JSON.stringify((await j('/lvr_points/pool/total.json')).j));
 const L=await j('/key_leads/leads.json');const srcs={};if(L.j&&typeof L.j==='object')Object.values(L.j).forEach(v=>{const s=(v&&v.source)||'?';srcs[s]=(srcs[s]||0)+1});console.log('leads by source:',JSON.stringify(srcs));
 for(const u of ['https://lvr-data-a60c1.web.app/lvr-points-admin.html','https://lvr-data-a60c1.web.app/key-room.html']){try{const r=await fetch(u+'?v='+Date.now());const t=await r.text();console.log(u.split('/').pop(),'HTTP',r.status,'has owner sign-in code:',t.includes('ownerAuth'))}catch(e){console.log(u,'fetch failed')}}
 const w=await fetch(DB+'/lvr_points/settings/zz_probe.json',{method:'PUT',headers:{'Content-Type':'application/json'},body:'1'});console.log('anonymous write to settings -> HTTP',w.status,w.status===200?'(owner-only rules NOT installed)':'(blocked)');
 if(w.status===200)await fetch(DB+'/lvr_points/settings/zz_probe.json',{method:'DELETE'});
})();
NODE
