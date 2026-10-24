#!/bin/bash
# One-shot (run on the Mac): fix the real reason the Deals site has had zero
# new listings since 2026-09-21.
#
# ROOT CAUSE (confirmed, not a guess): Craigslist is NOT blocking anything -
# the exact search API the scraper uses was tested live and returned a clean
# 200 with real current listings. The actual bug is that the 6-hour
# auto-cycle (deals-agent.sh, installed by setup-deals-auto.sh) only ever
# ran `gen.js` (rebuild the site FROM manual.json) + `rest-deploy.js`
# (redeploy) - it never ran any of the 21 watch-*.js harvesters that are the
# only thing that actually fetches NEW listings from Craigslist and appends
# them to manual.json. The auto-cycle was rebuilding and redeploying the
# exact same stale data over and over, which is why the live site always
# looked "current" (fresh timestamp) while the listings underneath never
# changed.
#
# This script:
#   1) installs _tools/harvest-all.js - runs all 21 watch-*.js harvesters in
#      sequence (idempotent, dedupe-checked, safe to re-run)
#   2) rewrites deals-agent.sh so the 6h auto-cycle runs harvest-all.js BEFORE
#      gen.js + rest-deploy.js, and reloads the LaunchAgent
#   3) runs one full cycle RIGHT NOW (harvest -> gen -> deploy) so the site
#      gets real fresh listings immediately instead of waiting 6 hours
#   4) verifies against the live site afterward and posts the result back
#
# Idempotent - safe to re-run. Posts its log back to Claude at the end.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com/_deals"
LOG=/tmp/fixdealsharvest.txt
: > "$LOG"
say(){ echo "$@" >> "$LOG"; }

cd /Users/mac/wholesale-classic-cars || { say "ABORT: deals dir not found"; exit 1; }

# ---------------------------------------------------------------------------
# 1) the missing orchestrator - runs every watch-*.js harvester in sequence
# ---------------------------------------------------------------------------
cat > /Users/mac/wholesale-classic-cars/_tools/harvest-all.js <<'JSEOF'
// Orchestrator: runs every watch-*.js harvester in sequence against the LIVE
// Craigslist search API, each as a plain child process (same as running
// `node _tools/watch-X.js` by hand). This was the missing piece in the 6-hour
// auto-cycle: gen.js only REBUILDS the site from whatever is already sitting
// in manual.json, it never re-harvests Craigslist for anything new. Safe to
// re-run any time - every watcher does its own dedupe check against manual.json
// and deleted-tokens.json before adding anything, so running this twice in a
// row just finds 0 new the second time.
const { execFileSync } = require('child_process');
const path = require('path');
const ROOT = __dirname;

const WATCHERS = [
  'watch-200sx.js', 'watch-antiques-pv.js', 'watch-antiques.js', 'watch-batman.js',
  'watch-coland.js', 'watch-ebikes-pv.js', 'watch-ebikes.js', 'watch-fordvan.js',
  'watch-foreclosures.js', 'watch-free.js', 'watch-homes-fsbo-pv.js', 'watch-houses.js',
  'watch-land.js', 'watch-pahrump.js', 'watch-pvcars.js', 'watch-rentals.js',
  'watch-restaurants.js', 'watch-rooms-pv.js', 'watch-rv.js', 'watch-sc430.js', 'watch-tesla.js'
];

let totalAdded = 0;
let failed = 0;
for (const w of WATCHERS) {
  const file = path.join(ROOT, w);
  try {
    const out = execFileSync('node', [file], { encoding: 'utf8', timeout: 180000, cwd: ROOT + '/..' });
    const lastLine = out.trim().split('\n').pop() || '';
    const m = lastLine.match(/ADDED (\d+)/);
    const n = m ? parseInt(m[1], 10) : 0;
    totalAdded += n;
    console.log(w + ': ' + lastLine);
  } catch (e) {
    failed++;
    console.error(w + ': FAILED - ' + e.message.split('\n')[0]);
  }
}
console.log('HARVEST DONE - total new listings added: ' + totalAdded + ', harvesters that failed: ' + failed);
JSEOF
node --check /Users/mac/wholesale-classic-cars/_tools/harvest-all.js 2>>"$LOG" && say "harvest-all.js installed, syntax OK" || { say "ABORT: harvest-all.js failed syntax check"; exit 1; }

# ---------------------------------------------------------------------------
# 2) rewrite the agent loop to actually harvest before rebuilding+deploying
# ---------------------------------------------------------------------------
cat > /Users/mac/deals-agent.sh <<'AGEOF'
#!/bin/bash
# Deals auto-updater. Loops forever: every 30s checks the RTDB flag the site's ⟳
# button sets; every 6h runs a cycle regardless. A cycle = harvest ALL
# Craigslist categories for new listings, gen.js sweep (rebuild), re-apply the
# refresh-button patch, deploy, then stamp _deals/updated so the page knows.
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com/_deals"
cd /Users/mac/wholesale-classic-cars || exit 1
LAST_AUTO=0
while true; do
  NOW=$(date +%s)
  REQ=$(curl -s --max-time 10 "$DB/refresh_request.json" 2>/dev/null)
  HANDLED=$(curl -s --max-time 10 "$DB/refresh_handled.json" 2>/dev/null)
  DO=0
  if [ -n "$REQ" ] && [ "$REQ" != "null" ] && [ "$REQ" != "$HANDLED" ]; then DO=1; fi
  if [ $((NOW-LAST_AUTO)) -ge 21600 ]; then DO=1; fi
  if [ "$DO" -eq 1 ]; then
    echo "[$(date)] cycle start (req=$REQ)" >> /tmp/deals-agent.log
    node _tools/harvest-all.js >> /tmp/deals-agent.log 2>&1
    node _tools/gen.js >> /tmp/deals-agent.log 2>&1
    node /Users/mac/patch-deals-refresh.js >> /tmp/deals-agent.log 2>&1
    node _tools/rest-deploy.js >> /tmp/deals-agent.log 2>&1
    curl -s -X PUT -H "Content-Type: application/json" -d "$(date +%s)000" "$DB/updated.json" > /dev/null
    if [ -n "$REQ" ] && [ "$REQ" != "null" ]; then
      curl -s -X PUT -H "Content-Type: application/json" -d "$REQ" "$DB/refresh_handled.json" > /dev/null
    fi
    LAST_AUTO=$(date +%s)
    echo "[$(date)] cycle done" >> /tmp/deals-agent.log
  fi
  sleep 30
done
AGEOF
chmod +x /Users/mac/deals-agent.sh
say "deals-agent.sh rewritten to harvest before rebuild+deploy"

launchctl unload /Users/mac/Library/LaunchAgents/com.lvr.dealsagent.plist 2>/dev/null
launchctl load /Users/mac/Library/LaunchAgents/com.lvr.dealsagent.plist 2>>"$LOG"
say "launch agent reloaded: $(launchctl list | grep -c com.lvr.dealsagent) (1 = running)"

# ---------------------------------------------------------------------------
# 3) run one full cycle RIGHT NOW so the fix is visible immediately
# ---------------------------------------------------------------------------
say "-- harvesting all 21 categories now (this is the step that was missing, ~3-6 min) --"
node _tools/harvest-all.js >> "$LOG" 2>&1
HARVEST_LINE=$(tail -1 "$LOG")
say "-- gen.js rebuild --"
node _tools/gen.js >> "$LOG" 2>&1
node /Users/mac/patch-deals-refresh.js >> "$LOG" 2>&1
say "-- deploying --"
node _tools/rest-deploy.js >> "$LOG" 2>&1
curl -s -X PUT -H "Content-Type: application/json" -d "$(date +%s)000" "$DB/updated.json" > /dev/null

# ---------------------------------------------------------------------------
# 4) verify against the live site
# ---------------------------------------------------------------------------
say "-- verifying live cars.json --"
curl -s https://classiccarsforsale-co.web.app/cars.json -o /tmp/cars-after-fix.json
node -e '
const fs=require("fs");
const d=JSON.parse(fs.readFileSync("/tmp/cars-after-fix.json","utf8"));
const entries=Array.isArray(d)?d:Object.values(d);
let newest="", newestTs=0, fresh=0;
const THIRTY=30*24*60*60*1000, now=Date.now();
for(const e of entries){
  const a=e.added||e.addedDate||e.date; if(!a) continue;
  const ts=new Date(a).getTime(); if(isNaN(ts)) continue;
  if(ts>newestTs){newestTs=ts;newest=a;}
  if(now-ts<=THIRTY) fresh++;
}
console.log("Total entries:", entries.length);
console.log("Newest added date:", newest);
console.log("Fresh (within 30 days):", fresh);
' >> "$LOG" 2>&1

node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("'"$LOG"'","utf8").slice(-6000))}).then(()=>console.log("LOG SENT — tell Claude done")).catch(e=>console.log("send failed "+e.message))'
echo "==== done ===="; cat "$LOG"
