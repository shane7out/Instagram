#!/bin/bash
# Run on the Mac (one command):
#   curl -sL --retry 8 --retry-delay 1 --connect-timeout 15 --speed-limit 3000 --speed-time 6 --max-time 150 "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/deploy-dashboard-sdk-auth.sh?$(date +%s)" -o /tmp/deploy-dashboard-sdk-auth.sh && bash /tmp/deploy-dashboard-sdk-auth.sh
# DASHBOARD OWNER LOCK, STEP 1 of 3 (nothing is locked by this step). Takes the LIVE dashboard copy and
#  1. refreshes the owner sign-in box to the newest version (it can now also sign the dashboard's live connection in as you), and
#  2. adds the small bridge (DASHSDK01) + Google's firebase-auth-compat.js (same Google host and version as the Firebase files already loaded),
#     so the dashboard keeps working AFTER the database is locked to you.
# Until the database rules are changed (step 3, deploy-dashboard-lock.sh) the dashboard behaves exactly as today. No PIN, data or rule is touched.
# Checks every script parses first; if anything fails it restores the old page and uploads nothing. Safe to run twice. Keeps index.html.bak-sdkauth.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac"
DASH="/Users/mac/lv-dash-work"
LOG=/tmp/sdkauth.txt
: > "$LOG"

cd "$DASH" || { echo "NO DASH DIR ($DASH)"; exit 1; }

IDX="index.html"; [ -f "$IDX" ] || IDX="$(ls *.html 2>/dev/null | head -1)"
echo "dashboard file: $IDX ($(wc -c < "$IDX") bytes)" >> "$LOG"
echo "before: $(grep -ao 'APP_VERSION=[0-9]*' "$IDX" | head -1)" >> "$LOG"

# ---------------------------------------------------------------------------
# 1) the patch
# ---------------------------------------------------------------------------
curl -sL --retry 8 --retry-delay 1 --connect-timeout 15 --speed-limit 3000 --speed-time 6 --max-time 150 -o /tmp/patch-dashboard-owner-auth.js "$RAWB/patch-dashboard-owner-auth.js"
curl -sL --retry 8 --retry-delay 1 --connect-timeout 15 --speed-limit 3000 --speed-time 6 --max-time 150 -o /tmp/patch-dashboard-sdk-auth.js "$RAWB/patch-dashboard-sdk-auth.js"
curl -sL --retry 8 --retry-delay 1 --connect-timeout 15 --speed-limit 3000 --speed-time 6 --max-time 150 -o /tmp/owner-auth.snippet.html "${RAWB%/mac}/owner-auth/owner-auth.snippet.html"
[ -s /tmp/owner-auth.snippet.html ] && [ -s /tmp/patch-dashboard-sdk-auth.js ] || { echo "Could not download the pieces - nothing changed."; exit 1; }
grep -q "OWNER_AUTH_SDK" /tmp/owner-auth.snippet.html || { echo "The sign-in box download is the old version - nothing changed."; exit 1; }
echo "patchers: $(wc -c < /tmp/patch-dashboard-owner-auth.js) + $(wc -c < /tmp/patch-dashboard-sdk-auth.js) bytes" >> "$LOG"
node /tmp/patch-dashboard-owner-auth.js "$IDX" /tmp/owner-auth.snippet.html >> "$LOG" 2>&1
PATCH_RC=$?
if [ "$PATCH_RC" = "0" ]; then node /tmp/patch-dashboard-sdk-auth.js "$IDX" >> "$LOG" 2>&1; PATCH_RC=$?; fi
echo "patch exit: $PATCH_RC" >> "$LOG"

if [ "$PATCH_RC" != "0" ]; then
  echo "PATCH REPORTED A FAILURE — restoring and stopping, nothing deployed" >> "$LOG"
  [ -f "$IDX.bak-sdkauth" ] && cp "$IDX.bak-sdkauth" "$IDX"
  node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/sdkauth.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT")).catch(function(){})'
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
  [ -f "$IDX.bak-sdkauth" ] && cp "$IDX.bak-sdkauth" "$IDX"
  node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/sdkauth.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT")).catch(function(){})'
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
for MARK in 'OWNER-AUTH-START' 'OWNER_AUTH_SDK' 'DASHSDK01'; do
  echo "live has $MARK : $(grep -c "$MARK" /tmp/live.html)" >> "$LOG"
done

node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/sdkauth.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT — tell Claude done")).catch(e=>console.log("send failed "+e.message))'
echo "==== done ===="; cat "$LOG"
