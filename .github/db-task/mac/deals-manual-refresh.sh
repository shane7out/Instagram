#!/bin/bash
# One-shot, run on the Mac RIGHT NOW: full Deals site sweep + redeploy.
# This is the exact cycle deals-agent.sh is supposed to be running every 6h
# in the background - running it directly here guarantees it happens now,
# regardless of whether the background agent is actually running.
#   1) node _tools/gen.js        - re-scans Craigslist, finds NEW listings
#   2) patch-deals-refresh.js    - keeps the refresh-button UI clean
#   3) node _tools/rest-deploy.js - redeploys the live site
#   4) stamps _deals/updated so the site shows a current timestamp
# Reports live listing count before/after so you can see it actually worked.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
LIVE="https://classiccarsforsale-co.web.app"
LOG=/tmp/deals-manual-refresh.txt
: > "$LOG"
say(){ echo "$@" >> "$LOG"; }

cd /Users/mac/wholesale-classic-cars || { say "NO /Users/mac/wholesale-classic-cars - can't run from here"; cat "$LOG"; exit 1; }

BEFORE=$(curl -s "$LIVE/?ci=$(date +%s)" | grep -oE '<article class="card' | wc -l | tr -d ' ')
say "live card count BEFORE: $BEFORE"

say "-- node _tools/gen.js --"
node _tools/gen.js >> "$LOG" 2>&1
GEN_RC=$?
say "gen.js exit: $GEN_RC"
if [ "$GEN_RC" != "0" ]; then
  say "gen.js FAILED - stopping before deploy, nothing changed on the live site"
  node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/deals-manual-refresh.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT")).catch(function(){})'
  echo "==== stopped ===="; cat "$LOG"; exit 1
fi

if [ -f /Users/mac/patch-deals-refresh.js ]; then
  node /Users/mac/patch-deals-refresh.js >> "$LOG" 2>&1
else
  say "patch-deals-refresh.js not found - skipping (cosmetic only, not required)"
fi

say "-- node _tools/rest-deploy.js --"
node _tools/rest-deploy.js >> "$LOG" 2>&1
DEPLOY_RC=$?
say "deploy exit: $DEPLOY_RC"

curl -s -X PUT -H "Content-Type: application/json" -d "$(date +%s)000" "$DB/_deals/updated.json" > /dev/null

sleep 3
AFTER=$(curl -s "$LIVE/?ci=$(date +%s)" | grep -oE '<article class="card' | wc -l | tr -d ' ')
say "live card count AFTER: $AFTER (was $BEFORE)"

node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/deals-manual-refresh.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT — tell Claude done")).catch(e=>console.log("send failed "+e.message))'
echo "==== done ===="; cat "$LOG"
