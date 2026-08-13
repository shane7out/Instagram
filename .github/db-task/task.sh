#!/bin/bash
# Eagle Point land sweep v2: all land within 5 miles of 97524, newest first,
# exact distance filter from each listing's own coordinates.
set -e
node <<'NODE'
const https=require('https'), fs=require('fs'), zlib=require('zlib');
const UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36';
function fetch(url){return new Promise((res,rej)=>{
  const req=https.get(url,{headers:{'user-agent':UA,'accept-encoding':'gzip,deflate',accept:'application/json'}},r=>{
    if(r.statusCode>=300&&r.statusCode<400&&r.headers.location){r.resume();return fetch(r.headers.location).then(res,rej);}
    const c=[];r.on('data',x=>c.push(x));r.on('end',()=>{let b=Buffer.concat(c);try{if(b[0]===0x1f&&b[1]===0x8b)b=zlib.gunzipSync(b);}catch(_){}res({status:r.statusCode,buf:b});});
  });req.on('error',rej);req.setTimeout(30000,()=>req.destroy(new Error('timeout')));
});}
async function fetchR(url,t){t=t||3;for(let a=0;a<t;a++){try{const r=await fetch(url);if(r.status===200)return r;}catch(e){}await new Promise(r=>setTimeout(r,1200*(a+1)));}return null;}

// item: [id, ?, ?, price, "d:n~lat~lon", ?, [13,token], [4,imgs...], [6,slug], [10,"$fmt"], ..., "title"]
function parseItem(it){
  const o={price:(typeof it[3]==='number'&&it[3]>0)?it[3]:null, images:[], lat:null, lon:null};
  for(let i=0;i<it.length;i++){const v=it[i];
    if(typeof v==='string'){
      const m=v.match(/^\d+:\d+~(-?\d+(?:\.\d+)?)~(-?\d+(?:\.\d+)?)$/);
      if(m){o.lat=parseFloat(m[1]);o.lon=parseFloat(m[2]);}
      else if(i>=5&&!/^[0-9:]+[A-Za-z0-9]*$/.test(v)&&v.length>8)o.title=o.title||v;
    } else if(Array.isArray(v)){
      if(v[0]===4)o.images=v.slice(1);
      else if(v[0]===6)o.slug=v[1];
      else if(v[0]===13)o.token=v[1];
      else if(v[0]===10&&typeof v[1]==='string')o.priceFmt=v[1];
    }
  }
  return o;
}
const imgUrl=raw=>'https://images.craigslist.org/'+String(raw).replace(/^\d+:/,'')+'_600x450.jpg';
const LAT=42.4726, LON=-122.8031, RADIUS_MI=5.5;
function miles(a,b,c,d){const R=3958.8,r=x=>x*Math.PI/180;const h=Math.sin(r(c-a)/2)**2+Math.cos(r(a))*Math.cos(r(c))*Math.sin(r(d-b)/2)**2;return 2*R*Math.asin(Math.sqrt(h));}
const LANDISH=/\b(land|acre|acres|acreage|lot|lots|parcel|property|homesite|home ?site)\b/i;
const HOUSE=/\b(\d+\s*(bed|bd|br)\b|bedroom|bathroom|\bbath\b|manufactured home|mobile home|\bhouse for (sale|rent)\b|apartment|duplex)\b/i;

(async()=>{
  const ar=await fetchR('https://reference.craigslist.org/Areas');
  const areas=JSON.parse(ar.buf.toString());
  const med=areas.find(a=>String(a.Hostname||'').toLowerCase()==='medford');
  console.error('medford AreaID: '+med.AreaID);
  // one pass: ALL real estate near 97524 within 5 mi, newest first (sort=date keeps API order)
  const url='https://sapi.craigslist.org/web/v8/postings/search/full?batch='+med.AreaID+'-0-360-0-0&cc=US&lang=en&searchPath=rea&postal=97524&search_distance=5&sort=date';
  const r=await fetchR(url,3);
  const d=JSON.parse(r.buf.toString()).data;
  console.error('raw items: '+(d.items||[]).length+' | totalResultCount: '+d.totalResultCount);
  const seen={}; const list=[];
  (d.items||[]).forEach(raw=>{
    const it=parseItem(raw);
    if(!it.token||!it.title)return;
    if(seen[it.token])return; seen[it.token]=1;
    if(it.lat!=null){ it.dist=miles(LAT,LON,it.lat,it.lon); if(it.dist>RADIUS_MI)return; }
    if(!LANDISH.test(it.title))return;
    if(HOUSE.test(it.title))return;
    list.push(it);       // response is sort=date → keep order = just listed first
  });
  console.error('kept (land, ≤5mi, newest first): '+list.length);
  list.forEach(it=>console.error('  · '+(it.priceFmt||(it.price?('$'+it.price):'—'))+' | '+(it.dist!=null?it.dist.toFixed(1)+'mi':'?')+' | '+String(it.title).slice(0,60)));

  const esc=s=>String(s==null?'':s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
  const card=e=>{
    const img=e.images&&e.images[0]?imgUrl(e.images[0]):'';
    const price=e.priceFmt||(e.price?('$'+Number(e.price).toLocaleString()):'—');
    const src='https://www.craigslist.org/view/d/'+esc(e.slug||'')+'/'+esc(e.token);
    const more=(e.images&&e.images.length>1)?('<div class="count">'+e.images.length+' photos</div>'):'';
    const dist=e.dist!=null?('<div class="loc">📍 '+e.dist.toFixed(1)+' mi from Eagle Point</div>'):'';
    return `<a class="card" href="${src}" target="_blank" rel="noopener">
    <div class="ph">${img?`<img loading="lazy" referrerpolicy="no-referrer" src="${esc(img)}" alt="${esc(e.title)}">`:'<div class="noph">no photo</div>'}${more}</div>
    <div class="body"><div class="price">${esc(price)}</div><div class="title">${esc(e.title)}</div>
    ${dist}<div class="cta">View on Craigslist →</div></div>
  </a>`;
  };
  const cards=list.map(card).join('\n');
  const html=`<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Eagle Point Land — within 5 mi of 97524</title>
<meta name="description" content="Land for sale within 5 miles of Eagle Point, Oregon 97524, found on Craigslist. Newest first.">
<style>
:root{--blue:#0d47a1;--line:#e3e8f0;--text:#0f1f36;--muted:#5c6b82}
*{box-sizing:border-box}body{margin:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;background:#f5f7fa;color:var(--text)}
header{background:var(--blue);color:#fff;padding:18px 20px;display:flex;align-items:center;gap:12px}
header a{color:#fff;text-decoration:none;font-weight:700;font-size:14px;opacity:.9}
header h1{font-size:20px;margin:0;font-weight:800}
.wrap{max-width:1100px;margin:0 auto;padding:20px}
.sub{color:var(--muted);font-size:14px;margin:0 0 18px}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:16px}
.card{background:#fff;border:1px solid var(--line);border-radius:14px;overflow:hidden;text-decoration:none;color:inherit;display:flex;flex-direction:column;transition:box-shadow .15s,transform .15s}
.card:hover{box-shadow:0 10px 28px rgba(13,40,80,.14);transform:translateY(-2px)}
.ph{position:relative;aspect-ratio:4/3;background:#eef2f8}
.ph img{width:100%;height:100%;object-fit:cover;display:block}
.noph{display:flex;align-items:center;justify-content:center;height:100%;color:var(--muted);font-size:14px}
.count{position:absolute;right:10px;bottom:10px;background:rgba(6,28,68,.85);color:#fff;font-size:12px;font-weight:700;padding:4px 10px;border-radius:11px}
.body{padding:14px}
.price{font-size:22px;font-weight:800;color:var(--blue)}
.title{font-weight:700;margin:4px 0;font-size:15px;line-height:1.3}
.loc{color:var(--muted);font-size:13px}
.cta{margin-top:10px;color:var(--blue);font-weight:700;font-size:13px}
.empty{color:var(--muted);padding:40px 0;text-align:center}
footer{color:var(--muted);font-size:12px;text-align:center;padding:24px}
</style></head><body>
<header><a href="/">← Deals</a><h1>🌲 Eagle Point Land · 5 mi of 97524</h1></header>
<div class="wrap">
<p class="sub">Land for sale within 5 miles of Eagle Point, Oregon (97524). Just-listed first. Tap a listing to open the original ad. ${list.length} matches.</p>
<div class="grid">${cards||'<div class="empty">No land listings right now — check back soon.</div>'}</div>
</div>
<footer>Refreshed from Craigslist · classiccarsforsale-co</footer>
</body></html>`;
  fs.writeFileSync('.github/db-task/fetched/land-eaglepoint.html',html);
  console.error('wrote land-eaglepoint.html ('+html.length+' bytes, '+list.length+' cards)');
})().catch(e=>{console.error('ERR '+e.message);process.exit(1);});
NODE
git config user.name "Claude"
git config user.email "noreply@anthropic.com"
git add .github/db-task/fetched/land-eaglepoint.html
git commit -m "fetched: Eagle Point land page v2 (exact 5mi, newest first)" || echo "no change"
git push
