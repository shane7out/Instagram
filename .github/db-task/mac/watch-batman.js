// BATMAN-1966 CARDS harvester (owner, 2026-08-03): WORLDWIDE Craigslist sweep for
// 1966 Batman trading cards (Topps: Black Bat / Red Bat / Blue Bat / Bat Laffs, etc).
// Unlike the other watchers this is not Vegas-only and has no deal math — every
// listing whose ad reads as Batman cards is imported. type:'Batman' entries in
// manual.json, photos to carimg/. Prints "ADDED n".
const https=require('https'), fs=require('fs'), path=require('path');
const ROOT=path.join(__dirname,'..');
const UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)';
const CARD=/\b(card|cards|topps)\b/i;
const BATMAN=/\bbatman\b/i;

function fetch(url,bin){return new Promise((res,rej)=>{
  const req=https.get(url,{headers:{'user-agent':UA,accept:bin?'*/*':'application/json'}},r=>{
    if(r.statusCode>=300&&r.statusCode<400&&r.headers.location){r.resume();return fetch(r.headers.location,bin).then(res,rej);}
    const c=[];r.on('data',x=>c.push(x));r.on('end',()=>res({status:r.statusCode,buf:Buffer.concat(c)}));
  });
  req.on('error',rej);req.setTimeout(30000,()=>req.destroy(new Error('timeout')));
});}
async function fetchR(url,bin,t){t=t||4;for(let a=0;a<t;a++){try{const r=await fetch(url,bin);if(r.status===200)return r;if(a===t-1)return r;}catch(e){if(a===t-1)throw e;}await new Promise(r=>setTimeout(r,1500*(a+1)));}}
function imgUrl(raw){return 'https://images.craigslist.org/'+raw.replace(/^\d+:/,'')+'_600x450.jpg';}
function parseItem(it){const o={price:it[3],geo:it[4],images:[]};for(let i=5;i<it.length;i++){const v=it[i];if(typeof v==='string')o.title=v;else if(Array.isArray(v)){if(v[0]===4)o.images=v.slice(1);else if(v[0]===6)o.slug=v[1];else if(v[0]===13)o.token=v[1];}}return o;}
async function detail(src){const r=await fetchR(src,false).catch(()=>null);if(!r||r.status!==200)return{imgs:[],text:'',postedTs:''};const h=r.buf.toString();
  const body=((h.match(/<section id="postingbody">([\s\S]*?)<\/section>/)||[])[1]||'').replace(/<[^>]+>/g,' ');
  const dt=(h.match(/<time[^>]+datetime="([^"]+)"/)||[])[1];
  return {imgs:[...new Set((h.match(/https:\/\/images\.craigslist\.org\/[0-9a-zA-Z_]+_600x450\.jpg/g)||[]))], text:body, postedTs:dt?new Date(Date.parse(dt)).toISOString():''};}
async function pmap(arr,fn,n){const out=[];let i=0;const w=Array.from({length:n},async()=>{while(i<arr.length){const k=i++;out[k]=await fn(arr[k]).catch(()=>null);}});await Promise.all(w);return out;}

(async()=>{
  const MANUAL=path.join(ROOT,'_tools','manual.json');
  const manual=JSON.parse(fs.readFileSync(MANUAL,'utf8'));
  const seen=new Set(manual.filter(e=>e.src).map(e=>e.src.split('/').pop()));
  try{JSON.parse(fs.readFileSync(path.join(ROOT,'_tools','deleted-tokens.json'),'utf8')).forEach(t=>seen.add(t));}catch(e){} // tombstones

  const ar=await fetchR('https://reference.craigslist.org/Areas',false);
  const areas=JSON.parse(ar.buf.toString());
  console.error('areas: '+areas.length);

  const byTok={};
  await pmap(areas,async a=>{
    const url='https://sapi.craigslist.org/web/v8/postings/search/full?batch='+a.AreaID+'-0-360-0-0&cc='+a.Country+'&lang=en&searchPath=sss&query='+encodeURIComponent('batman 1966');
    const r=await fetchR(url,false,2).catch(()=>null); if(!r)return;
    let d;try{d=JSON.parse(r.buf.toString()).data;}catch(e){return;}
    if(!d||!Array.isArray(d.items))return;
    d.items.forEach(raw=>{const it=parseItem(raw);
      if(!it.token||!it.title)return;
      if(!byTok[it.token]){it.where=(a.Description||a.Hostname)+(a.Country&&a.Country!=='US'?(', '+a.Country):'');byTok[it.token]=it;}
    });
  },8);
  console.error('unique postings: '+Object.keys(byTok).length);

  const cands=Object.values(byTok).filter(it=>!seen.has(it.token));
  let added=0, scanned=0, skipped=0;
  for(const it of cands){
    scanned++;
    const src='https://www.craigslist.org/view/d/'+it.slug+'/'+it.token;
    const det=await detail(src);
    const atext=it.title+' '+det.text;
    if(!CARD.test(atext)||!BATMAN.test(atext)){skipped++;continue;}  // must read as Batman cards
    let urls=det.imgs.length?det.imgs:it.images.map(imgUrl); urls=urls.slice(0,24);
    const slug=('batman-'+it.token.slice(0,8)).toLowerCase();
    const imgs=[];
    for(let i=0;i<urls.length;i++){try{const im=await fetchR(urls[i],true);if(im&&im.status===200&&im.buf.length>2000){const fn='carimg/'+slug+'-'+(i+1)+'.jpg';fs.writeFileSync(path.join(ROOT,fn),im.buf);imgs.push('/'+fn);}}catch(e){}}
    if(!imgs.length){skipped++;continue;}
    const price=(typeof it.price==='number'&&it.price>0)?it.price:0;
    manual.push({oid:'clbm'+it.token.slice(0,8),year:'1966',make:'Batman',model:it.title.replace(/\s+/g,' ').slice(0,58).trim(),type:'Batman',
      price:price,miles:null,color:'',fuel:'',sub:'Batman Cards',
      location:it.where||'Craigslist',
      desc:(it.title||'Batman cards')+' — '+(price?('asking $'+Number(price).toLocaleString()):'no price listed')+'. 1966 Batman trading cards listing on Craigslist ('+(it.where||'')+'). See the original ad for details and to contact the seller.',
      imgs,src,added:new Date().toISOString().slice(0,10),addedTs:new Date().toISOString(),postedTs:det.postedTs||''});
    added++;
    console.error('IMPORTED BATMAN $'+price+' ['+(it.where||'')+'] '+it.title.slice(0,48));
  }
  if(added){fs.writeFileSync(MANUAL,JSON.stringify(manual,null,1));}
  console.log('ADDED '+added+' (scanned '+scanned+', not-cards/no-photos: '+skipped+')');
})().catch(e=>{console.error('ERR '+e.message);console.log('ADDED 0');});
