#!/bin/bash
# Run on the Mac (one command):
#   curl -sL --retry 8 --retry-delay 1 --connect-timeout 15 --speed-limit 3000 --speed-time 6 --max-time 150 "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/deploy-dashboard-faceid.sh?$(date +%s)" -o /tmp/deploy-dashboard-faceid.sh && bash /tmp/deploy-dashboard-faceid.sh
# LVR DASHBOARD PIN PAD: adds a Face ID / Touch ID key (bottom-left, where the empty key is) and turns the dashboard's own Face ID code back on
# (it was switched off on 2026-07-17). The PIN works exactly as before; Face ID is a second way in. The key is dim until you have turned Face ID on:
# enter your PIN once and say yes to "Use face unlock next time?". Takes the LIVE dashboard copy, checks every script parses first; if anything fails
# it restores the old page and uploads nothing. Safe to run twice. No PIN, data or rule is touched. Keeps index.html.bak-faceid.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac"
DASH="/Users/mac/lv-dash-work"
LOG=/tmp/faceid.txt
: > "$LOG"

cd "$DASH" || { echo "NO DASH DIR ($DASH)"; exit 1; }

IDX="index.html"; [ -f "$IDX" ] || IDX="$(ls *.html 2>/dev/null | head -1)"
echo "dashboard file: $IDX ($(wc -c < "$IDX") bytes)" >> "$LOG"
echo "before: $(grep -ao 'APP_VERSION=[0-9]*' "$IDX" | head -1)" >> "$LOG"

# ---------------------------------------------------------------------------
# 1) the patch
# ---------------------------------------------------------------------------
curl -sL --retry 8 --retry-delay 1 --connect-timeout 15 --speed-limit 3000 --speed-time 6 --max-time 150 -o /tmp/patch-dashboard-faceid.js "$RAWB/patch-dashboard-faceid.js"
echo "patcher: $(wc -c < /tmp/patch-dashboard-faceid.js) bytes" >> "$LOG"
node /tmp/patch-dashboard-faceid.js "$IDX" >> "$LOG" 2>&1
PATCH_RC=$?
echo "patch exit: $PATCH_RC" >> "$LOG"

if [ "$PATCH_RC" != "0" ]; then
  echo "PATCH REPORTED A FAILURE — restoring and stopping, nothing deployed" >> "$LOG"
  [ -f "$IDX.bak-faceid" ] && cp "$IDX.bak-faceid" "$IDX"
  node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/faceid.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT")).catch(function(){})'
  echo "==== stopped ===="; cat "$LOG"; exit 1
fi

# ---------------------------------------------------------------------------
# 2) sanity: every inline script must still parse before anything ships
# ---------------------------------------------------------------------------
IDX="$IDX" node <<'NODE' >> "$LOG" 2>&1
const fs=require('fs'), cp=require('child_process');
const s=fs.readFileSync(process.env.IDX,'utf8');
const re=/<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/g;
let m,n=0,bad=0;
while((m=re.exec(s))){
  if(/application\/ld\+json/.test(m[0])||!m[1].trim())continue;
  n++; fs.writeFileSync('/tmp/_blk.js',m[1]);
  const r=cp.spawnSync('node',['--check','/tmp/_blk.js'],{encoding:'utf8'});
  if(r.status){bad++;console.log('SCRIPT BLOCK '+n+' FAILED:\n'+(r.stderr||'').split('\n').slice(0,4).join('\n'));}
}
console.log('inline scripts checked: '+n+', failures: '+bad);
if(bad) process.exit(2);
NODE
if [ "$?" != "0" ]; then
  echo "SYNTAX CHECK FAILED — restoring and stopping, nothing deployed" >> "$LOG"
  [ -f "$IDX.bak-faceid" ] && cp "$IDX.bak-faceid" "$IDX"
  node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/faceid.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT")).catch(function(){})'
  echo "==== stopped ===="; cat "$LOG"; exit 1
fi

# ---------------------------------------------------------------------------
# 3) cache-bust so phones actually pick it up
# ---------------------------------------------------------------------------
IDX="$IDX" node <<'NODE' >> "$LOG" 2>&1
const fs=require('fs');
const F=process.env.IDX;
let s=fs.readFileSync(F,'utf8');
const vm=s.match(/APP_VERSION\s*=\s*(\d+)/);
if(vm){
  const nv=parseInt(vm[1],10)+1;
  s=s.replace(/APP_VERSION\s*=\s*\d+/,'APP_VERSION='+nv);
  fs.writeFileSync(F,s);
  console.log('APP_VERSION '+vm[1]+' -> '+nv);
  try{
    if(fs.existsSync('version.json')){
      fs.writeFileSync('version.json',JSON.stringify({v:nv}));
      console.log('version.json -> {"v":'+nv+'}');
    }
  }catch(e){ console.log('version.json: '+e.message); }
} else console.log('APP_VERSION not found — not bumped');
NODE

# ---------------------------------------------------------------------------
# 4) deploy + verify
# ---------------------------------------------------------------------------
DEP="$(ls deploy-overlay.js 2>/dev/null | head -1)"
[ -z "$DEP" ] && DEP="$(ls *overlay*.js deploy*.js 2>/dev/null | head -1)"
if [ -n "$DEP" ]; then
  echo "-- deploying ($DEP) --" >> "$LOG"
  node "$DEP" >> "$LOG" 2>&1
else
  echo "NO DASHBOARD DEPLOYER FOUND in $DASH" >> "$LOG"
fi

sleep 3
curl -s https://lvr-data-a60c1.web.app/ -o /tmp/live.html
echo "-- live check --" >> "$LOG"
echo "live version : $(grep -ao 'APP_VERSION=[0-9]*' /tmp/live.html | head -1)" >> "$LOG"
for MARK in 'FACEID01' 'pin-face-btn'; do
  echo "live has $MARK : $(grep -c "$MARK" /tmp/live.html)" >> "$LOG"
done

node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/faceid.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT — tell Claude done")).catch(e=>console.log("send failed "+e.message))'
echo "==== done ===="; cat "$LOG"
