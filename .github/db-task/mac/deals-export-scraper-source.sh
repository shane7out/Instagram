#!/bin/bash
# One-shot, run on the Mac: exports the Deals scraper's actual source code
# (gen.js + rest-deploy.js + anything else in _tools/, plus package.json if
# present) to Firebase diag so Claude can read it and port it to GitHub
# Actions. Nothing sensitive in these files (no API keys - gen.js just
# scrapes public Craigslist search pages), so this is safe to upload.
set +e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
SRC_DIR="/Users/mac/wholesale-classic-cars"
LOG=/tmp/deals-export.txt
: > "$LOG"
say(){ echo "$@" >> "$LOG"; }

cd "$SRC_DIR" || { say "NO $SRC_DIR"; cat "$LOG"; exit 1; }

say "=== _tools/ directory listing ==="
ls -la _tools/ >> "$LOG" 2>&1

node <<'NODE' >> "$LOG" 2>&1
const fs = require('fs'), path = require('path');
const DIR = '_tools';
const out = {};
function walk(d) {
  for (const f of fs.readdirSync(d)) {
    const p = path.join(d, f);
    const st = fs.statSync(p);
    if (st.isDirectory()) { walk(p); continue; }
    if (/\.(js|json)$/.test(f) && st.size < 200000) {
      out[p] = fs.readFileSync(p, 'utf8');
    }
  }
}
try { walk(DIR); } catch (e) { console.log('walk error: ' + e.message); }
if (fs.existsSync('package.json')) out['package.json'] = fs.readFileSync('package.json', 'utf8');
console.log('files collected: ' + Object.keys(out).join(', '));
fs.writeFileSync('/tmp/deals-scraper-source.json', JSON.stringify(out));
console.log('payload size: ' + fs.statSync('/tmp/deals-scraper-source.json').size + ' bytes');
NODE

say "-- uploading to Firebase diag --"
node -e '
const fs=require("fs");
const body=fs.readFileSync("/tmp/deals-scraper-source.json","utf8");
fetch("'"$DB"'/_debug/deals_scraper_source.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:body})
  .then(r=>console.log("upload status: "+r.status))
  .catch(e=>console.log("upload failed: "+e.message));
' >> "$LOG" 2>&1

node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/deals-export.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT — tell Claude done")).catch(e=>console.log("send failed "+e.message))'
echo "==== done ===="; cat "$LOG"
