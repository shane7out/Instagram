#!/bin/bash
# One-shot (run on the Mac), two jobs:
#   A) Deals site: add a "↻ Refresh" tab that force-reloads the page past the cache
#   B) Dashboard: REMOVE the "Storage Containers" pill, bump APP_VERSION, redeploy
# Idempotent — safe to run twice. Posts its log back to Claude at the end.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
DASH="/Users/mac/lv-dash-work"
LOG=/tmp/rfp.txt
: > "$LOG"
say(){ echo "$@" >> "$LOG"; }

# ---------------------------------------------------------------------------
# Part A — Deals site: ↻ Refresh tab
# ---------------------------------------------------------------------------
cd /Users/mac/wholesale-classic-cars || { say "no deals dir"; }
if [ -f index.html ]; then
  node <<'NODE' >> "$LOG" 2>&1
const fs=require('fs');let s=fs.readFileSync('index.html','utf8');const before=s;
const S='display:inline-flex;align-items:center;gap:5px;padding:8px 16px;border-radius:999px;font-size:14px;font-weight:800;text-decoration:none;cursor:pointer';
// force-reload with a cache-busting query param so the browser can't serve a stale copy
const REF='<a class="tablink" href="#" onclick="location.replace(\'/?r=\'+Date.now());return false" style="'+S+';border:1.5px solid #2e7d32;color:#2e7d32">↻ Refresh</a>';
// remove any prior refresh tab, then insert after the Batman tab (fallback: after the Deals chip)
s=s.replace(/<a class="tablink"[^>]*>↻ Refresh<\/a>/g,'');
if(/<a class="tablink"[^>]*>🦇 Batman Cards<\/a>/.test(s)){
  s=s.replace(/(<a class="tablink"[^>]*>🦇 Batman Cards<\/a>)/, '$1\n        '+REF);
}else{
  s=s.replace(/(<button class="chip chip-deals"[^>]*>🔥 Deals<\/button>)/, '$1\n        '+REF);
}
if(s!==before){fs.writeFileSync('index.html.bak-refresh',before);fs.writeFileSync('index.html',s);console.log('refresh tab: inserted');}
else console.log('refresh tab: NO CHANGE (anchors not found?)');
console.log('has refresh tab now: '+(/↻ Refresh/.test(s)?'yes':'no'));
NODE
  say "-- deploying deals site --"
  node _tools/rest-deploy.js >> "$LOG" 2>&1
  say "LIVE deals refresh tab: $(curl -s https://classiccarsforsale-co.web.app/ | grep -c 'Refresh')"
else
  say "deals index.html missing — skipped"
fi

# ---------------------------------------------------------------------------
# Part B — Dashboard: remove the Storage Containers pill
# ---------------------------------------------------------------------------
cd "$DASH" || { say "no dash dir — skipping pill removal"; }
if [ -f "$DASH/index.html" ]; then
  cd "$DASH"
  node <<'NODE' >> "$LOG" 2>&1
const fs=require('fs');let s=fs.readFileSync('index.html','utf8');const before=s;
// remove the whole Storage Containers anchor (multiline) + its lead-in comment if present
s=s.replace(/\s*<!--[^>]*The ATL[^>]*-->\s*/g,'\n  ');
s=s.replace(/<a href="https:\/\/the-atl\.web\.app"[\s\S]*?<\/a>/g,'');
if(/Storage Containers/.test(s)) console.log('WARN: "Storage Containers" text still present after removal');
else console.log('Storage Containers pill: removed');
// bump APP_VERSION (cache-bust)
const vm=s.match(/APP_VERSION\s*=\s*(\d+)/); let newv=null;
if(vm){ newv=parseInt(vm[1],10)+1; s=s.replace(/APP_VERSION\s*=\s*\d+/, 'APP_VERSION='+newv); console.log('APP_VERSION '+vm[1]+' -> '+newv); }
if(s!==before){ fs.writeFileSync('index.html.bak-nostorage',before); fs.writeFileSync('index.html',s); console.log('dashboard patched'); }
else console.log('dashboard: no change');
try{
  if(fs.existsSync('version.json') && newv!=null){
    fs.writeFileSync('version.json.bak-nostorage', fs.readFileSync('version.json'));
    fs.writeFileSync('version.json', JSON.stringify({v:newv}));
    console.log('version.json -> {"v":'+newv+'}');
  }
}catch(e){ console.log('version.json: '+e.message); }
NODE
  say "-- deploying dashboard --"
  DEP="$(ls deploy-overlay.js 2>/dev/null | head -1)"; [ -z "$DEP" ] && DEP="$(ls *overlay*.js deploy*.js 2>/dev/null | head -1)"
  if [ -n "$DEP" ]; then node "$DEP" >> "$LOG" 2>&1; else say "NO DASHBOARD DEPLOYER FOUND"; fi
  say "LIVE dashboard still mentions Storage Containers: $(curl -s https://lvr-data-a60c1.web.app/ | grep -c 'Storage Containers')  (0 = gone)"
fi

# ---------------------------------------------------------------------------
node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/rfp.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT — tell Claude done")).catch(e=>console.log("send failed "+e.message))'
echo "==== done ===="; cat "$LOG"
