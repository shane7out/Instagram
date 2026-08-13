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

// strip every older refresh UI (v1 corner button, v2 block, old ↻ tab, prior v3)
s=s.replace(/<style>\/\*DEALS-REFRESH-v[123]\*\/[\s\S]*?<\/style>\n?/g,'');
s=s.replace(/<script>\/\*DEALS-REFRESH-v[123]\*\/[\s\S]*?<\/script>\n?/g,'');
s=s.replace(/\s*<a class="tablink"[^>]*>\u21bb Refresh<\/a>/g,'');
// baked date: drop the word "Updated"
s=s.replace(/(<div class="lastupd" id="lastupd">)\s*Updated\s*/,'$1');

const CSS='<style>/*DEALS-REFRESH-v3*/'
 +'#lastupd{font-size:clamp(17px,4vw,24px)!important;font-weight:800!important;line-height:1.25!important;color:#0d47a1!important;display:flex;align-items:center;gap:8px}'
 +'#refreshbtn{display:inline-flex;align-items:center;justify-content:center;width:34px;height:34px;border-radius:50%;'
 +'border:2px solid #0d47a1;background:#fff;color:#0d47a1;font-size:18px;font-weight:800;cursor:pointer;padding:0;line-height:1;flex:none}'
 +'#refreshbtn.busy{animation:spinbtn 1s linear infinite;opacity:.75}'
 +'@keyframes spinbtn{to{transform:rotate(360deg)}}'
 +'</style>';

const JS='<script>/*DEALS-REFRESH-v3*/\n'
 +"(function(){\n"
 +"var DB='https://lvr-data-a60c1-default-rtdb.firebaseio.com/_deals';\n"
 +"var lu=document.getElementById('lastupd');if(!lu)return;\n"
 +"if(!lu.firstChild||lu.firstChild.nodeType!==3){lu.insertBefore(document.createTextNode(''),lu.firstChild);}\n"
 +"var btn=document.createElement('button');btn.id='refreshbtn';btn.title='Refresh listings';\n"
 +"btn.setAttribute('aria-label','Refresh listings');btn.innerHTML='\\u27F3';\n"
 +"lu.appendChild(btn);\n"
 +"function setTxt(t){lu.firstChild.nodeValue=t;}\n"
 +"function fmt(ts){var d=new Date(ts);return d.toLocaleDateString('en-US',{month:'short',day:'numeric'})+', '+d.toLocaleTimeString('en-US',{hour:'numeric',minute:'2-digit'});}\n"
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
if(s!==before){fs.writeFileSync('index.html.bak-v3',before);fs.writeFileSync(F,s);console.log('v3 refresh UI: applied');}
else console.log('v3 refresh UI: NO CHANGE (unexpected)');
console.log('v3 present: '+((s.match(/DEALS-REFRESH-v3/g)||[]).length)+' (expect 2)');
NODE

echo "-- deploying --" >> "$LOG"
node _tools/rest-deploy.js >> "$LOG" 2>&1
echo "LIVE v3 blocks: $(curl -s https://classiccarsforsale-co.web.app/ | grep -c 'DEALS-REFRESH-v3')" >> "$LOG"

node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/rui.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT — tell Claude done")).catch(e=>console.log("send failed "+e.message))'
echo "==== done ===="; cat "$LOG"
