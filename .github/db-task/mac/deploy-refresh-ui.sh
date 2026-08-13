#!/bin/bash
# One-shot (run on the Mac): put the ALS-style refresh UI on the Deals page and deploy.
# After this ONE deploy, refreshing is handled by GitHub in the cloud — laptop can stay off.
#   - big time next to the car count (no "Updated" word), round ⟳ circle right after it
#   - the page reads _deals/updated + _deals/removed from the database live
#   - tapping ⟳ writes the request flag; GitHub checks every 15 min, prunes sold cars,
#     stamps the time; the page updates itself in place
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
LOG=/tmp/rui.txt
: > "$LOG"
cd /Users/mac/wholesale-classic-cars || { echo "no deals dir"; exit 1; }

node <<'NODE' >> "$LOG" 2>&1
const fs=require('fs');
const F='index.html';
let s=fs.readFileSync(F,'utf8'); const before=s;

// strip every older refresh UI (v1 corner button, v2/v3 blocks, old ↻ tab, prior v4)
s=s.replace(/<style>\/\*DEALS-REFRESH-v[1234]\*\/[\s\S]*?<\/style>\n?/g,'');
s=s.replace(/<script>\/\*DEALS-REFRESH-v[1234]\*\/[\s\S]*?<\/script>\n?/g,'');
s=s.replace(/\s*<a class="tablink"[^>]*>\u21bb Refresh<\/a>/g,'');
s=s.replace(/\s*<a class="tablink"[^>]*>\ud83e\udd87 Batman Cards<\/a>/g,'');
// baked date: fresh M/D/YY h:mm AM stamp (page JS overwrites from the database anyway)
const la=new Date(new Date().toLocaleString('en-US',{timeZone:'America/Los_Angeles'}));
const stamp=(la.getMonth()+1)+'/'+la.getDate()+'/'+String(la.getFullYear()).slice(-2)+', '+la.toLocaleTimeString('en-US',{hour:'numeric',minute:'2-digit'});
s=s.replace(/(<div class="lastupd" id="lastupd">)[^<]*/,'$1'+stamp+' ');

const CSS='<style>/*DEALS-REFRESH-v4*/'
 +'.hd{display:flex!important;align-items:center!important;justify-content:space-between!important;gap:10px;flex-wrap:wrap}'
 +'#lastupd{margin-left:auto!important;font-size:clamp(13px,3vw,18px)!important;font-weight:800!important;line-height:1.25!important;color:#0d47a1!important;display:flex;align-items:center;gap:7px}'
 +'#refreshbtn{display:inline-flex;align-items:center;justify-content:center;width:34px;height:34px;border-radius:50%;'
 +'border:2px solid #0d47a1;background:#fff;color:#0d47a1;font-size:18px;font-weight:800;cursor:pointer;padding:0;line-height:1;flex:none}'
 +'#refreshbtn.busy{animation:spinbtn 1s linear infinite;opacity:.75}'
 +'@keyframes spinbtn{to{transform:rotate(360deg)}}'
 +'</style>';

const JS='<script>/*DEALS-REFRESH-v4*/\n'
 +"(function(){\n"
 +"var DB='https://lvr-data-a60c1-default-rtdb.firebaseio.com/_deals';\n"
 +"var lu=document.getElementById('lastupd');if(!lu)return;\n"
 +"if(!lu.firstChild||lu.firstChild.nodeType!==3){lu.insertBefore(document.createTextNode(''),lu.firstChild);}\n"
 +"var btn=document.createElement('button');btn.id='refreshbtn';btn.title='Refresh listings';\n"
 +"btn.setAttribute('aria-label','Refresh listings');btn.innerHTML='\\u27F3';\n"
 +"lu.appendChild(btn);\n"
 +"function setTxt(t){lu.firstChild.nodeValue=t;}\n"
 +"function fmt(ts){var d=new Date(ts);return (d.getMonth()+1)+'/'+d.getDate()+'/'+String(d.getFullYear()).slice(-2)+', '+d.toLocaleTimeString('en-US',{hour:'numeric',minute:'2-digit'});}\n"
 +"function applyRemoved(obj){if(!obj)return;\n"
 +" document.querySelectorAll('article.card').forEach(function(a){\n"
 +"  var f=a.querySelector('.cardfav');var k=f&&f.getAttribute('data-fav');\n"
 +"  if(k&&obj[k]){a.style.display='none';a.setAttribute('data-dead','1');}\n"
 +" });\n"
 +" var vis=document.querySelectorAll('article.card:not([data-dead])').length;\n"
 +" var gt=document.getElementById('grandTotal');if(gt)gt.textContent=vis;\n"
 +"}\n"
 +"var base=null;\n"
 +"function pull(cb){\n"
 +" fetch(DB+'/updated.json').then(function(r){return r.json();}).then(function(ts){\n"
 +"  if(ts){if(cb&&base&&ts>base){cb(ts);}else if(!cb){base=ts;setTxt(fmt(ts)+' ');}else{base=base||ts;}}\n"
 +" }).catch(function(){});\n"
 +" fetch(DB+'/removed.json').then(function(r){return r.json();}).then(applyRemoved).catch(function(){});\n"
 +"}\n"
 +"pull(null);\n"
 +"btn.onclick=function(){\n"
 +" if(btn.classList.contains('busy'))return;\n"
 +" btn.classList.add('busy');\n"
 +" setTxt('Refreshing\\u2026 (about 15 min) ');\n"
 +" fetch(DB+'/refresh_request.json',{method:'PUT',headers:{'Content-Type':'application/json'},body:JSON.stringify(Date.now())}).then(function(){\n"
 +"  var n=0;var iv=setInterval(function(){n++;\n"
 +"   fetch(DB+'/updated.json').then(function(r){return r.json();}).then(function(ts){\n"
 +"    if(ts&&base&&ts>base){base=ts;clearInterval(iv);btn.classList.remove('busy');\n"
 +"     setTxt(fmt(ts)+' ');\n"
 +"     fetch(DB+'/removed.json').then(function(r){return r.json();}).then(applyRemoved).catch(function(){});\n"
 +"    }else if(n>=80){clearInterval(iv);btn.classList.remove('busy');setTxt('Timed out \\u2014 try again ');}\n"
 +"   }).catch(function(){});\n"
 +"  },15000);\n"
 +" }).catch(function(){btn.classList.remove('busy');setTxt('No connection \\u2014 try again ');});\n"
 +"};\n"
 +"})();\n"
 +'</script>';

s=s.replace(/<\/body>/, CSS+'\n'+JS+'\n</body>');
// Eagle Point land tab (idempotent): remove old copies, insert after the US Coins tab
const TS='display:inline-flex;align-items:center;gap:5px;padding:8px 16px;border-radius:999px;font-size:14px;font-weight:800;text-decoration:none;cursor:pointer';
const LANDTAB='<a class="tablink" href="/land-eaglepoint" style="'+TS+';border:1.5px solid #1b5e20;color:#1b5e20">\ud83c\udf32 Eagle Point Land</a>';
s=s.replace(/\s*<a class="tablink"[^>]*>\ud83c\udf32 Eagle Point Land<\/a>/g,'');
if(/tablink" href="\/coins"/.test(s)) s=s.replace(/(<a class="tablink" href="\/coins"[^>]*>[^<]*<\/a>)/, '$1\n        '+LANDTAB);
else s=s.replace(/(<button class="chip chip-deals"[^>]*>\ud83d\udd25 Deals<\/button>)/, '$1\n        '+LANDTAB);
console.log('land tab: '+(/land-eaglepoint/.test(s)?'inserted':'ANCHOR NOT FOUND'));
if(s!==before){fs.writeFileSync('index.html.bak-v4',before);fs.writeFileSync(F,s);console.log('v4 refresh UI: applied');}
else console.log('v4 refresh UI: NO CHANGE (unexpected)');
console.log('v4 present: '+((s.match(/DEALS-REFRESH-v4/g)||[]).length)+' (expect 2)');
NODE

# neutralize the auto-updater's old patcher: from now on it only cleans up
# (strips old v1/v2 UI + Batman tab) and leaves the v3 refresh UI alone
cat > /Users/mac/patch-deals-refresh.js <<'P2EOF'
const fs=require('fs');
const F='/Users/mac/wholesale-classic-cars/index.html';
let s=fs.readFileSync(F,'utf8'); const before=s;
s=s.replace(/<style>\/\*DEALS-REFRESH-v[123]\*\/[\s\S]*?<\/style>\n?/g,'');
s=s.replace(/<script>\/\*DEALS-REFRESH-v[123]\*\/[\s\S]*?<\/script>\n?/g,'');
s=s.replace(/\s*<a class="tablink"[^>]*>\u21bb Refresh<\/a>/g,'');
s=s.replace(/\s*<a class="tablink"[^>]*>\ud83e\udd87 Batman Cards<\/a>/g,'');
s=s.replace(/(<div class="lastupd" id="lastupd">)\s*Updated\s*/,'$1');
if(s!==before){fs.writeFileSync(F,s);console.log('cleanup patch: applied');}
else console.log('cleanup patch: nothing to do');
console.log('v4 present: '+(/DEALS-REFRESH-v4/.test(s)?'yes':'NO — rerun deploy-refresh-ui.sh'));
P2EOF
echo "agent patcher updated to cleanup-only" >> "$LOG"

# Eagle Point land page — prebuilt on the server, just fetch it into the site root
curl -sL -o land-eaglepoint.html "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/fetched/land-eaglepoint.html"
echo "land-eaglepoint.html: $(wc -c < land-eaglepoint.html) bytes, $(grep -c 'class=\"card\"' land-eaglepoint.html) cards" >> "$LOG"

echo "-- deploying --" >> "$LOG"
node _tools/rest-deploy.js >> "$LOG" 2>&1
echo "LIVE v4 blocks: $(curl -s https://classiccarsforsale-co.web.app/ | grep -c 'DEALS-REFRESH-v4')" >> "$LOG"
echo "LIVE /land-eaglepoint: $(curl -sL -o /dev/null -w '%{http_code}' https://classiccarsforsale-co.web.app/land-eaglepoint)" >> "$LOG"

node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/rui.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT — tell Claude done")).catch(e=>console.log("send failed "+e.message))'
echo "==== done ===="; cat "$LOG"
