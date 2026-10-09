#!/bin/bash
# One-shot, run on the Mac: exports _tools/manual.json (the Deals site's actual
# live listing data - all ~20 Craigslist category watchers write into this one
# file) to Firebase diag so Claude can read it. This file was too big for the
# earlier scraper-source export (which skips anything over 200KB), so this
# script gzips + base64s it and uploads in chunks to stay well within a safe
# single-write size. Nothing sensitive here - just scraped public listing data
# (titles, prices, photo URLs) you're already showing publicly on the site.
set +e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
SRC_DIR="/Users/mac/wholesale-classic-cars"
MANUAL="$SRC_DIR/_tools/manual.json"
LOG=/tmp/deals-manual-export.txt
: > "$LOG"
say(){ echo "$@" >> "$LOG"; }

if [ ! -f "$MANUAL" ]; then
  say "NO $MANUAL found"; cat "$LOG"
  node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("'"$LOG"'","utf8"))}).catch(function(){})' 2>/dev/null
  exit 1
fi

say "manual.json size: $(wc -c < "$MANUAL") bytes"

node <<NODE >> "$LOG" 2>&1
const fs = require('fs'), zlib = require('zlib'), https = require('https'), crypto = require('crypto');
const raw = fs.readFileSync('$MANUAL');
const gz = zlib.gzipSync(raw, { level: 9 });
const b64 = gz.toString('base64');
const fullHash = crypto.createHash('sha256').update(b64).digest('hex');
console.log('raw: ' + raw.length + ' bytes, gzip+base64: ' + b64.length + ' bytes, sha256: ' + fullHash);

const CHUNK = 150000; // smaller chunks (prior 300000-char attempt silently lost bytes on one chunk)
const chunks = [];
for (let i = 0; i < b64.length; i += CHUNK) chunks.push(b64.slice(i, i + CHUNK));
console.log('splitting into ' + chunks.length + ' chunk(s)');
const chunkHashes = chunks.map(c => crypto.createHash('sha256').update(c).digest('hex'));

function put(path, body) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const u = new URL('$DB' + path);
    const req = https.request(u, { method: 'PUT', headers: { 'Content-Type': 'application/json' } }, r => {
      let d = ''; r.on('data', c => d += c); r.on('end', () => resolve({ status: r.statusCode, body: d }));
    });
    req.on('error', reject);
    req.write(data); req.end();
  });
}

(async () => {
  // fresh path each run (timestamped) so a prior partial/corrupt attempt can never bleed into this one
  const RUNID = 'run_' + Date.now();
  for (let i = 0; i < chunks.length; i++) {
    const r = await put('/_debug/deals_manual_json/' + RUNID + '/chunks/' + i + '.json', chunks[i]);
    console.log('chunk ' + i + '/' + (chunks.length - 1) + ' upload status: ' + r.status + ' (len ' + chunks[i].length + ', sha256 ' + chunkHashes[i].slice(0,12) + ')');
    if (r.status !== 200) { console.log('ABORT on chunk ' + i); process.exit(1); }
  }
  const meta = { count: chunks.length, rawBytes: raw.length, gzB64Bytes: b64.length, fullHash, chunkHashes, chunkSize: CHUNK, runId: RUNID, uploadedAt: Date.now() };
  const r = await put('/_debug/deals_manual_json/' + RUNID + '/meta.json', meta);
  console.log('meta upload status: ' + r.status);
  const r2 = await put('/_debug/deals_manual_json_latest.json', RUNID);
  console.log('latest-pointer upload status: ' + r2.status + ' -> ' + RUNID);
})();
NODE

node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("'"$LOG"'","utf8").slice(-5000))}).then(()=>console.log("LOG SENT — tell Claude done")).catch(e=>console.log("send failed "+e.message))'
echo "==== done ===="; cat "$LOG"
