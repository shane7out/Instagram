#!/bin/bash
# One-shot (run on the Mac): make the dating site skip sign-up on a fresh
# visit and land straight on the swipe deck, then deploy.
# Idempotent - the edit is marker-fenced, so re-running changes nothing.
#
# v2 (2026-10-06): the first version patched a copy of dating.html downloaded
# fresh into lv-dash-work, then tried to deploy it with deploy-overlay.js -
# which only ever uploads /Users/mac/lv-dash-work/index.html (the dashboard),
# never dating.html. Patch applied, "to upload: 0", nothing went live -
# confirmed live afterward (DATEQS01 count stayed 0). The REAL source for
# the live /dating.html page is /Users/mac/spark-dating/index.html, deployed
# by its own proven deployer at /Users/mac/spark-dating/_tools/deploy-dating.js
# (confirmed by reading it: addLocal(path.join(ROOT,'index.html'),'/dating.html'),
# same lvr-data-a60c1 site). This version patches and deploys the real source.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac"
SRC="/Users/mac/spark-dating/index.html"
DEPLOYER="/Users/mac/spark-dating/_tools/deploy-dating.js"
LOG=/tmp/dateqs.txt
: > "$LOG"

[ -f "$SRC" ] || { echo "NO $SRC - the real dating-site source isn't where expected, stopping"; cat "$LOG"; exit 1; }
[ -f "$DEPLOYER" ] || { echo "NO $DEPLOYER - the proven deployer isn't where expected, stopping"; cat "$LOG"; exit 1; }
echo "source file: $SRC ($(wc -c < "$SRC") bytes)" >> "$LOG"

# ---------------------------------------------------------------------------
# 1) the patch
# ---------------------------------------------------------------------------
curl -sL -o /tmp/patch-dating-instant-swipe.js "$RAWB/patch-dating-instant-swipe.js"
echo "patcher: $(wc -c < /tmp/patch-dating-instant-swipe.js) bytes" >> "$LOG"
node /tmp/patch-dating-instant-swipe.js "$SRC" >> "$LOG" 2>&1
PATCH_RC=$?
echo "patch exit: $PATCH_RC" >> "$LOG"

if [ "$PATCH_RC" != "0" ]; then
  echo "PATCH REPORTED A FAILURE — restoring and stopping, nothing deployed" >> "$LOG"
  [ -f "$SRC.bak-dateqs" ] && cp "$SRC.bak-dateqs" "$SRC"
  node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/dateqs.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT")).catch(function(){})'
  echo "==== stopped ===="; cat "$LOG"; exit 1
fi

# ---------------------------------------------------------------------------
# 2) sanity: every inline script must still parse before anything ships
#    (the deployer does its own syntax guard too - this is a second,
#    redundant check that fails before even attempting a deploy)
# ---------------------------------------------------------------------------
SRC="$SRC" node <<'NODE' >> "$LOG" 2>&1
const fs=require('fs'), cp=require('child_process');
const s=fs.readFileSync(process.env.SRC,'utf8');
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
  [ -f "$SRC.bak-dateqs" ] && cp "$SRC.bak-dateqs" "$SRC"
  node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/dateqs.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT")).catch(function(){})'
  echo "==== stopped ===="; cat "$LOG"; exit 1
fi

# ---------------------------------------------------------------------------
# 3) deploy via the real, proven spark-dating deployer + verify
# ---------------------------------------------------------------------------
echo "-- deploying ($DEPLOYER) --" >> "$LOG"
node "$DEPLOYER" >> "$LOG" 2>&1
echo "deploy exit: $?" >> "$LOG"

sleep 3
curl -s https://lvr-data-a60c1.web.app/dating.html -o /tmp/live-dating.html
echo "-- live check --" >> "$LOG"
echo "live dating.html bytes: $(wc -c < /tmp/live-dating.html)" >> "$LOG"
for MARK in 'DATEQS01' 'Instant demo profile' 'guest_'; do
  echo "live has $MARK : $(grep -c "$MARK" /tmp/live-dating.html)" >> "$LOG"
done
echo "live still has the old else-branch (should be 0): $(grep -c 'classList.remove(\"hidden\")); }' /tmp/live-dating.html)" >> "$LOG"

node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/dateqs.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT — tell Claude done")).catch(e=>console.log("send failed "+e.message))'
echo "==== done ===="; cat "$LOG"
