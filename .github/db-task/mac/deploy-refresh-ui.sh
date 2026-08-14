#!/bin/bash
# One-shot (run on the Mac): Deals refresh v8 — the CSP fix.
# ROOT CAUSE FOUND: the site's Content-Security-Policy (script-src 'self') blocks ALL inline
# scripts, so every previous inline version of the refresh logic never ran in browsers.
# v8 ships the logic as an external file (/deals-refresh.js), exactly like gate.js.
#   - baked round button next to the date (HTML, cannot disappear), 26px white arrow
#   - external client: tap -> spin + toast -> cloud sweep -> page fixes itself, date updates
#   - 30-day rule enforced instantly in the page AND by the cloud sweeper
#   - nightly agent patcher = the SAME full patcher, so gen rebuilds keep everything
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/fetched"
LOG=/tmp/rui.txt
: > "$LOG"
cd /Users/mac/wholesale-classic-cars || { echo "no deals dir"; exit 1; }

# ---------------------------------------------------------------------------
# 1) the full idempotent page patcher — used right now AND by the nightly agent
# ---------------------------------------------------------------------------
cat > /Users/mac/patch-deals-refresh.js <<'P8EOF'
// Full v8 page patcher (idempotent). Applies the refresh UI to the Deals index:
//  - strips all older inline refresh blocks (CSP blocked them anyway), old tabs, old buttons
//  - bakes the date (M/D/YY h:mm) + round refresh button as real HTML
//  - appends the v8 style block and the EXTERNAL script tag (cache-busted)
//  - ensures the Eagle Point land tab exists, Batman tab stays gone
const fs=require('fs');
const F='/Users/mac/wholesale-classic-cars/index.html';
let s=fs.readFileSync(F,'utf8'); const before=s;

s=s.replace(/<style>\/\*DEALS-REFRESH-v[12345678]\*\/[\s\S]*?<\/style>\n?/g,'');
s=s.replace(/<script>\/\*DEALS-REFRESH-v[12345678]\*\/[\s\S]*?<\/script>\n?/g,'');
s=s.replace(/\s*<script src="\/deals-refresh\.js[^>]*><\/script>/g,'');
s=s.replace(/\s*<button id="refreshbtn"[\s\S]*?<\/button>/g,'');
s=s.replace(/\s*<a class="tablink"[^>]*>↻ Refresh<\/a>/g,'');
s=s.replace(/\s*<a class="tablink"[^>]*>🦇 Batman Cards<\/a>/g,'');

const la=new Date(new Date().toLocaleString('en-US',{timeZone:'America/Los_Angeles'}));
const stamp=(la.getMonth()+1)+'/'+la.getDate()+'/'+String(la.getFullYear()).slice(-2)+', '+la.toLocaleTimeString('en-US',{hour:'numeric',minute:'2-digit'});
s=s.replace(/(<div class="lastupd" id="lastupd">)[^<]*/,'$1'+stamp);
const BTN='<button id="refreshbtn" title="Refresh listings" aria-label="Refresh listings"><span class="rg">⟳</span></button>';
s=s.replace(/(<div class="lastupd" id="lastupd">[^<]*<\/div>)/,'$1'+BTN);

const CSS='<style>/*DEALS-REFRESH-v8*/'
 +'.hd{display:flex!important;align-items:center!important;justify-content:space-between!important;gap:10px;flex-wrap:wrap}'
 +'#lastupd{margin-left:auto!important;font-size:clamp(15px,3.5vw,21px)!important;font-weight:800!important;line-height:1.25!important;color:#0d47a1!important}'
 +'#refreshbtn{width:38px;height:38px;border-radius:50%;flex:none;'
 +'background:linear-gradient(135deg,#1565d8,#0d47a1);color:#fff;border:none;font-size:26px;font-weight:800;'
 +'cursor:pointer;display:inline-flex;align-items:center;justify-content:center;padding:0;line-height:1;'
 +'box-shadow:0 3px 10px rgba(13,40,80,.4);transition:transform .12s}'
 +'#refreshbtn:hover{transform:scale(1.07)}'
 +'#refreshbtn:active{transform:scale(.94)}'
 +'#refreshbtn.busy .rg{display:inline-block;animation:spinbtn 1s linear infinite}'
 +'#refreshbtn.done{background:linear-gradient(135deg,#1b8a3a,#146c2e)}'
 +'@keyframes spinbtn{to{transform:rotate(360deg)}}'
 +'#rtoast{position:fixed;top:64px;right:14px;z-index:9999;background:rgba(9,25,55,.94);color:#fff;'
 +'font-size:13.5px;font-weight:700;padding:10px 14px;border-radius:12px;max-width:240px;line-height:1.35;'
 +'box-shadow:0 6px 20px rgba(0,0,0,.3);opacity:0;transform:translateY(-6px);transition:opacity .25s,transform .25s;pointer-events:none}'
 +'#rtoast.show{opacity:1;transform:translateY(0)}'
 +'</style>';
const TAG='<script src="/deals-refresh.js?v='+Date.now()+'" defer><\/script>';
s=s.replace(/<\/body>/, CSS+'\n'+TAG+'\n</body>');

// Eagle Point land tab (idempotent)
const TS='display:inline-flex;align-items:center;gap:5px;padding:8px 16px;border-radius:999px;font-size:14px;font-weight:800;text-decoration:none;cursor:pointer';
const LANDTAB='<a class="tablink" href="/land-eaglepoint" style="'+TS+';border:1.5px solid #1b5e20;color:#1b5e20">🌲 Eagle Point Land</a>';
s=s.replace(/\s*<a class="tablink"[^>]*>🌲 Eagle Point Land<\/a>/g,'');
if(/tablink" href="\/coins"/.test(s)) s=s.replace(/(<a class="tablink" href="\/coins"[^>]*>[^<]*<\/a>)/, '$1\n        '+LANDTAB);
else s=s.replace(/(<button class="chip chip-deals"[^>]*>🔥 Deals<\/button>)/, '$1\n        '+LANDTAB);

console.log('baked button: '+(/<button id="refreshbtn"/.test(s)?'yes':'NO'));
console.log('external tag: '+(/script src="\/deals-refresh\.js/.test(s)?'yes':'NO'));
console.log('land tab: '+(/land-eaglepoint/.test(s)?'yes':'NO'));
if(s!==before){fs.writeFileSync(F,s);console.log('v8 patch: applied');}
else console.log('v8 patch: no change');
P8EOF
node /Users/mac/patch-deals-refresh.js >> "$LOG" 2>&1

# ---------------------------------------------------------------------------
# 2) same-site photos (the CSP img-src 'self' blocks every off-site image host)
#    pull every coins/land photo into the site's own /pimg folder
# ---------------------------------------------------------------------------
mkdir -p pimg/coins pimg/land
curl -sL -o /tmp/pimg-manifest.txt "$RAWB/pimg-manifest.txt"
NDL=0; NERR=0
while IFS= read -r f; do
  [ -z "$f" ] && continue
  if [ ! -s "pimg/$f" ]; then
    if curl -sL --fail -o "pimg/$f" "$RAWB/img/$f"; then NDL=$((NDL+1)); else NERR=$((NERR+1)); rm -f "pimg/$f"; fi
  fi
done < /tmp/pimg-manifest.txt
echo "pimg: downloaded $NDL new, errors $NERR, total $(find pimg -name '*.jpg' | wc -l | tr -d ' ')" >> "$LOG"

# ---------------------------------------------------------------------------
# 3) fetch the external client + photo-fixed pages into the site root
# ---------------------------------------------------------------------------
curl -sL -o deals-refresh.js "$RAWB/deals-refresh.js"
echo "deals-refresh.js: $(wc -c < deals-refresh.js) bytes" >> "$LOG"
curl -sL -o coins.html "$RAWB/coins.html"
echo "coins.html: $(wc -c < coins.html) bytes, $(grep -c 'raw.githubusercontent' coins.html) hosted imgs" >> "$LOG"
curl -sL -o land-eaglepoint.html "$RAWB/land-eaglepoint.html"
echo "land-eaglepoint.html: $(wc -c < land-eaglepoint.html) bytes, $(grep -c 'raw.githubusercontent' land-eaglepoint.html) hosted imgs" >> "$LOG"

# ---------------------------------------------------------------------------
# 3) deploy + verify
# ---------------------------------------------------------------------------
echo "-- deploying --" >> "$LOG"
node _tools/rest-deploy.js >> "$LOG" 2>&1
echo "LIVE v8 style: $(curl -s https://classiccarsforsale-co.web.app/ | grep -c 'DEALS-REFRESH-v8')" >> "$LOG"
echo "LIVE external tag: $(curl -s https://classiccarsforsale-co.web.app/ | grep -c 'deals-refresh.js')" >> "$LOG"
echo "LIVE /deals-refresh.js: $(curl -s -o /dev/null -w '%{http_code}' https://classiccarsforsale-co.web.app/deals-refresh.js)" >> "$LOG"
echo "LIVE baked button: $(curl -s https://classiccarsforsale-co.web.app/ | grep -c '<button id=\"refreshbtn\"')" >> "$LOG"
IMG1=$(grep -o '/pimg/[^"]*' coins.html | head -1)
echo "LIVE sample photo ($IMG1): $(curl -s -o /dev/null -w '%{http_code}' https://classiccarsforsale-co.web.app$IMG1)" >> "$LOG"
echo "LIVE /coins pimg refs: $(curl -sL https://classiccarsforsale-co.web.app/coins | grep -c '/pimg/')" >> "$LOG"
echo "LIVE /land-eaglepoint pimg refs: $(curl -sL https://classiccarsforsale-co.web.app/land-eaglepoint | grep -c '/pimg/')" >> "$LOG"

node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/rui.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT — tell Claude done")).catch(e=>console.log("send failed "+e.message))'
echo "==== done ===="; cat "$LOG"
