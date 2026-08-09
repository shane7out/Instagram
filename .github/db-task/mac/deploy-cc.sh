#!/bin/bash
# One-shot (run on the Mac): deploy the 💳 CC credit-card manager + add its pill to the dashboard.
#   Part A: deploy cc.html -> https://lvr-cc.web.app  (self-contained, client-side encrypted)
#   Part B: add a "CC" pill to the PIN-gated LVR dashboard (right after the Deals pill), redeploy
# Nothing sensitive is committed anywhere — the page holds only UI; real card data is entered in the
# browser and stored ENCRYPTED in Firebase. One line to run.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
PROJECT="lvr-data-a60c1"
CC_SITE="lvr-cc"
CC_URL="https://${CC_SITE}.web.app"
REF="claude/master-file-e6ofy0"     # pull the latest cc.html from this branch
DASH="/Users/mac/lv-dash-work"
LOG=/tmp/cc.txt
: > "$LOG"
say(){ echo "$@" >> "$LOG"; }

# ---------------------------------------------------------------------------
# Part A — deploy the CC site (its own Firebase Hosting site, REST, serial upload)
# ---------------------------------------------------------------------------
WORK=/tmp/cc-site; mkdir -p "$WORK"; cd "$WORK" || { say "no workdir"; }
curl -sL -o index.html "https://raw.githubusercontent.com/shane7out/Instagram/${REF}/.github/db-task/fetched/cc.html"
say "cc index.html: $(wc -c < index.html) bytes"

node <<'NODE' >> "$LOG" 2>&1
const {execSync}=require('child_process'), fs=require('fs'), zlib=require('zlib'), crypto=require('crypto');
const PROJECT='lvr-data-a60c1', SITE='lvr-cc', API='https://firebasehosting.googleapis.com/v1beta1';
const token=execSync('gcloud auth print-access-token').toString().trim();
async function api(method,url,body,raw){
  const headers={Authorization:'Bearer '+token,'x-goog-user-project':PROJECT};
  headers['Content-Type']= raw?'application/octet-stream':'application/json';
  const r=await fetch(url,{method,headers,body: raw?body:(body?JSON.stringify(body):undefined)});
  const t=await r.text(); let j; try{j=JSON.parse(t)}catch(e){j={raw:t}} return {status:r.status,json:j};
}
(async()=>{
  let r=await api('POST',API+'/projects/'+PROJECT+'/sites?siteId='+SITE);
  if(r.status===200)console.log('site created: '+SITE);
  else if(r.status===409)console.log('site exists: '+SITE);
  else {console.log('SITE CREATE FAILED '+r.status+': '+JSON.stringify(r.json).slice(0,300));process.exit(1);}
  r=await api('POST',API+'/sites/'+SITE+'/versions',{});
  if(!r.json.name){console.log('VERSION FAILED: '+JSON.stringify(r.json).slice(0,300));process.exit(1);}
  const version=r.json.name; console.log('version: '+version);
  const gz=zlib.gzipSync(fs.readFileSync('index.html'));
  const hash=crypto.createHash('sha256').update(gz).digest('hex');
  r=await api('POST',API+'/'+version+':populateFiles',{files:{'/index.html':hash}});
  if(r.status!==200){console.log('POPULATE FAILED: '+JSON.stringify(r.json).slice(0,300));process.exit(1);}
  if((r.json.uploadRequiredHashes||[]).indexOf(hash)!==-1){
    const up=await api('POST',r.json.uploadUrl+'/'+hash,gz,true);
    if(up.status!==200){console.log('UPLOAD FAILED '+up.status);process.exit(1);}
    console.log('  uploaded index.html');
  } else console.log('  content already on server');
  r=await api('PATCH',API+'/'+version+'?update_mask=status',{status:'FINALIZED'});
  if(r.status!==200){console.log('FINALIZE FAILED: '+JSON.stringify(r.json).slice(0,300));process.exit(1);}
  r=await api('POST',API+'/sites/'+SITE+'/releases?versionName='+version);
  if(r.status!==200){console.log('RELEASE FAILED: '+JSON.stringify(r.json).slice(0,300));process.exit(1);}
  console.log('RELEASED CC ✅ https://'+SITE+'.web.app');
})();
NODE
say "LIVE CC: $(curl -sL -o /dev/null -w '%{http_code}' "$CC_URL")"

# ---------------------------------------------------------------------------
# Part B — add the CC pill to the dashboard and redeploy
# ---------------------------------------------------------------------------
cd "$DASH" || { say "NO DASH DIR ($DASH) — skipping pill; CC site is live at $CC_URL"; }
if [ -d "$DASH" ]; then
  # find the dashboard html (index.html at root, else first *.html)
  IDX="index.html"; [ -f "$IDX" ] || IDX="$(ls *.html 2>/dev/null | head -1)"
  say "dashboard file: $IDX"
  IDX="$IDX" CC_URL="$CC_URL" node <<'NODE' >> "$LOG" 2>&1
const fs=require('fs');
const IDX=process.env.IDX||'index.html';
let f=IDX; if(!fs.existsSync(f)){ const h=require('child_process').execSync('ls *.html').toString().split('\n').filter(Boolean); f=h[0]; }
let s=fs.readFileSync(f,'utf8'); const before=s;
const URL=process.env.CC_URL;
if(s.indexOf(URL)!==-1){ console.log('CC pill already present — skip insert'); }
else{
  const pill='\n  <!-- CC: private credit-card manager (client-side encrypted) -->\n'
   +'  <a href="'+URL+'" target="_blank" rel="noopener"\n'
   +'     style="display:inline-block;text-decoration:none;\n'
   +'            color:rgba(255,255,255,0.55);font-size:14px;letter-spacing:0.01em;\n'
   +'            border:1px solid rgba(255,255,255,0.25);border-radius:10px;\n'
   +'            padding:8px 20px;">CC</a>';
  // insert right after the Deals pill's closing </a>
  const m=s.match(/(<a href="https:\/\/classiccarsforsale-co\.web\.app"[\s\S]*?>Deals<\/a>)/);
  if(m){ s=s.replace(m[1], m[1]+pill); console.log('CC pill inserted after Deals'); }
  else { console.log('DEALS ANCHOR NOT FOUND — pill not inserted (report to Claude)'); }
}
// bump APP_VERSION (cache-bust) if present
const vm=s.match(/APP_VERSION\s*=\s*(\d+)/);
let newv=null;
if(vm){ newv=parseInt(vm[1],10)+1; s=s.replace(/APP_VERSION\s*=\s*\d+/, 'APP_VERSION='+newv); console.log('APP_VERSION '+vm[1]+' -> '+newv); }
if(s!==before){ fs.writeFileSync(f+'.bak-cc',before); fs.writeFileSync(f,s); console.log('dashboard patched: '+f); }
else console.log('dashboard: no change');
// keep version.json in lockstep if it exists
try{
  if(fs.existsSync('version.json') && newv!=null){
    let vj=fs.readFileSync('version.json','utf8');
    vj=vj.replace(/(\d+)/, String(newv));
    fs.writeFileSync('version.json.bak-cc', fs.readFileSync('version.json'));
    fs.writeFileSync('version.json', vj);
    console.log('version.json -> '+vj.trim());
  }
}catch(e){ console.log('version.json: '+e.message); }
NODE

  # locate + run the dashboard deployer
  DEP="$(ls deploy-overlay.js 2>/dev/null | head -1)"
  [ -z "$DEP" ] && DEP="$(ls *overlay*.js deploy*.js 2>/dev/null | head -1)"
  if [ -n "$DEP" ]; then
    say "-- deploying dashboard ($DEP) --"
    node "$DEP" >> "$LOG" 2>&1
  else
    say "NO DASHBOARD DEPLOYER FOUND in $DASH — CC site is live; pill patched locally, needs deploy"
  fi
  say "LIVE dashboard has CC pill: $(curl -s https://lvr-data-a60c1.web.app/ | grep -oE 'lvr-cc\.web\.app' | head -1)"
fi

# ---------------------------------------------------------------------------
# report back to Claude
# ---------------------------------------------------------------------------
node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/cc.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT — tell Claude done")).catch(e=>console.log("send failed "+e.message))'
echo "==== done ===="; cat "$LOG"
