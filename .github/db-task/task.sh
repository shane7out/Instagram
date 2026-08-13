#!/bin/bash
# DIAGNOSTIC: dump the raw sapi search response structure (find lat/lon + posted-time + postal filter behavior).
set -e
node <<'NODE'
const https=require('https'), zlib=require('zlib');
const UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36';
function fetch(url){return new Promise((res,rej)=>{
  const req=https.get(url,{headers:{'user-agent':UA,'accept-encoding':'gzip,deflate',accept:'application/json'}},r=>{
    const c=[];r.on('data',x=>c.push(x));r.on('end',()=>{let b=Buffer.concat(c);try{if(b[0]===0x1f&&b[1]===0x8b)b=zlib.gunzipSync(b);}catch(_){}res({status:r.statusCode,buf:b});});
  });req.on('error',rej);req.setTimeout(30000,()=>req.destroy(new Error('timeout')));
});}
(async()=>{
  const ar=await fetch('https://reference.craigslist.org/Areas');
  const areas=JSON.parse(ar.buf.toString());
  const med=areas.find(a=>String(a.Hostname||'').toLowerCase()==='medford');
  console.log('medford:', JSON.stringify(med));
  const base='https://sapi.craigslist.org/web/v8/postings/search/full?batch='+med.AreaID+'-0-360-0-0&cc=US&lang=en&searchPath=rea&query=land';
  for (const variant of ['','&postal=97524&search_distance=5','&lat=42.4726&lon=-122.8031&search_distance=5']){
    const r=await fetch(base+variant);
    let j; try{ j=JSON.parse(r.buf.toString()); }catch(e){ console.log('variant',variant||'(none)','parse fail', r.status); continue; }
    const d=j.data||{};
    console.log('=== variant:', variant||'(none)', '| status', r.status, '| items:', (d.items||[]).length);
    if(variant===''){
      console.log('data keys:', Object.keys(d).join(','));
      const it=(d.items||[])[0];
      console.log('first item RAW:', JSON.stringify(it).slice(0,800));
      // any decode tables?
      for(const k of Object.keys(d)){ if(k!=='items'){ console.log('  d.'+k+':', JSON.stringify(d[k]).slice(0,400)); } }
    }
  }
})().catch(e=>{console.log('ERR',e.message);process.exit(1);});
NODE
