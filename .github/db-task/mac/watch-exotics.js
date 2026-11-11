// EXOTICS harvester (owner, 2026-11-11): Lamborghini and Ferrari listings on Craigslist within 100 miles of Las Vegas.
// By default only "by owner" sellers (searchPath cto); set EXOTIC_PATH=cta to include dealers too.
// Same pattern as watch-batman.js: type 'Lamborghini' / 'Ferrari' entries in manual.json, photos to carimg/, prints "ADDED n".
// Distance is computed here from the latitude/longitude Craigslist attaches to every listing (haversine from downtown Las Vegas), so it does not
// depend on any Craigslist distance setting. Seller ads only: want-to-buy ads, tractors, toys and listings without photos are skipped.
// Also removes entries whose ad has been deleted/expired. `node watch-exotics.js --selftest` runs the built-in checks.
const https=require('https'), fs=require('fs'), path=require('path'), zlib=require('zlib');
const ROOT=path.join(__dirname,'..');
const UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)';
const CENTER={lat:36.1716,lon:-115.1391}, RADIUS=100; // miles
const SEARCH_PATH=process.env.EXOTIC_PATH==='cta'?'cta':'cto';
const MAKES=[{q:'lamborghini',make:'Lamborghini',re:/\blamborghini\b/i},{q:'ferrari',make:'Ferrari',re:/\bferrari\b/i}];
const MINP=3000;
const WTB=/\b(wtb|wanted|looking for|looking to buy|i buy|we buy|cash (?:paid|for)|buying|will pay)\b/i;
const NOTCAR=/\b(tractor|golf cart|scooter|toy|model car|diecast|die-cast|poster|bicycle|e-?bike|lawn|rc car|steering wheel only|wheels? only|rims? only|parts? only|for parts)\b/i;
const DEAD=/this posting has been (deleted|flagged)|this posting has expired|page not found/i;

function miles(lat1,lon1,lat2,lon2){const R=3958.8,r=x=>x*Math.PI/180;const dLat=r(lat2-lat1),dLon=r(lon2-lon1);
  const a=Math.sin(dLat/2)**2+Math.cos(r(lat1))*Math.cos(r(lat2))*Math.sin(dLon/2)**2;return 2*R*Math.asin(Math.sqrt(a));}
function geoOf(g){if(typeof g!=='string')return null;const p=g.split('~');if(p.length<3)return null;const la=parseFloat(p[1]),lo=parseFloat(p[2]);return isFinite(la)&&isFinite(lo)?{lat:la,lon:lo}:null;}
function parseItem(it){const o={price:it[3],geo:it[4],images:[]};for(let i=5;i<it.length;i++){const v=it[i];if(typeof v==='string')o.title=v;else if(Array.isArray(v)){if(v[0]===4)o.images=v.slice(1);else if(v[0]===6)o.slug=v[1];else if(v[0]===13)o.token=v[1];}}return o;}
// decides whether a parsed listing belongs on the page; returns {ok, why, dist}
function judge(it,mk,text){
  if(!it.token||!it.title)return{ok:false,why:'incomplete'};
  if(!(typeof it.price==='number'&&it.price>=MINP))return{ok:false,why:'price'};
  const g=geoOf(it.geo);if(!g)return{ok:false,why:'no location'};
  const dist=miles(CENTER.lat,CENTER.lon,g.lat,g.lon);if(dist>RADIUS)return{ok:false,why:'too far',dist};
  const t=it.title+' '+(text||'');
  if(!mk.re.test(it.title))return{ok:false,why:'not '+mk.make,dist};
  if(WTB.test(t))return{ok:false,why:'wanted ad',dist};
  if(NOTCAR.test(t))return{ok:false,why:'not a car',dist};
  return{ok:true,dist};
}
if(process.argv.includes('--selftest')){
  const mk=MAKES[0];let bad=0;const T=(n,c)=>{if(!c){bad++;console.log('FAIL '+n);}else console.log('ok   '+n);};
  const mkItem=(price,geo,title)=>[1,2,3,price,geo,'x',[13,'tok1'],[4,'3:aaa_bbb'],[6,'slug'],title];
  const a=parseItem(mkItem(180000,'1:1~36.1433~-115.2004','2018 Lamborghini Huracan LP580'));
  T('parse',a.token==='tok1'&&a.title.includes('Huracan')&&a.images.length===1);
  T('near accepted',judge(a,mk,'').ok);
  T('far rejected (Phoenix)',!judge(parseItem(mkItem(180000,'1:2~33.45~-112.07','2018 Lamborghini Huracan')),mk,'').ok);
  T('Kingman about 100 mi',(()=>{const d=miles(CENTER.lat,CENTER.lon,35.19,-114.05);return d>85&&d<110;})());
  T('wanted ad rejected',!judge(parseItem(mkItem(180000,'1:1~36.1~-115.2','WTB Lamborghini Gallardo')),mk,'').ok);
  T('tractor rejected',!judge(parseItem(mkItem(18000,'1:1~36.1~-115.2','Lamborghini tractor 1990')),mk,'').ok);
  T('low price rejected',!judge(parseItem(mkItem(1,'1:1~36.1~-115.2','Lamborghini')),mk,'').ok);
  T('no geo rejected',!judge(parseItem(mkItem(90000,'','2012 Lamborghini Gallardo')),mk,'').ok);
  T('Ferrari title needed',!judge(a,MAKES[1],'').ok);
  process.exit(bad?1:0);
}

function get(url,bin){return new Promise((res,rej)=>{
  const req=https.get(url,{headers:{'user-agent':UA,accept:bin?'*/*':'application/json'}},r=>{
    if(r.statusCode>=300&&r.statusCode<400&&r.headers.location){r.resume();return get(r.headers.location,bin).then(res,rej);}
    const c=[];r.on('data',x=>c.push(x));r.on('end',()=>{let b=Buffer.concat(c);const enc=(r.headers['content-encoding']||'').toLowerCase();try{if(enc==='gzip'||(b[0]===0x1f&&b[1]===0x8b))b=zlib.gunzipSync(b);else if(enc==='deflate'||b[0]===0x78)b=zlib.inflateSync(b);}catch(e){}res({status:r.statusCode,buf:b});});
  });
  req.on('error',rej);req.setTimeout(30000,()=>req.destroy(new Error('timeout')));
});}
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
async function getR(url,bin,t){t=t||3;for(let a=0;a<t;a++){try{const r=await get(url,bin);if(r.status===200)return r;if(a===t-1)return r;}catch(e){if(a===t-1)throw e;}await sleep(1500*(a+1));}}
function imgUrl(raw){return 'https://images.craigslist.org/'+raw.replace(/^\d+:/,'')+'_600x450.jpg';}
async function detail(src){const r=await getR(src,false).catch(()=>null);if(!r||r.status!==200)return{imgs:[],text:'',postedTs:'',dead:!!(r&&(r.status===404||r.status===410))};const h=r.buf.toString();
  const body=((h.match(/<section id="postingbody">([\s\S]*?)<\/section>/)||[])[1]||'').replace(/<[^>]+>/g,' ');
  const dt=(h.match(/<time[^>]+datetime="([^"]+)"/)||[])[1];
  return {imgs:[...new Set((h.match(/https:\/\/images\.craigslist\.org\/[0-9a-zA-Z_]+_600x450\.jpg/g)||[]))], text:body, postedTs:dt?new Date(Date.parse(dt)).toISOString():'', dead:DEAD.test(h)};}

(async()=>{
  const MANUAL=path.join(ROOT,'_tools','manual.json');
  const manual=JSON.parse(fs.readFileSync(MANUAL,'utf8'));
  const seen=new Set(manual.filter(e=>e.src).map(e=>e.src.split('/').pop()));
  try{JSON.parse(fs.readFileSync(path.join(ROOT,'_tools','deleted-tokens.json'),'utf8')).forEach(t=>seen.add(t));}catch(e){}
  const ar=await getR('https://reference.craigslist.org/Areas',false);
  const areas=JSON.parse(ar.buf.toString()).filter(a=>['lasvegas','mohave'].includes(a.Hostname)); // the two Craigslist sites that reach 100 miles around Las Vegas
  console.error('areas: '+areas.map(a=>a.Hostname).join(','));
  // 1) drop ads that have been taken down
  let removed=0;
  for(const e of manual.filter(e=>(e.type==='Lamborghini'||e.type==='Ferrari')&&e.src)){
    const d=await detail(e.src); await sleep(1200);
    if(d.dead){manual.splice(manual.indexOf(e),1);removed++;}
  }
  // 2) find new ones
  const byTok={};
  for(const mk of MAKES)for(const a of areas){
    const url='https://sapi.craigslist.org/web/v8/postings/search/full?batch='+a.AreaID+'-0-360-0-0&cc='+a.Country+'&lang=en&searchPath='+SEARCH_PATH+'&query='+encodeURIComponent(mk.q);
    const r=await getR(url,false,2).catch(()=>null); await sleep(1500); if(!r)continue;
    let d;try{d=JSON.parse(r.buf.toString()).data;}catch(e){continue;}
    if(!d||!Array.isArray(d.items))continue;
    d.items.forEach(raw=>{const it=parseItem(raw);if(!it.token)return;const j=judge(it,mk,'');if(!j.ok)return;
      if(!byTok[it.token]){it.dist=j.dist;it.mk=mk;it.where=a.Description;byTok[it.token]=it;}});
  }
  const cands=Object.values(byTok).filter(it=>!seen.has(it.token));
  console.error('candidates within '+RADIUS+' miles: '+Object.keys(byTok).length+', new: '+cands.length);
  let added=0, skipped=0;
  for(const it of cands){
    const src='https://www.craigslist.org/view/d/'+it.slug+'/'+it.token;
    const det=await detail(src); await sleep(1200);
    const j=judge(it,it.mk,det.text); if(!j.ok){skipped++;continue;}
    let urls=det.imgs.length?det.imgs:it.images.map(imgUrl); urls=urls.slice(0,24);
    const slug=(it.mk.make.toLowerCase()+'-'+it.token.slice(0,8));
    const imgs=[];
    for(let i=0;i<urls.length;i++){try{const im=await getR(urls[i],true);if(im&&im.status===200&&im.buf.length>2000){const fn='carimg/'+slug+'-'+(i+1)+'.jpg';fs.writeFileSync(path.join(ROOT,fn),im.buf);imgs.push('/'+fn);}}catch(e){}}
    if(!imgs.length){skipped++;continue;}
    const yr=(it.title.match(/\b(19[5-9]\d|20[0-3]\d)\b/)||[])[1]||'';
    manual.push({oid:'clex'+it.token.slice(0,8),year:yr,make:it.mk.make,model:it.title.replace(/\s+/g,' ').slice(0,70).trim(),type:it.mk.make,
      price:it.price,miles:null,color:'',fuel:'',sub:'Exotics',location:(it.where||'Las Vegas')+' (~'+Math.round(it.dist)+' mi from Las Vegas)',distMiles:Math.round(it.dist),
      desc:(it.title)+' - asking $'+Number(it.price).toLocaleString()+', about '+Math.round(it.dist)+' miles from Las Vegas. Craigslist ad ('+(SEARCH_PATH==='cto'?'by owner':'owner or dealer')+'). See the original ad for details and to contact the seller.',
      imgs,src,added:new Date().toISOString().slice(0,10),addedTs:new Date().toISOString(),postedTs:det.postedTs||''});
    added++; console.error('IMPORTED '+it.mk.make+' $'+it.price+' ('+Math.round(it.dist)+' mi) '+it.title.slice(0,50));
  }
  if(added||removed){fs.writeFileSync(MANUAL,JSON.stringify(manual,null,1));}
  console.log('ADDED '+added+' (removed '+removed+' taken-down ads, skipped '+skipped+')');
})().catch(e=>{console.error('ERR '+e.message);console.log('ADDED 0');});
