#!/bin/bash
# Self-host the coins + Eagle Point land photos: download every Craigslist image referenced
# by the two prebuilt pages into the repo, rewrite the pages to use our own copies
# (raw.githubusercontent), and commit. Also snapshot the live /app.js for reference.
set -e
mkdir -p .github/db-task/fetched/img/coins .github/db-task/fetched/img/land
curl -sL -o .github/db-task/fetched/live-app.js "https://classiccarsforsale-co.web.app/app.js" || true
echo "app.js snapshot: $(wc -c < .github/db-task/fetched/live-app.js 2>/dev/null || echo 0) bytes"
node <<'NODE'
const https=require('https'), fs=require('fs'), zlib=require('zlib'), crypto=require('crypto');
const UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36';
function fetch(url){return new Promise((res,rej)=>{
  const req=https.get(url,{headers:{'user-agent':UA,accept:'image/*,*/*'}},r=>{
    if(r.statusCode>=300&&r.statusCode<400&&r.headers.location){r.resume();return fetch(r.headers.location).then(res,rej);}
    const c=[];r.on('data',x=>c.push(x));r.on('end',()=>res({status:r.statusCode,buf:Buffer.concat(c)}));
  });req.on('error',rej);req.setTimeout(25000,()=>req.destroy(new Error('timeout')));
});}
async function pmap(arr,fn,n){let i=0;const w=Array.from({length:n},async()=>{while(i<arr.length){const k=i++;await fn(arr[k]).catch(()=>null);}});await Promise.all(w);}

const RAW='https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/fetched/img';

async function localize(file, sub){
  if(!fs.existsSync(file)){console.error('missing '+file);return;}
  let html=fs.readFileSync(file,'utf8');
  const urls=[...new Set((html.match(/https:\/\/images\.craigslist\.org\/[^"']+\.jpg/g)||[]))];
  console.error(file+': '+urls.length+' craigslist image url(s)');
  let ok=0, fail=0;
  await pmap(urls, async u=>{
    const name=crypto.createHash('md5').update(u).digest('hex').slice(0,16)+'.jpg';
    const dest='.github/db-task/fetched/img/'+sub+'/'+name;
    if(!fs.existsSync(dest)){
      const r=await fetch(u);
      if(r.status===200 && r.buf.length>1000){ fs.writeFileSync(dest,r.buf); }
      else { fail++; return; }
    }
    html=html.split(u).join(RAW+'/'+sub+'/'+name);
    ok++;
  }, 8);
  fs.writeFileSync(file,html);
  console.error(file+': localized '+ok+', failed '+fail);
}

(async()=>{
  await localize('.github/db-task/fetched/coins.html','coins');
  await localize('.github/db-task/fetched/land-eaglepoint.html','land');
})().catch(e=>{console.error('ERR '+e.message);process.exit(1);});
NODE
echo "coins imgs: $(ls .github/db-task/fetched/img/coins | wc -l) | land imgs: $(ls .github/db-task/fetched/img/land | wc -l)"
echo "repo img size: $(du -sh .github/db-task/fetched/img | cut -f1)"
git config user.name "Claude"
git config user.email "noreply@anthropic.com"
git add .github/db-task/fetched/
git commit -m "fetched: self-host coins + land photos (browsers can't hotlink craigslist)" || echo "no change"
git push
