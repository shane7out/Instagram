#!/bin/bash
# Run on the Mac (one command):
#   curl -sL "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/deploy-johnny-macs.sh?$(date +%s)" -o /tmp/deploy-johnny-macs.sh && bash /tmp/deploy-johnny-macs.sh
# Publishes the Johnny Mac's Sports Bar & Grill site (rebuilt from johnnymacswings.com) on the LVR dashboard hosting at
#   lvr-data-a60c1.web.app/johnny-macs.html
# and adds a "Johnny Mac's" chip to the PIN-pad page next to the other site chips (same look as Private Chef / Saint Rita's).
# Idempotent. Syntax-checks the dashboard's inline scripts before shipping; on failure restores the old page and uploads nothing.
# Keeps index.html.bak-johnnymacs. No PIN, data or rule is touched.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/fetched"
DASH="/Users/mac/lv-dash-work"
LOG=/tmp/johnnymacs.txt
: > "$LOG"
cd "$DASH" || { echo "NO DASH DIR ($DASH)"; exit 1; }

send() { node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/johnnymacs.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT — tell Claude done")).catch(e=>console.log("send failed "+e.message))'; }

# 1) the site
curl -sL -o johnny-macs.html "$RAWB/johnny-macs-single.html?$(date +%s)"
SZ=$(wc -c < johnny-macs.html)
echo "johnny-macs.html: $SZ bytes" >> "$LOG"
if [ "$SZ" -lt 100000 ] || ! grep -q "Johnny Mac" johnny-macs.html; then
  echo "DOWNLOAD LOOKS WRONG - nothing changed" >> "$LOG"; send; cat "$LOG"; exit 1
fi

# 2) the chip + version bump
IDX="index.html"; [ -f "$IDX" ] || IDX="$(ls *.html 2>/dev/null | head -1)"
echo "dashboard file: $IDX ($(wc -c < "$IDX") bytes)" >> "$LOG"
[ -f "$IDX.bak-johnnymacs" ] || cp "$IDX" "$IDX.bak-johnnymacs"
IDX="$IDX" node <<'NODE' >> "$LOG" 2>&1
const fs=require('fs'); const F=process.env.IDX;
let s=fs.readFileSync(F,'utf8'); const before=s;
s=s.replace(/\s*<!-- JOHNNYMACS-START -->[\s\S]*?<!-- JOHNNYMACS-END -->/g,'');
const CHIP='\n  <!-- JOHNNYMACS-START -->\n'
 +'  <a href="/johnny-macs.html" target="_blank" rel="noopener"\n'
 +'     style="display:inline-block;text-decoration:none;\n'
 +'            color:rgba(255,255,255,0.55);font-size:14px;letter-spacing:0.01em;\n'
 +'            border:1px solid rgba(255,255,255,0.25);border-radius:10px;\n'
 +'            padding:8px 20px;">Johnny Mac\'s</a>\n  <!-- JOHNNYMACS-END -->';
// after the Saint Rita's chip, else after Private Chef, else after Deals
let m=s.match(/(<a href="\/st-ritas\.html"[\s\S]*?<\/a>)/)
   || s.match(/(<a href="https:\/\/private-table-lv\.web\.app"[\s\S]*?>Private Chef<\/a>)/)
   || s.match(/(<a href="https:\/\/classiccarsforsale-co\.web\.app"[\s\S]*?>Deals<\/a>)/);
if(m){ s=s.replace(m[1], m[1]+CHIP); console.log('chip inserted'); } else { console.log('ANCHOR NOT FOUND - chip not inserted'); process.exit(3); }
const vm=s.match(/APP_VERSION\s*=\s*(\d+)/);
if(vm){ const nv=parseInt(vm[1],10)+1; s=s.replace(/APP_VERSION\s*=\s*\d+/,'APP_VERSION='+nv); console.log('APP_VERSION '+vm[1]+' -> '+nv);
  try{ if(fs.existsSync('version.json')) { fs.writeFileSync('version.json',JSON.stringify({v:nv})); console.log('version.json -> '+nv); } }catch(e){} }
fs.writeFileSync(F,s);
// every inline script must still parse
const cp=require('child_process'); const re=/<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/g; let b,n=0,bad=0;
while((b=re.exec(s))){ if(/application\/ld\+json/.test(b[0])||!b[1].trim())continue; n++; fs.writeFileSync('/tmp/_blk.js',b[1]);
  const r=cp.spawnSync('node',['--check','/tmp/_blk.js'],{encoding:'utf8'}); if(r.status){bad++;console.log('SCRIPT '+n+' FAILED: '+(r.stderr||'').split('\n')[0]);} }
console.log('inline scripts checked: '+n+', failures: '+bad);
if(bad) process.exit(2);
NODE
RC=$?
if [ "$RC" != "0" ]; then
  echo "PATCH FAILED (exit $RC) - restoring, nothing deployed" >> "$LOG"
  cp "$IDX.bak-johnnymacs" "$IDX"; [ -f version.json.bak-johnnymacs ] && cp version.json.bak-johnnymacs version.json
  send; cat "$LOG"; exit 1
fi

# 3) deploy + verify
DEP="$(ls deploy-overlay.js 2>/dev/null | head -1)"; [ -z "$DEP" ] && DEP="$(ls *overlay*.js deploy*.js 2>/dev/null | head -1)"
if [ -n "$DEP" ]; then echo "-- deploying ($DEP) --" >> "$LOG"; OVERLAY_FILES="johnny-macs.html" node "$DEP" >> "$LOG" 2>&1
else echo "NO DASHBOARD DEPLOYER FOUND in $DASH" >> "$LOG"; fi
sleep 3
echo "-- live check --" >> "$LOG"
echo "LIVE /johnny-macs.html: $(curl -sL -o /dev/null -w '%{http_code} %{size_download} bytes' https://lvr-data-a60c1.web.app/johnny-macs.html)" >> "$LOG"
echo "LIVE chip on dashboard: $(curl -s https://lvr-data-a60c1.web.app/ | grep -c 'johnny-macs.html')" >> "$LOG"
send; echo "==== done ===="; cat "$LOG"
