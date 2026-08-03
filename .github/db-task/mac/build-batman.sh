#!/bin/bash
# Standalone Batman Cards page — bypasses gen.js entirely.
# Reads the Batman entries from manual.json, writes a self-contained batman.html,
# turns the 🦇 chip into a link to it, then deploys. One line to run.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
cd /Users/mac/wholesale-classic-cars || { echo "no dir"; exit 1; }
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
LOG=/tmp/buildbat.txt
: > "$LOG"

node <<'NODE' >> "$LOG" 2>&1
const fs=require('fs');
const man=JSON.parse(fs.readFileSync('_tools/manual.json','utf8'));
const bats=man.filter(e=>e.type==='Batman');
console.log('batman entries: '+bats.length);
const esc=s=>String(s==null?'':s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const card=e=>{
  const img=(e.imgs&&e.imgs[0])||'';
  const price=e.price?('$'+Number(e.price).toLocaleString()):'—';
  const more=(e.imgs&&e.imgs.length>1)?('<div class="count">'+e.imgs.length+' photos</div>'):'';
  return `<a class="card" href="${esc(e.src)}" target="_blank" rel="noopener">
    <div class="ph">${img?`<img loading="lazy" src="${esc(img)}" alt="${esc(e.model)}">`:'<div class="noph">no photo</div>'}${more}</div>
    <div class="body"><div class="price">${esc(price)}</div><div class="title">${esc(e.model)}</div>
    <div class="loc">${esc(e.location||'')}</div><div class="cta">View on Craigslist →</div></div>
  </a>`;
};
const cards=bats.map(card).join('\n');
const html=`<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Batman 1966 Trading Cards — Deals</title>
<meta name="description" content="1966 Batman trading cards found on Craigslist nationwide.">
<style>
:root{--blue:#0d47a1;--line:#e3e8f0;--text:#0f1f36;--muted:#5c6b82}
*{box-sizing:border-box}body{margin:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;background:#f5f7fa;color:var(--text)}
header{background:var(--blue);color:#fff;padding:18px 20px;display:flex;align-items:center;gap:12px}
header a{color:#fff;text-decoration:none;font-weight:700;font-size:14px;opacity:.9}
header h1{font-size:20px;margin:0;font-weight:800}
.wrap{max-width:1100px;margin:0 auto;padding:20px}
.sub{color:var(--muted);font-size:14px;margin:0 0 18px}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:16px}
.card{background:#fff;border:1px solid var(--line);border-radius:14px;overflow:hidden;text-decoration:none;color:inherit;display:flex;flex-direction:column;transition:box-shadow .15s,transform .15s}
.card:hover{box-shadow:0 10px 28px rgba(13,40,80,.14);transform:translateY(-2px)}
.ph{position:relative;aspect-ratio:4/3;background:#eef2f8}
.ph img{width:100%;height:100%;object-fit:cover;display:block}
.noph{display:flex;align-items:center;justify-content:center;height:100%;color:var(--muted);font-size:14px}
.count{position:absolute;right:10px;bottom:10px;background:rgba(6,28,68,.85);color:#fff;font-size:12px;font-weight:700;padding:4px 10px;border-radius:11px}
.body{padding:14px}
.price{font-size:22px;font-weight:800;color:var(--blue)}
.title{font-weight:700;margin:4px 0;font-size:15px;line-height:1.3}
.loc{color:var(--muted);font-size:13px}
.cta{margin-top:10px;color:var(--blue);font-weight:700;font-size:13px}
.empty{color:var(--muted);padding:40px 0;text-align:center}
footer{color:var(--muted);font-size:12px;text-align:center;padding:24px}
</style></head><body>
<header><a href="/">← Deals</a><h1>🦇 Batman 1966 Trading Cards</h1></header>
<div class="wrap">
<p class="sub">1966 Batman trading cards found on Craigslist nationwide. Tap a card to open the original ad.</p>
<div class="grid">${cards||'<div class="empty">No cards in stock right now — check back soon.</div>'}</div>
</div>
<footer>Refreshed from Craigslist · classiccarsforsale-co</footer>
</body></html>`;
fs.writeFileSync('batman.html',html);
console.log('wrote batman.html ('+html.length+' bytes, '+bats.length+' cards)');

// Turn the 🦇 chip into a link to /batman.html so it opens the standalone page.
let idx=fs.readFileSync('index.html','utf8');
const before=idx;
idx=idx.replace(/<button class="chip chip-batman"[^>]*>🦇 Batman Cards<\/button>/,
  '<a class="chip chip-batman" href="/batman.html" style="text-decoration:none">🦇 Batman Cards</a>');
if(idx!==before){fs.writeFileSync('index.html.bak-batlink',before);fs.writeFileSync('index.html',idx);console.log('chip -> link: patched');}
else{console.log('chip -> link: pattern not found (may already be a link)');}
NODE

echo "-- deploying --" >> "$LOG"
node _tools/rest-deploy.js >> "$LOG" 2>&1
echo "LIVE batman.html: $(curl -s -o /dev/null -w '%{http_code}' https://classiccarsforsale-co.web.app/batman.html)" >> "$LOG"

node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/buildbat.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT — tell Claude done")).catch(e=>console.log("send failed "+e.message))'
