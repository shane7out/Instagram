#!/bin/bash
# One-shot (run on the Mac): apply every pending dashboard patch and deploy.
#   patch-crm.js            - 23 CRM fixes (import data loss, dead buttons, counts)
#   patch-staging-tab.js    - brings back the Outreach | Staging tab row
#   patch-staging-firebase.js - lets the staging queue be filled from Firebase
#   patch-badig-suggest.js  - suggested Instagram handles on Bad IG cards
# Each patcher is idempotent and marker-fenced, so re-running changes nothing.
# If any patcher or the syntax check fails, the backup is restored and nothing
# is deployed.
# The staging pipeline itself already exists and works - 487 restaurants are
# queued in it. Only the tab that reaches it had been removed.
# Idempotent - every edit is marker-fenced, so re-running changes nothing.
# One pristine copy is taken before any patcher runs, and that is what a failure
# restores - each patcher writes its own backup of whatever it saw, so the last
# one is not the original. Posts its log back to Claude at the end.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac"
DASH="/Users/mac/lv-dash-work"
LOG=/tmp/dashpatch.txt
: > "$LOG"

cd "$DASH" || { echo "NO DASH DIR ($DASH)"; exit 1; }

IDX="index.html"; [ -f "$IDX" ] || IDX="$(ls *.html 2>/dev/null | head -1)"
echo "dashboard file: $IDX ($(wc -c < "$IDX") bytes)" >> "$LOG"
echo "before: $(grep -ao 'APP_VERSION=[0-9]*' "$IDX" | head -1)" >> "$LOG"

# ---------------------------------------------------------------------------
# 1) the two staging patches: the tab, and the Firebase-backed queue
# ---------------------------------------------------------------------------
PRISTINE="$IDX.pristine-$(date -u +%Y%m%dT%H%M%SZ)"
cp "$IDX" "$PRISTINE"
echo "pristine copy: $PRISTINE ($(wc -c < "$PRISTINE") bytes)" >> "$LOG"

for P in patch-crm.js patch-staging-tab.js patch-staging-firebase.js patch-badig-suggest.js; do
  curl -sL -o "/tmp/$P" "$RAWB/$P"
  echo "-- $P ($(wc -c < "/tmp/$P") bytes) --" >> "$LOG"
  node "/tmp/$P" "$IDX" >> "$LOG" 2>&1
  RC=$?
  echo "   exit: $RC" >> "$LOG"
  [ "$RC" != "0" ] && PATCH_FAIL=1
done
if [ -n "$PATCH_FAIL" ]; then
  echo "PATCH REPORTED A FAILURE — restoring and stopping, nothing deployed" >> "$LOG"
  cp "$PRISTINE" "$IDX"   # full rollback to the pre-patch file
  node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/dashpatch.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT")).catch(function(){})'
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
  cp "$PRISTINE" "$IDX"   # full rollback to the pre-patch file
  node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/dashpatch.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT")).catch(function(){})'
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
for MARK in 'id="mtab-staging"' 'mtab-stg-cnt' 'rsLoadFirebaseStaging' 'igSuggestAccept' 's-badig-sug' 'Avg Spend' 'Type MERGE'; do
  echo "live has $MARK : $(grep -c "$MARK" /tmp/live.html)" >> "$LOG"
done
echo "tab row still empty: $(grep -c '<div id=\"main-tab-row\" style=\"display:none;\"></div>' /tmp/live.html)  (0 = restored)" >> "$LOG"

node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/dashpatch.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT — tell Claude done")).catch(e=>console.log("send failed "+e.message))'
echo "==== done ===="; cat "$LOG"
