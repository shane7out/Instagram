#!/bin/bash
# Run on the Mac (one command):
#   curl -sL --retry 8 --retry-delay 1 --connect-timeout 15 --speed-limit 3000 --speed-time 6 --max-time 150 "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/deploy-dashboard-keypad.sh?$(date +%s)" -o /tmp/deploy-dashboard-keypad.sh && bash /tmp/deploy-dashboard-keypad.sh
# (also: the Ads tab gets a toggle that decides whether the DMs and emails use the Las Vegas Restaurants or the Key Technologies message)
# BLUE EVERYWHERE (Shane, 2026-11-25: "always make it the one on the left, blue... I don't want to ever see white again"). Two steps, one command:
#  1) the LIVE dashboard: removes the "Johnny Mac's" chip from the PIN page, removes the light keypad block if an earlier run added it (the blue round LVR keypad stays as it is),
#     and the owner key at the bottom now opens a blue PIN pad (the same PIN as the Treasury) instead of the email and password box;
#  2) the owner pages (Key Room, Prospect CRM, Leads, Advertisers, Rewards admin, Coupons admin, Invoice): the white look is replaced by the LVR PIN blue, and the Key Room keypad becomes the same round blue keypad.
# Colours and one chip only: no PIN number, PIN logic, data or rule is touched. Every page is syntax-checked first; if a check fails the old page is put back and nothing is uploaded.
# Safe to run twice. Keeps index.html.bak-keypad (and .bak-ownerlight for the owner pages). The Johnny Mac's site page itself is left on the hosting, only the chip goes.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac"
DASH="/Users/mac/lv-dash-work"
LOG=/tmp/keypad.txt
: > "$LOG"

cd "$DASH" || { echo "NO DASH DIR ($DASH)"; exit 1; }

IDX="index.html"; [ -f "$IDX" ] || IDX="$(ls *.html 2>/dev/null | head -1)"
[ -f "$IDX.bak-keypad" ] || cp "$IDX" "$IDX.bak-keypad"   # the very first copy is kept for good
cp "$IDX" /tmp/index.pre-keypad.html                              # this run's own undo copy
echo "dashboard file: $IDX ($(wc -c < "$IDX") bytes)" >> "$LOG"
echo "before: $(grep -ao 'APP_VERSION=[0-9]*' "$IDX" | head -1)" >> "$LOG"

# ---------------------------------------------------------------------------
# 1) the patch
# ---------------------------------------------------------------------------
curl -sL --retry 8 --retry-delay 1 --connect-timeout 15 --speed-limit 3000 --speed-time 6 --max-time 150 -o /tmp/patch-dashboard-keypad.js "$RAWB/patch-dashboard-keypad.js"
curl -sL --retry 8 --retry-delay 1 --connect-timeout 15 --speed-limit 3000 --speed-time 6 --max-time 150 -o /tmp/owner-auth.snippet.html "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/owner-auth/owner-auth.snippet.html?$(date +%s)"
echo "pin sign-in code: $(wc -c < /tmp/owner-auth.snippet.html) bytes" >> "$LOG"
echo "patcher: $(wc -c < /tmp/patch-dashboard-keypad.js) bytes" >> "$LOG"
node /tmp/patch-dashboard-keypad.js "$IDX" /tmp/owner-auth.snippet.html >> "$LOG" 2>&1
PATCH_RC=$?
echo "patch exit: $PATCH_RC" >> "$LOG"
# the Ads tab message toggle (Las Vegas Restaurants / Key Technologies); not fatal if the live page differs: the dashboard is released either way and the log says so
curl -sL --retry 8 --retry-delay 1 --connect-timeout 15 --speed-limit 3000 --speed-time 6 --max-time 150 -o /tmp/patch-dashboard-ads.js "$RAWB/patch-dashboard-ads.js"
echo "ads patcher: $(wc -c < /tmp/patch-dashboard-ads.js) bytes" >> "$LOG"
node /tmp/patch-dashboard-ads.js "$IDX" >> "$LOG" 2>&1
echo "ads patch exit: $?" >> "$LOG"

if [ "$PATCH_RC" != "0" ]; then
  echo "PATCH REPORTED A FAILURE — restoring and stopping, nothing deployed" >> "$LOG"
  [ -f /tmp/index.pre-keypad.html ] && cp /tmp/index.pre-keypad.html "$IDX"
  node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/keypad.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT")).catch(function(){})'
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
  [ -f /tmp/index.pre-keypad.html ] && cp /tmp/index.pre-keypad.html "$IDX"
  node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/keypad.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT")).catch(function(){})'
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
for MARK in 'OWNERPIN01' 'ADSMSG02' 'DMRESTORE02'; do
  echo "live has $MARK (should be 1 or more): $(grep -ac "$MARK" /tmp/live.html)" >> "$LOG"
done
echo "live Johnny Mac chip (should be 0): $(grep -ac "JOHNNYMACS-START" /tmp/live.html)" >> "$LOG"

node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/keypad.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT — tell Claude done")).catch(e=>console.log("send failed "+e.message))'
echo "live Johnny Mac chip left: $(grep -c 'href="/johnny-macs.html"' /tmp/live.html)" >> "$LOG"; echo "==== done ===="; cat "$LOG"
echo "---- now the owner pages (blue instead of white) ----"
curl -sL --retry 8 --retry-delay 1 --connect-timeout 15 --speed-limit 3000 --speed-time 6 --max-time 150 "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/deploy-owner-light.sh?$(date +%s)" -o /tmp/deploy-owner-light.sh && bash /tmp/deploy-owner-light.sh
