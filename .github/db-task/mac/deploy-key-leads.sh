#!/bin/bash
# One-shot (run on the Mac): deploy the new Key Technologies Leads viewer as
# a standalone page at lvr-data-a60c1.web.app/key-leads.html - same Firebase
# project/database as the main dashboard, reading from /key_leads/leads
# (the exact node every lead form on keytechnologies.si already writes to -
# the short form, full form, free Website Audit, and all 4 vertical-page
# forms). Its own PIN gate, same family as kt-crm.html's. View every lead,
# filter by source, mark status (new/contacted/responded/client), delete.
# Reuses the same proven deploy-overlay.js already in $DASH, same mechanism
# as every other dashboard/tool patch deploy.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac"
DASH="/Users/mac/lv-dash-work"
LOG=/tmp/keyleadsdeploy.txt
: > "$LOG"

cd "$DASH" || { echo "NO DASH DIR ($DASH)"; exit 1; }

curl -sL -o key-leads.html "$RAWB/key-leads.html"
echo "key-leads.html: $(wc -c < key-leads.html) bytes" >> "$LOG"

# sanity: every inline script block must parse before anything ships
node <<'NODE' >> "$LOG" 2>&1
const fs = require('fs'), cp = require('child_process');
const s = fs.readFileSync('key-leads.html', 'utf8');
const scripts = [...s.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/g)].map(m => m[1]);
if (!scripts.length) { console.log('NO SCRIPT BLOCK FOUND'); process.exit(2); }
fs.writeFileSync('/tmp/_keyleads_block.js', scripts.join('\n;\n'));
const r = cp.spawnSync('node', ['--check', '/tmp/_keyleads_block.js'], { encoding: 'utf8' });
if (r.status) { console.log('SYNTAX CHECK FAILED:\n' + (r.stderr || '')); process.exit(2); }
console.log('syntax check: OK');
NODE
if [ "$?" != "0" ]; then
  echo "SYNTAX CHECK FAILED — not deploying, removing the bad file" >> "$LOG"
  rm -f key-leads.html
  node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/keyleadsdeploy.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT")).catch(function(){})'
  echo "==== stopped ===="; cat "$LOG"; exit 1
fi

# ---------------------------------------------------------------------------
# deploy + verify (same deployer the dashboard patches already use)
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
echo "-- live check --" >> "$LOG"
echo "live /key-leads.html status: $(curl -s -o /tmp/keyleads-live.html -w '%{http_code}' https://lvr-data-a60c1.web.app/key-leads.html)" >> "$LOG"
echo "live bytes: $(wc -c < /tmp/keyleads-live.html 2>/dev/null || echo 0)" >> "$LOG"
echo "live has PIN screen: $(grep -c 'id=\"pin-screen\"' /tmp/keyleads-live.html 2>/dev/null || echo 0)" >> "$LOG"
echo "live has Key Technologies LEADS: $(grep -c 'KEY TECHNOLOGIES — LEADS' /tmp/keyleads-live.html 2>/dev/null || echo 0)" >> "$LOG"

echo "" >> "$LOG"
echo "URL: https://lvr-data-a60c1.web.app/key-leads.html" >> "$LOG"
echo "PIN: 702950 (change it by editing the 'var PIN =' line in key-leads.html and re-running this deploy)" >> "$LOG"

node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/keyleadsdeploy.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT — tell Claude done")).catch(e=>console.log("send failed "+e.message))'
echo "==== done ===="; cat "$LOG"
