#!/bin/bash
# One-shot: give Batman entries a slug, rebuild the Deals site, deploy, and report.
# Run from anywhere:  bash fix-batman.sh
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
cd /Users/mac/wholesale-classic-cars || { echo "no dir"; exit 1; }
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
LOG=/tmp/fixbat.txt
: > "$LOG"

# 1) ensure every Batman entry has a slug (the missing field that kept them out of cars.json)
node -e '
const fs=require("fs");const P="_tools/manual.json";
const m=JSON.parse(fs.readFileSync(P,"utf8"));let fixed=0;
m.forEach(e=>{ if(e.type==="Batman" && !e.slug){
  const h=Math.abs([...(e.model||"")+(e.oid||"")].reduce((a,c)=>((a<<5)-a+c.charCodeAt(0))|0,0)).toString(36);
  e.slug="batman-"+h; fixed++;
}});
if(fixed){fs.writeFileSync(P+".bak-slug",fs.readFileSync(P));fs.writeFileSync(P,JSON.stringify(m,null,1));}
console.log("slug-fixed "+fixed+" batman entr(y/ies)");
' >> "$LOG" 2>&1

# 2) rebuild the site (this is the slow step, ~2-3 min)
echo "-- rebuilding --" >> "$LOG"
node _tools/gen.js >> "$LOG" 2>&1
echo "LOCAL clbm after gen: $(grep -c clbm cars.json)" >> "$LOG"

# 3) deploy only if the rebuild actually included the Batman cards
if [ "$(grep -c clbm cars.json)" -ge 1 ]; then
  echo "-- deploying --" >> "$LOG"
  node _tools/rest-deploy.js >> "$LOG" 2>&1
  echo "LIVE clbm: $(curl -s https://classiccarsforsale-co.web.app/cars.json | grep -c clbm)" >> "$LOG"
else
  echo "STILL 0 after gen — not deploying; sending gen tail for diagnosis" >> "$LOG"
fi

# 4) ship the whole log back to Claude
node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/fixbat.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT — tell Claude done")).catch(e=>console.log("send failed "+e.message))'
