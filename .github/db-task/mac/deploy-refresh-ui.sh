#!/bin/bash
# One-shot (run on the Mac): Deals refresh UI v7 + photo-fixed Coins & Eagle Point Land pages.
#   - the round refresh button is now BAKED INTO THE HTML (a real element next to the date,
#     not created by script) — it cannot fail to appear
#   - date/time far right, M/D/YY, slightly bigger; button immediately to the right of the time
#   - coins + land pages now use OUR hosted photos (Craigslist blocks browsers from hotlinking,
#     which is why every tab showed gray boxes)
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/fetched"
LOG=/tmp/rui.txt
: > "$LOG"
cd /Users/mac/wholesale-classic-cars || { echo "no deals dir"; exit 1; }

node <<'NODE' >> "$LOG" 2>&1
const fs=require('fs');
const F='index.html';
let s=fs.readFileSync(F,'utf8'); const before=s;

// strip every older refresh UI (all versioned blocks, old tabs, any previous baked button)
s=s.replace(/<style>\/\*DEALS-REFRESH-v[1234567]\*\/[\s\S]*?<\/style>\n?/g,'');
s=s.replace(/<script>\/\*DEALS-REFRESH-v[1234567]\*\/[\s\S]*?<\/script>\n?/g,'');
s=s.replace(/\s*<button id="refreshbtn"[\s\S]*?<\/button>/g,'');
s=s.replace(/\s*<a class="tablink"[^>]*>\u21bb Refresh<\/a>/g,'');
s=s.replace(/\s*<a class="tablink"[^>]*>\ud83e\udd87 Batman Cards<\/a>/g,'');

// baked date (M/D/YY h:mm) + the button as REAL HTML right after the date div
const la=new Date(new Date().toLocaleString('en-US',{timeZone:'America/Los_Angeles'}));
const stamp=(la.getMonth()+1)+'/'+la.getDate()+'/'+String(la.getFullYear()).slice(-2)+', '+la.toLocaleTimeString('en-US',{hour:'numeric',minute:'2-digit'});
s=s.replace(/(<div class="lastupd" id="lastupd">)[^<]*/,'$1'+stamp);
const BTN='<button id="refreshbtn" title="Refresh listings" aria-label="Refresh listings"><span class="rg">\u27F3</span></button>';
s=s.replace(/(<div class="lastupd" id="lastupd">[^<]*<\/div>)/,'$1'+BTN);

const CSS='<style>/*DEALS-REFRESH-v7*/'
 +'.hd{display:flex!important;align-items:center!important;justify-content:space-between!important;gap:10px;flex-wrap:wrap}'
 +'#lastupd{margin-left:auto!important;font-size:clamp(15px,3.5vw,21px)!important;font-weight:800!important;line-height:1.25!important;color:#0d47a1!important}'
 +'#refreshbtn{width:38px;height:38px;border-radius:50%;flex:none;'
 +'background:linear-gradient(135deg,#1565d8,#0d47a1);color:#fff;border:none;font-size:19px;font-weight:800;'
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

const JS='<script>/*DEALS-REFRESH-v7*/\n'
 +"(function(){\n"
 +"var DB='https://lvr-data-a60c1-default-rtdb.firebaseio.com/_deals';\n"
 +"var btn=document.getElementById('refreshbtn');\n"
 +"if(!btn){btn=document.createElement('button');btn.id='refreshbtn';btn.innerHTML='<span class=\\\"rg\\\">\\u27F3</span>';btn.style.cssText='position:fixed;top:14px;right:14px;z-index:9999';document.body.appendChild(btn);}\n"
 +"var toast=document.createElement('div');toast.id='rtoast';document.body.appendChild(toast);\n"
 +"var tt=null;function say(msg,ms){toast.textContent=msg;toast.classList.add('show');clearTimeout(tt);if(ms)tt=setTimeout(function(){toast.classList.remove('show');},ms);}\n"
 +"function fmt(ts){var d=new Date(ts);return (d.getMonth()+1)+'/'+d.getDate()+'/'+String(d.getFullYear()).slice(-2)+', '+d.toLocaleTimeString('en-US',{hour:'numeric',minute:'2-digit'});}\n"
 +"function setDate(ts){var lu=document.getElementById('lastupd');if(!lu)return;if(!lu.firstChild||lu.firstChild.nodeType!==3){lu.insertBefore(document.createTextNode(''),lu.firstChild);}lu.firstChild.nodeValue=fmt(ts);}\n"
 +"function applyRemoved(obj){if(!obj)return;\n"
 +" document.querySelectorAll('article.card').forEach(function(a){\n"
 +"  var f=a.querySelector('.cardfav');var k=f&&f.getAttribute('data-fav');\n"
 +"  if(k&&obj[k]){a.style.display='none';a.setAttribute('data-dead','1');}\n"
 +" });\n"
 +" var vis=document.querySelectorAll('article.card:not([data-dead])').length;\n"
 +" var gt=document.getElementById('grandTotal');if(gt)gt.textContent=vis;\n"
 +"}\n"
 +"var base=null;\n"
 +"fetch(DB+'/updated.json').then(function(r){return r.json();}).then(function(ts){if(ts){base=ts;setDate(ts);}}).catch(function(){});\n"
 +"fetch(DB+'/removed.json').then(function(r){return r.json();}).then(applyRemoved).catch(function(){});\n"
 +"btn.onclick=function(){\n"
 +" if(btn.classList.contains('busy'))return;\n"
 +" btn.classList.add('busy');btn.classList.remove('done');\n"
 +" say('Refreshing\\u2026 checking every listing. Takes up to ~15 min \\u2014 you can leave this page.');\n"
 +" fetch(DB+'/refresh_request.json',{method:'PUT',headers:{'Content-Type':'application/json'},body:JSON.stringify(Date.now())}).then(function(){\n"
 +"  var n=0;var iv=setInterval(function(){n++;\n"
 +"   fetch(DB+'/updated.json').then(function(r){return r.json();}).then(function(ts){\n"
 +"    if(ts&&base&&ts>base){base=ts;clearInterval(iv);\n"
 +"     fetch(DB+'/removed.json').then(function(r){return r.json();}).then(function(obj){\n"
 +"      applyRemoved(obj);setDate(ts);\n"
 +"      btn.classList.remove('busy');btn.classList.add('done');btn.innerHTML='\\u2713';\n"
 +"      say('Up to date \\u2014 '+fmt(ts),6000);\n"
 +"      setTimeout(function(){btn.classList.remove('done');btn.innerHTML='<span class=\\\"rg\\\">\\u27F3</span>';},4000);\n"
 +"     }).catch(function(){});\n"
 +"    }else if(ts&&!base){base=ts;}\n"
 +"    else if(n>=80){clearInterval(iv);btn.classList.remove('busy');say('Timed out \\u2014 tap to try again',6000);}\n"
 +"   }).catch(function(){});\n"
 +"  },15000);\n"
 +" }).catch(function(){btn.classList.remove('busy');say('No connection \\u2014 tap to try again',5000);});\n"
 +"};\n"
 +"})();\n"
 +'</script>';

s=s.replace(/<\/body>/, CSS+'\n'+JS+'\n</body>');
// Eagle Point land tab (idempotent)
const TS='display:inline-flex;align-items:center;gap:5px;padding:8px 16px;border-radius:999px;font-size:14px;font-weight:800;text-decoration:none;cursor:pointer';
const LANDTAB='<a class="tablink" href="/land-eaglepoint" style="'+TS+';border:1.5px solid #1b5e20;color:#1b5e20">\ud83c\udf32 Eagle Point Land</a>';
s=s.replace(/\s*<a class="tablink"[^>]*>\ud83c\udf32 Eagle Point Land<\/a>/g,'');
if(/tablink" href="\/coins"/.test(s)) s=s.replace(/(<a class="tablink" href="\/coins"[^>]*>[^<]*<\/a>)/, '$1\n        '+LANDTAB);
else s=s.replace(/(<button class="chip chip-deals"[^>]*>\ud83d\udd25 Deals<\/button>)/, '$1\n        '+LANDTAB);
console.log('land tab: '+(/land-eaglepoint/.test(s)?'inserted':'ANCHOR NOT FOUND'));
console.log('baked button: '+(/<button id="refreshbtn"/.test(s)?'yes':'NO'));
if(s!==before){fs.writeFileSync('index.html.bak-v7',before);fs.writeFileSync(F,s);console.log('v7 refresh UI: applied');}
else console.log('v7 refresh UI: NO CHANGE (unexpected)');
console.log('v7 present: '+((s.match(/DEALS-REFRESH-v7/g)||[]).length)+' (expect 2)');
NODE

# the overnight auto-updater's patcher: cleanup-only — strips old UI, keeps v7 + baked button
cat > /Users/mac/patch-deals-refresh.js <<'P2EOF'
const fs=require('fs');
const F='/Users/mac/wholesale-classic-cars/index.html';
let s=fs.readFileSync(F,'utf8'); const before=s;
s=s.replace(/<style>\/\*DEALS-REFRESH-v[123456]\*\/[\s\S]*?<\/style>\n?/g,'');
s=s.replace(/<script>\/\*DEALS-REFRESH-v[123456]\*\/[\s\S]*?<\/script>\n?/g,'');
s=s.replace(/\s*<a class="tablink"[^>]*>\u21bb Refresh<\/a>/g,'');
s=s.replace(/\s*<a class="tablink"[^>]*>\ud83e\udd87 Batman Cards<\/a>/g,'');
s=s.replace(/(<div class="lastupd" id="lastupd">)\s*Updated\s*/,'$1');
if(s!==before){fs.writeFileSync(F,s);console.log('cleanup patch: applied');}
else console.log('cleanup patch: nothing to do');
console.log('v7 present: '+(/DEALS-REFRESH-v7/.test(s)?'yes':'NO — rerun deploy-refresh-ui.sh'));
P2EOF
echo "agent patcher updated (cleanup-only, keeps v7)" >> "$LOG"

# photo-fixed pages — prebuilt on the server with self-hosted images, just fetch them
curl -sL -o coins.html "$RAWB/coins.html"
echo "coins.html: $(wc -c < coins.html) bytes, $(grep -c 'raw.githubusercontent' coins.html) hosted imgs" >> "$LOG"
curl -sL -o land-eaglepoint.html "$RAWB/land-eaglepoint.html"
echo "land-eaglepoint.html: $(wc -c < land-eaglepoint.html) bytes, $(grep -c 'raw.githubusercontent' land-eaglepoint.html) hosted imgs" >> "$LOG"

echo "-- deploying --" >> "$LOG"
node _tools/rest-deploy.js >> "$LOG" 2>&1
echo "LIVE v7 blocks: $(curl -s https://classiccarsforsale-co.web.app/ | grep -c 'DEALS-REFRESH-v7')" >> "$LOG"
echo "LIVE baked button: $(curl -s https://classiccarsforsale-co.web.app/ | grep -c '<button id=\"refreshbtn\"')" >> "$LOG"
echo "LIVE /coins hosted imgs: $(curl -sL https://classiccarsforsale-co.web.app/coins | grep -c 'raw.githubusercontent')" >> "$LOG"
echo "LIVE /land-eaglepoint hosted imgs: $(curl -sL https://classiccarsforsale-co.web.app/land-eaglepoint | grep -c 'raw.githubusercontent')" >> "$LOG"

node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/rui.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT — tell Claude done")).catch(e=>console.log("send failed "+e.message))'
echo "==== done ===="; cat "$LOG"
