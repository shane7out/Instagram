#!/bin/bash
# One-shot (run on the Mac): publish the Site Index page and add its pill to the dashboard.
#   1) puts sites.html on the dashboard's own hosting  -> lvr-data-a60c1.web.app/sites.html
#      (same place badges.html and dating.html already live, so it works immediately —
#       no dependence on the GitHub Pages toggle)
#   2) adds an "All Sites" pill to the PIN-pad dashboard, right after the Deals pill
#   3) bumps APP_VERSION + version.json so phones pick it up, then deploys
# Idempotent — safe to re-run. Posts its log back to Claude at the end.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/fetched"
DASH="/Users/mac/lv-dash-work"
LOG=/tmp/sitespill.txt
: > "$LOG"

cd "$DASH" || { echo "NO DASH DIR ($DASH)"; exit 1; }

# ---------------------------------------------------------------------------
# 1) the page itself
# ---------------------------------------------------------------------------
curl -sL -o sites.html "$RAWB/sites.html"
echo "sites.html: $(wc -c < sites.html) bytes, $(grep -c 'class=\"site\"' sites.html) entries" >> "$LOG"

# ---------------------------------------------------------------------------
# 2) the pill + version bump
# ---------------------------------------------------------------------------
IDX="index.html"; [ -f "$IDX" ] || IDX="$(ls *.html 2>/dev/null | head -1)"
echo "dashboard file: $IDX" >> "$LOG"
IDX="$IDX" node <<'NODE' >> "$LOG" 2>&1
const fs=require('fs');
const F=process.env.IDX||'index.html';
let s=fs.readFileSync(F,'utf8'); const before=s;

// remove any previous copy of this pill, then insert a fresh one after the Deals pill
s=s.replace(/\s*<!-- Site Index[\s\S]*?<\/a>/g,'');
s=s.replace(/\s*<a href="\/sites\.html"[\s\S]*?<\/a>/g,'');
const PILL='\n  <!-- Site Index: every site you own, with live status -->\n'
 +'  <a href="/sites.html" target="_blank" rel="noopener"\n'
 +'     style="display:inline-block;text-decoration:none;\n'
 +'            color:rgba(255,255,255,0.55);font-size:14px;letter-spacing:0.01em;\n'
 +'            border:1px solid rgba(255,255,255,0.25);border-radius:10px;\n'
 +'            padding:8px 20px;">All Sites</a>';
const m=s.match(/(<a href="https:\/\/classiccarsforsale-co\.web\.app"[\s\S]*?>Deals<\/a>)/);
if(m){ s=s.replace(m[1], m[1]+PILL); console.log('pill inserted after Deals'); }
else { console.log('DEALS ANCHOR NOT FOUND — pill not inserted'); }

// cache-bust so phones actually see it
const vm=s.match(/APP_VERSION\s*=\s*(\d+)/); let newv=null;
if(vm){ newv=parseInt(vm[1],10)+1; s=s.replace(/APP_VERSION\s*=\s*\d+/, 'APP_VERSION='+newv); console.log('APP_VERSION '+vm[1]+' -> '+newv); }
if(s!==before){ fs.writeFileSync(F+'.bak-sites',before); fs.writeFileSync(F,s); console.log('dashboard patched'); }
else console.log('dashboard: no change');
try{
  if(fs.existsSync('version.json') && newv!=null){
    fs.writeFileSync('version.json.bak-sites', fs.readFileSync('version.json'));
    fs.writeFileSync('version.json', JSON.stringify({v:newv}));
    console.log('version.json -> {"v":'+newv+'}');
  }
}catch(e){ console.log('version.json: '+e.message); }
console.log('pill present: '+(/href="\/sites\.html"/.test(s)?'yes':'NO'));
NODE

# ---------------------------------------------------------------------------
# 3) deploy + verify
# ---------------------------------------------------------------------------
DEP="$(ls deploy-overlay.js 2>/dev/null | head -1)"
[ -z "$DEP" ] && DEP="$(ls *overlay*.js deploy*.js 2>/dev/null | head -1)"
if [ -n "$DEP" ]; then
  echo "-- deploying ($DEP) --" >> "$LOG"
  node "$DEP" >> "$LOG" 2>&1
else
  echo "NO DASHBOARD DEPLOYER FOUND in $DASH" >> "$LOG"
fi
echo "LIVE /sites.html: $(curl -sL -o /dev/null -w '%{http_code}' https://lvr-data-a60c1.web.app/sites.html)" >> "$LOG"
echo "LIVE pill on dashboard: $(curl -s https://lvr-data-a60c1.web.app/ | grep -c '/sites.html')" >> "$LOG"

node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/sitespill.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT — tell Claude done")).catch(e=>console.log("send failed "+e.message))'
echo "==== done ===="; cat "$LOG"
