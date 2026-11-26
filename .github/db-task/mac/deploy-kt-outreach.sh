#!/bin/bash
# One-shot (run on the Mac): puts the Key Technologies DM room on the Las Vegas Restaurants site.
#   curl -sL --retry 3 --retry-delay 2 --connect-timeout 15 --max-time 120 "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/deploy-kt-outreach.sh?$(date +%s)" -o /tmp/deploy-kt-outreach.sh && bash /tmp/deploy-kt-outreach.sh
#
# What it does (additive; nothing is removed, no PIN, rule or data changes):
#   1. adds https://lvr-data-a60c1.web.app/kt-outreach.html : the outreach page with a switch "Market Key Technologies" / "Market Las Vegas Restaurants"
#      (each with its OWN fresh DM list), reading the same advertiser pool as the dashboard's Ads tab;
#   2. re-publishes key-room.html with one new card, "Send DMs: Key Technologies".
# After it: log into the dashboard with your keypad > tap the "Key Tech" button next to Teams > "Send DMs: Key Technologies".
# On that page, tap "Sign in as owner" (bottom right) once so your lists save to the database and show on every device.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac"
DASH="/Users/mac/lv-dash-work"
LOG=/tmp/ktoutreachdeploy.txt
: > "$LOG"
cd "$DASH" || { echo "NO DASH DIR ($DASH)"; exit 1; }
curl -sL --retry 3 --retry-delay 2 --connect-timeout 15 --max-time 120 -o kt-outreach.html "$RAWB/kt-outreach.html?$(date +%s)"
curl -sL --retry 3 --retry-delay 2 --connect-timeout 15 --max-time 120 -o key-room.html "$RAWB/key-room.html?$(date +%s)"
echo "kt-outreach.html: $(wc -c < kt-outreach.html) bytes; key-room.html: $(wc -c < key-room.html) bytes" >> "$LOG"
node <<'NODE' >> "$LOG" 2>&1
const fs = require('fs'), cp = require('child_process');
let bad = 0;
for (const f of ['kt-outreach.html', 'key-room.html']) {
  const s = fs.readFileSync(f, 'utf8');
  const blocks = [...s.matchAll(/<script>([\s\S]*?)<\/script>/g)].map(m => m[1]).join('\n;\n');
  if (!blocks) { console.log(f + ': NO SCRIPT'); bad = 1; continue; }
  fs.writeFileSync('/tmp/_chk.js', blocks);
  const r = cp.spawnSync('node', ['--check', '/tmp/_chk.js'], { encoding: 'utf8' });
  if (r.status) { console.log(f + ': SYNTAX CHECK FAILED\n' + (r.stderr || '')); bad = 1; } else console.log(f + ': syntax OK');
}
if (!/Send DMs: Key Technologies/.test(fs.readFileSync('key-room.html', 'utf8'))) { console.log('key-room.html is missing the new card'); bad = 1; }
process.exit(bad);
NODE
if [ "$?" != "0" ]; then echo "CHECK FAILED - not deploying" >> "$LOG"; echo "==== stopped ===="; cat "$LOG"; exit 1; fi
curl -sL --retry 3 --retry-delay 2 --connect-timeout 15 --max-time 120 -o deploy-overlay.js "$RAWB/deploy-overlay.js"
export OVERLAY_FILES="kt-outreach.html key-room.html"
echo "-- deploying --" >> "$LOG"
node deploy-overlay.js >> "$LOG" 2>&1
sleep 3
echo "live /kt-outreach.html: HTTP $(curl -s -o /tmp/kto-live.html -w '%{http_code}' https://lvr-data-a60c1.web.app/kt-outreach.html), has the switch: $(grep -c 'Market Key Technologies' /tmp/kto-live.html 2>/dev/null)" >> "$LOG"
echo "live /key-room.html has the new card: $(curl -s https://lvr-data-a60c1.web.app/key-room.html | grep -c 'Send DMs: Key Technologies')" >> "$LOG"
node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/ktoutreach.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/ktoutreachdeploy.txt","utf8").slice(-1500))}).then(()=>console.log("SENT result"))'
echo "==== done ===="; cat "$LOG"
