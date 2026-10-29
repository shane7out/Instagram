#!/bin/bash
# One-shot (run on the Mac): deploy the new Key Technologies Prospect CRM as
# a standalone page at lvr-data-a60c1.web.app/kt-crm.html - same Firebase
# project/database as the main dashboard, but a completely separate login
# (its own PIN, its own /kt_crm/prospects Firebase node) so it never mixes
# with the restaurant data. Reuses the same proven deploy-overlay.js already
# in $DASH, since it just uploads whatever changed files it finds there as a
# new Hosting version - adding one new file is the same mechanism as every
# dashboard patch deploy.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac"
DASH="/Users/mac/lv-dash-work"
LOG=/tmp/ktcrmdeploy.txt
: > "$LOG"

cd "$DASH" || { echo "NO DASH DIR ($DASH)"; exit 1; }

curl -sL -o kt-crm.html "$RAWB/kt-crm.html"
echo "kt-crm.html: $(wc -c < kt-crm.html) bytes" >> "$LOG"

# sanity: the inline script must parse before anything ships
node <<'NODE' >> "$LOG" 2>&1
const fs = require('fs'), cp = require('child_process');
const s = fs.readFileSync('kt-crm.html', 'utf8');
const m = s.match(/<script>([\s\S]*?)<\/script>/);
if (!m) { console.log('NO SCRIPT BLOCK FOUND'); process.exit(2); }
fs.writeFileSync('/tmp/_ktcrm_block.js', m[1]);
const r = cp.spawnSync('node', ['--check', '/tmp/_ktcrm_block.js'], { encoding: 'utf8' });
if (r.status) { console.log('SYNTAX CHECK FAILED:\n' + (r.stderr || '')); process.exit(2); }
console.log('syntax check: OK');
NODE
if [ "$?" != "0" ]; then
  echo "SYNTAX CHECK FAILED — not deploying, removing the bad file" >> "$LOG"
  rm -f kt-crm.html
  node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/ktcrmdeploy.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT")).catch(function(){})'
  echo "==== stopped ===="; cat "$LOG"; exit 1
fi

# ---------------------------------------------------------------------------
# deploy + verify (same deployer the dashboard patches already use)
# ---------------------------------------------------------------------------
curl -sL -o deploy-overlay.js "$RAWB/deploy-overlay.js"
DEP="deploy-overlay.js"
export OVERLAY_FILES="kt-crm.html"
if [ -n "$DEP" ]; then
  echo "-- deploying ($DEP) --" >> "$LOG"
  node "$DEP" >> "$LOG" 2>&1
else
  echo "NO DASHBOARD DEPLOYER FOUND in $DASH" >> "$LOG"
fi

sleep 3
echo "-- live check --" >> "$LOG"
echo "live /kt-crm.html status: $(curl -s -o /tmp/ktcrm-live.html -w '%{http_code}' https://lvr-data-a60c1.web.app/kt-crm.html)" >> "$LOG"
echo "live bytes: $(wc -c < /tmp/ktcrm-live.html 2>/dev/null || echo 0)" >> "$LOG"
echo "live has PIN screen: $(grep -c 'id=\"pin-screen\"' /tmp/ktcrm-live.html 2>/dev/null || echo 0)" >> "$LOG"
echo "live has Key Technologies CRM: $(grep -c 'Key Technologies CRM' /tmp/ktcrm-live.html 2>/dev/null || echo 0)" >> "$LOG"

echo "" >> "$LOG"
echo "URL: https://lvr-data-a60c1.web.app/kt-crm.html" >> "$LOG"
echo "PIN: 137900 (change it by editing the 'var PIN =' line in kt-crm.html and re-running this deploy)" >> "$LOG"

node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/ktcrmdeploy.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT — tell Claude done")).catch(e=>console.log("send failed "+e.message))'
echo "==== done ===="; cat "$LOG"
