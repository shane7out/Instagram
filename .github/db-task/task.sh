#!/bin/bash
# Worldwide Craigslist sweep for US coins $100-$1000, build a standalone coins.html,
# and commit it to the repo (deploy happens on the Mac).
set -e
node <<'NODE'
const https=require('https'), fs=require('fs'), zlib=require('zlib');
const UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36';
function fetch(url,bin){return new Promise((res,rej)=>{
  const req=https.get(url,{headers:{'user-agent':UA,'accept-encoding':'gzip,deflate',accept:bin?'*/*':'application/json'}},r=>{
    if(r.statusCode>=300&&r.statusCode<400&&r.headers.location){r.resume();return fetch(r.headers.location,bin).then(res,rej);}
    const c=[];r.on('data',x=>c.push(x));r.on('end',()=>{let b=Buffer.concat(c);const e=(r.headers['content-encoding']||'').toLowerCase();try{if(e==='gzip'||(b[0]===0x1f&&b[1]===0x8b))b=zlib.gunzipSync(b);else if(e==='deflate')b=zlib.inflateSync(b);}catch(_){}res({status:r.statusCode,buf:b});});
  });
  req.on('error',rej);req.setTimeout(30000,()=>req.destroy(new Error('timeout')));
});}
async function fetchR(url,bin,t){t=t||3;for(let a=0;a<t;a++){try{const r=await fetch(url,bin);if(r.status===200)return r;if(a===t-1)return r;}catch(e){if(a===t-1)return null;}await new Promise(r=>setTimeout(r,1200*(a+1)));}}
function parseItem(it){const o={price:it[3],images:[]};for(let i=5;i<it.length;i++){const v=it[i];if(typeof v==='string')o.title=v;else if(Array.isArray(v)){if(v[0]===4)o.images=v.slice(1);else if(v[0]===6)o.slug=v[1];else if(v[0]===13)o.token=v[1];}}return o;}
const imgUrl=raw=>'https://images.craigslist.org/'+String(raw).replace(/^\d+:/,'')+'_600x450.jpg';
async function pmap(arr,fn,n){const out=[];let i=0;const w=Array.from({length:n},async()=>{while(i<arr.length){const k=i++;out[k]=await fn(arr[k]).catch(()=>null);}});await Promise.all(w);return out;}

const COIN=/\b(coins?|morgan|peace dollar|silver dollar|half dollar|walking liberty|mercury dime|barber|franklin|buffalo nickel|indian head|lincoln cent|wheat penn(y|ies)|silver eagle|gold coin|proof set|mint set|numismat|bullion|krugerrand|double eagle|seated liberty|standing liberty|kennedy half|susan b|sacagawea|commemorative coin)\b/i;
const USA=/\b(us|u\.?s\.?|usa|america|american|morgan|peace|walking liberty|mercury|barber|franklin|buffalo|indian head|lincoln|wheat|kennedy|eagle|susan b|sacagawea|liberty|washington|jefferson|roosevelt)\b/i;
const BAD=/\b(bitcoin|crypto|litecoin|dogecoin|ethereum|arcade|laundr|washer|dryer|token machine|coin op|coin-op|coinstar|counter|sorter|pusher|wanted|wtb|looking for|looking to buy|i buy|we buy|buying|paying|top dollar|cash (?:paid|for)|will pay|replica|repro|reproduction|copy coin|copy replica|tribute|novelty|pamphlet|stamps? only)\b/i;

(async()=>{
  const ar=await fetchR('https://reference.craigslist.org/Areas',false);
  const areas=JSON.parse(ar.buf.toString());
  console.error('areas: '+areas.length);
  const byTok={};
  await pmap(areas,async a=>{
    const url='https://sapi.craigslist.org/web/v8/postings/search/full?batch='+a.AreaID+'-0-360-0-0&cc='+a.Country+'&lang=en&searchPath=sss&query=coins&min_price=100&max_price=1000';
    const r=await fetchR(url,false,2); if(!r)return;
    let d;try{d=JSON.parse(r.buf.toString()).data;}catch(e){return;}
    if(!d||!Array.isArray(d.items))return;
    d.items.forEach(raw=>{const it=parseItem(raw);
      if(!it.token||!it.title)return;
      if(!(typeof it.price==='number'&&it.price>=100&&it.price<=1000))return;
      if(!byTok[it.token]){it.where=(a.Description||a.Hostname)+(a.Country&&a.Country!=='US'?(', '+a.Country):'');byTok[it.token]=it;}
    });
  },8);
  let list=Object.values(byTok).filter(it=>{
    const t=it.title||'';
    return COIN.test(t)&&USA.test(t)&&!BAD.test(t);
  });
  // most photos first, then keep it reasonable
  list.sort((a,b)=>(b.images.length-a.images.length)||(a.price-b.price));
  const total=list.length;
  list=list.slice(0,150);
  console.error('coin listings kept: '+total+' (showing '+list.length+')');

  const esc=s=>String(s==null?'':s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
  const card=e=>{
    const img=e.images&&e.images[0]?imgUrl(e.images[0]):'';
    const price='$'+Number(e.price).toLocaleString();
    const src='https://www.craigslist.org/view/d/'+esc(e.slug||'')+'/'+esc(e.token);
    const more=(e.images&&e.images.length>1)?('<div class="count">'+e.images.length+' photos</div>'):'';
    return `<a class="card" href="${src}" target="_blank" rel="noopener">
    <div class="ph">${img?`<img loading="lazy" src="${esc(img)}" alt="${esc(e.title)}">`:'<div class="noph">no photo</div>'}${more}</div>
    <div class="body"><div class="price">${esc(price)}</div><div class="title">${esc(e.title)}</div>
    <div class="loc">${esc(e.where||'')}</div><div class="cta">View on Craigslist →</div></div>
  </a>`;
  };
  const cards=list.map(card).join('\n');
  const html=`<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>US Coins $100–$1000 — Deals</title>
<meta name="description" content="US coins for sale $100 to $1000, found on Craigslist nationwide.">
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
<header><a href="/">← Deals</a><h1>🪙 US Coins · $100–$1000</h1></header>
<div class="wrap">
<p class="sub">US coins for sale, $100–$1000, found on Craigslist nationwide. Tap a listing to open the original ad. ${total} matches.</p>
<div class="grid">${cards||'<div class="empty">No coins in this range right now — check back soon.</div>'}</div>
</div>
<footer>Refreshed from Craigslist · classiccarsforsale-co</footer>
</body></html>`;
  fs.writeFileSync('.github/db-task/fetched/coins.html',html);
  console.error('wrote coins.html ('+html.length+' bytes, '+list.length+' cards)');
})().catch(e=>{console.error('ERR '+e.message);process.exit(1);});
NODE
git config user.name "db-task"
git config user.email "actions@users.noreply.github.com"
git add .github/db-task/fetched/coins.html
git commit -m "db-task: coins.html worldwide sweep result"
git push origin claude/master-file-e6ofy0
echo "coins.html committed"
