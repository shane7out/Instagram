#!/bin/bash
# One-shot (run on the Mac): make the Deals site self-updating.
#   1) installs patch-deals-refresh.js  — adds the round ⟳ button (top-right), big Updated date,
#      and the page-side JS that asks the Mac for a fresh sweep (via an RTDB flag)
#   2) installs deals-agent.sh + a LaunchAgent — re-sweeps + redeploys every 6h while the Mac
#      is awake, and within ~30s whenever the ⟳ button is pressed
#   3) runs one full sweep+deploy RIGHT NOW so the data stops saying Aug 3
# Idempotent — safe to re-run. Posts its log back to Claude at the end.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
LOG=/tmp/setupauto.txt
: > "$LOG"
say(){ echo "$@" >> "$LOG"; }

# ---------------------------------------------------------------------------
# 1) the idempotent page patcher (re-applied after every gen.js run)
# ---------------------------------------------------------------------------
cat > /Users/mac/patch-deals-refresh.js <<'JSEOF'
// Adds/refreshes the DEALS-REFRESH-v1 block in index.html:
//  - round ⟳ button fixed top-right (spins while a refresh runs)
//  - #lastupd (Updated date) enlarged to match the car-count size
//  - page JS: writes a refresh request to RTDB, polls for completion, reloads;
//    on load, overwrites the date from RTDB so it is always current
// Also removes the old "↻ Refresh" tab (superseded by the button). Idempotent.
const fs=require('fs');
const F='/Users/mac/wholesale-classic-cars/index.html';
let s=fs.readFileSync(F,'utf8'); const before=s;

// drop old versions of our block + the old refresh tab
s=s.replace(/<style>\/\*DEALS-REFRESH-v1\*\/[\s\S]*?<\/style>\n?/g,'');
s=s.replace(/<script>\/\*DEALS-REFRESH-v1\*\/[\s\S]*?<\/script>\n?/g,'');
s=s.replace(/\s*<a class="tablink"[^>]*>↻ Refresh<\/a>/g,'');

const CSS='<style>/*DEALS-REFRESH-v1*/'
 +'#refreshbtn{position:fixed;top:12px;right:12px;width:46px;height:46px;border-radius:50%;'
 +'border:2px solid #0d47a1;background:#fff;color:#0d47a1;font-size:24px;font-weight:800;'
 +'cursor:pointer;z-index:9999;box-shadow:0 4px 14px rgba(13,40,80,.25);display:flex;'
 +'align-items:center;justify-content:center;padding:0;line-height:1}'
 +'#refreshbtn.busy{animation:spinbtn 1s linear infinite;opacity:.75}'
 +'@keyframes spinbtn{to{transform:rotate(360deg)}}'
 +'#lastupd{font-size:clamp(17px,4vw,24px)!important;font-weight:800!important;line-height:1.25!important;color:#0d47a1!important}'
 +'</style>';

const JS='<script>/*DEALS-REFRESH-v1*/\n'
 +"(function(){\n"
 +"var DB='https://lvr-data-a60c1-default-rtdb.firebaseio.com/_deals';\n"
 +"var btn=document.createElement('button');btn.id='refreshbtn';btn.title='Refresh listings';\n"
 +"btn.setAttribute('aria-label','Refresh listings');btn.innerHTML='\\u27F3';\n"
 +"document.body.appendChild(btn);\n"
 +"function el(){return document.getElementById('lastupd');}\n"
 +"function fmt(ts){var d=new Date(ts);return 'Updated '+d.toLocaleDateString('en-US',{month:'short',day:'numeric'})+', '+d.toLocaleTimeString('en-US',{hour:'numeric',minute:'2-digit'});}\n"
 +"var base=null;\n"
 +"fetch(DB+'/updated.json').then(function(r){return r.json();}).then(function(ts){if(ts){base=ts;if(el())el().textContent=fmt(ts);}}).catch(function(){});\n"
 +"btn.onclick=function(){\n"
 +" if(btn.classList.contains('busy'))return;\n"
 +" btn.classList.add('busy');\n"
 +" if(el())el().textContent='Refreshing\\u2026 takes a few minutes';\n"
 +" fetch(DB+'/refresh_request.json',{method:'PUT',body:JSON.stringify(Date.now())}).then(function(){\n"
 +"  var n=0;var iv=setInterval(function(){n++;\n"
 +"   fetch(DB+'/updated.json').then(function(r){return r.json();}).then(function(ts){\n"
 +"    if(ts&&(!base||ts>base)&&ts!==base){clearInterval(iv);location.replace('/?r='+Date.now());}\n"
 +"    else if(n>=40){clearInterval(iv);btn.classList.remove('busy');if(el())el().textContent='No response \\u2014 is the Mac awake?';}\n"
 +"   }).catch(function(){});\n"
 +"  },15000);\n"
 +" }).catch(function(){btn.classList.remove('busy');if(el())el().textContent='Refresh failed \\u2014 no connection';});\n"
 +"};\n"
 +"})();\n"
 +'</script>';

s=s.replace(/<\/body>/, CSS+'\n'+JS+'\n</body>');
if(s!==before){fs.writeFileSync(F,s);console.log('refresh block: applied');}
else console.log('refresh block: NO CHANGE (unexpected)');
console.log('button present: '+(/refreshbtn/.test(s)?'yes':'no')+' | big date css: '+(/DEALS-REFRESH-v1/.test(s)?'yes':'no'));
JSEOF
say "patch-deals-refresh.js installed"

# ---------------------------------------------------------------------------
# 2) the agent: 6h auto-cycle + button listener (runs while the Mac is awake)
# ---------------------------------------------------------------------------
cat > /Users/mac/deals-agent.sh <<'AGEOF'
#!/bin/bash
# Deals auto-updater. Loops forever: every 30s checks the RTDB flag the site's ⟳
# button sets; every 6h runs a cycle regardless. A cycle = gen.js sweep, re-apply
# the refresh-button patch, deploy, then stamp _deals/updated so the page knows.
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
say "deals-agent.sh installed"

# LaunchAgent so it starts on login and stays running
mkdir -p /Users/mac/Library/LaunchAgents
cat > /Users/mac/Library/LaunchAgents/com.lvr.dealsagent.plist <<'PLEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.lvr.dealsagent</string>
  <key>ProgramArguments</key><array>
    <string>/bin/bash</string><string>/Users/mac/deals-agent.sh</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>/tmp/deals-agent-launchd.log</string>
  <key>StandardErrorPath</key><string>/tmp/deals-agent-launchd.log</string>
</dict></plist>
PLEOF
launchctl unload /Users/mac/Library/LaunchAgents/com.lvr.dealsagent.plist 2>/dev/null
launchctl load /Users/mac/Library/LaunchAgents/com.lvr.dealsagent.plist 2>>"$LOG"
say "launch agent loaded: $(launchctl list | grep -c com.lvr.dealsagent) (1 = running)"

# ---------------------------------------------------------------------------
# 3) one full cycle right now so the site freshens immediately (~2-4 min)
# ---------------------------------------------------------------------------
cd /Users/mac/wholesale-classic-cars || { say "no deals dir"; }
say "-- running sweep now (gen.js, ~2-4 min) --"
node _tools/gen.js >> "$LOG" 2>&1
tail -5 "$LOG" > /tmp/gentail.txt
node /Users/mac/patch-deals-refresh.js >> "$LOG" 2>&1
say "-- deploying --"
node _tools/rest-deploy.js >> "$LOG" 2>&1
curl -s -X PUT -H "Content-Type: application/json" -d "$(date +%s)000" "$DB/_deals/updated.json" > /dev/null
say "LIVE has refresh button: $(curl -s https://classiccarsforsale-co.web.app/ | grep -c refreshbtn) (>0 = yes)"

# ---------------------------------------------------------------------------
node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/setupauto.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT — tell Claude done")).catch(e=>console.log("send failed "+e.message))'
echo "==== done ===="; tail -30 "$LOG"
