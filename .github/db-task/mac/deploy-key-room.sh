#!/bin/bash
# One-shot (run on the Mac): single-sign-on for every Key Tech / LVR admin
# tool, plus a new hub page to reach them all from one place.
#
# What this does:
#   1. The moment you log into the main dashboard with your OWNER PIN
#      (137900 by default), a timestamp gets written to this browser's
#      localStorage (lv_owner_session). Every page below checks for that
#      same stamp on load and - if it's there and less than 24h old - skips
#      its own PIN screen entirely and opens straight up. Enter your master
#      PIN once, everything else just opens. No new PINs to remember.
#   2. A new "🔑 Key Tech" pill appears in the main dashboard header, next
#      to Teams, opening the new key-room.html hub - one page listing
#      every tool (Leads, Prospect CRM, Advertisers, Coupon Programs, the
#      live site, Page Views) as a simple tappable list.
#   3. Re-deploys key-leads.html, kt-crm.html, key-advertisers.html, and
#      lvr-coupons-admin.html with that same single-sign-on check added -
#      this SUPERSEDES running deploy-key-leads.sh / deploy-kt-crm.sh /
#      deploy-keytech-advertisers.sh / deploy-lvr-coupons.sh individually
#      for those files (running them again later is harmless, just
#      redundant - they pull the same source).
#
# Same safety discipline as every other dashboard patch here: pristine
# backup before touching the dashboard, the patcher's exit code checked,
# every inline script syntax-checked before deploy, full rollback on any
# failure, live verification after.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac"
DASH="/Users/mac/lv-dash-work"
LOG=/tmp/keyroomdeploy.txt
: > "$LOG"

cd "$DASH" || { echo "NO DASH DIR ($DASH)"; exit 1; }

IDX="index.html"; [ -f "$IDX" ] || IDX="$(ls *.html 2>/dev/null | grep -v key-advertisers | grep -v key-leads | grep -v kt-crm | grep -v key-room | grep -v lvr-coupons | grep -v lvr-wallet | grep -v lvr-points | grep -v lvr-restaurant | head -1)"
echo "dashboard file: $IDX ($(wc -c < "$IDX") bytes)" >> "$LOG"
echo "before: $(grep -ao 'APP_VERSION=[0-9]*' "$IDX" | head -1)" >> "$LOG"

# ---------------------------------------------------------------------------
# 1) standalone tools - download fresh, syntax-check each, skip (don't ship)
#    any that fail rather than aborting the whole run
# ---------------------------------------------------------------------------
FILES="key-room.html key-leads.html kt-crm.html key-advertisers.html lvr-coupons-admin.html lvr-wallet.html lvr-points-admin.html lvr-restaurant-portal.html lvr-rewards.html"
FAILED=""
for F in $FILES; do
  curl -sL -o "$F" "$RAWB/$F"
  echo "$F: $(wc -c < "$F") bytes" >> "$LOG"
  node <<NODE >> "$LOG" 2>&1
const fs = require('fs'), cp = require('child_process');
const s = fs.readFileSync('$F', 'utf8');
const scripts = [...s.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/g)].map(m => m[1]);
if (!scripts.length) { console.log('$F: NO SCRIPT BLOCK FOUND'); process.exit(2); }
fs.writeFileSync('/tmp/_keyroomfile_block.js', scripts.join('\n;\n'));
const r = cp.spawnSync('node', ['--check', '/tmp/_keyroomfile_block.js'], { encoding: 'utf8' });
if (r.status) { console.log('$F: SYNTAX CHECK FAILED:\n' + (r.stderr || '')); process.exit(2); }
console.log('$F: syntax check OK');
NODE
  if [ "$?" != "0" ]; then
    echo "$F FAILED its syntax check — removing it, not deploying it" >> "$LOG"
    rm -f "$F"
    FAILED="$FAILED $F"
  fi
done

# ---------------------------------------------------------------------------
# 2) patch the live dashboard (pristine backup first, full rollback on any failure)
# ---------------------------------------------------------------------------
PRISTINE="$IDX.pristine-$(date -u +%Y%m%dT%H%M%SZ)"
cp "$IDX" "$PRISTINE"
echo "pristine copy: $PRISTINE ($(wc -c < "$PRISTINE") bytes)" >> "$LOG"

curl -sL -o /tmp/patch-key-room-pill.js "$RAWB/patch-key-room-pill.js"
node /tmp/patch-key-room-pill.js "$IDX" >> "$LOG" 2>&1
RC=$?
echo "   patch-key-room-pill.js exit: $RC" >> "$LOG"
if [ "$RC" != "0" ]; then
  echo "PATCH REPORTED A FAILURE — restoring and stopping, nothing deployed" >> "$LOG"
  cp "$PRISTINE" "$IDX"
  node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/keyroomdeploy.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT")).catch(function(){})'
  echo "==== stopped ===="; cat "$LOG"; exit 1
fi

# ---------------------------------------------------------------------------
# 3) sanity: every inline script in the patched dashboard must still parse
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
  cp "$PRISTINE" "$IDX"
  node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/keyroomdeploy.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT")).catch(function(){})'
  echo "==== stopped ===="; cat "$LOG"; exit 1
fi

# ---------------------------------------------------------------------------
# 4) cache-bust so phones actually pick it up
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
# 5) deploy + verify
#    Always pull the latest deploy-overlay.js fresh (it used to only ever
#    overlay index.html+version.json - fixed 2026-10-27 to overlay any file
#    named in OVERLAY_FILES too) so a stale local copy can't silently drop
#    the standalone tool files again.
# ---------------------------------------------------------------------------
curl -sL -o deploy-overlay.js "$RAWB/deploy-overlay.js"
DEP="deploy-overlay.js"
if [ -n "$DEP" ]; then
  echo "-- deploying ($DEP) --" >> "$LOG"
  OVERLAY_FILES="$FILES" node "$DEP" >> "$LOG" 2>&1
else
  echo "NO DASHBOARD DEPLOYER FOUND in $DASH" >> "$LOG"
fi

sleep 3
curl -s https://lvr-data-a60c1.web.app/ -o /tmp/live-dash.html
echo "-- live check: dashboard --" >> "$LOG"
echo "live version : $(grep -ao 'APP_VERSION=[0-9]*' /tmp/live-dash.html | head -1)" >> "$LOG"
for MARK in 'KEYROOM-SESSION-v1' 'KEYROOM-PILL-v1'; do
  echo "live has $MARK : $(grep -c "$MARK" /tmp/live-dash.html)" >> "$LOG"
done

echo "-- live check: standalone tools --" >> "$LOG"
for F in $FILES; do
  if echo "$FAILED" | grep -q "$F"; then
    echo "$F: SKIPPED - failed its syntax check earlier, was not deployed" >> "$LOG"
    continue
  fi
  CODE=$(curl -s -o /dev/null -w '%{http_code}' "https://lvr-data-a60c1.web.app/$F")
  echo "$F: live status $CODE" >> "$LOG"
done

echo "" >> "$LOG"
echo "Log in to the dashboard with your master PIN as usual, then look for the" >> "$LOG"
echo "new 🔑 Key Tech pill near the top. That takes you into the room - every" >> "$LOG"
echo "tool opens with no further PIN, for 24h from that login." >> "$LOG"
echo "Direct room URL: https://lvr-data-a60c1.web.app/key-room.html" >> "$LOG"

node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/keyroomdeploy.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT — tell Claude done")).catch(e=>console.log("send failed "+e.message))'
echo "==== done ===="; cat "$LOG"
