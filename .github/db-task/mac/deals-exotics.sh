#!/bin/bash
# Run on the Mac (ONE command): finds Lamborghinis and Ferraris for sale by owner within 100 miles of Las Vegas on Craigslist,
# adds them to the Deals site as two pages (/lamborghini and /ferrari) with tabs on the Deals home page, and puts it live.
#   curl -sL "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/deals-exotics.sh?$(date +%s)" -o /tmp/deals-exotics.sh && bash /tmp/deals-exotics.sh
# Add dealers too:  EXOTIC_PATH=cta bash /tmp/deals-exotics.sh        Run it again any time: it adds new cars and removes ads that were taken down.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac"
cd /Users/mac/wholesale-classic-cars || { echo "Could not find the Deals folder (/Users/mac/wholesale-classic-cars) - nothing changed."; exit 1; }
[ -f _tools/manual.json ] || { echo "No _tools/manual.json here - nothing changed."; exit 1; }
LOG=/tmp/exotics.txt; : > "$LOG"
cp _tools/manual.json _tools/manual.json.bak-exotics
curl -sL -o _tools/watch-exotics.js "$RAWB/watch-exotics.js?cb=$(date +%s)"
if ! node --check _tools/watch-exotics.js 2>/dev/null; then echo "The harvester did not download correctly - nothing changed."; exit 1; fi
echo "Searching Craigslist (this takes a few minutes: it is polite and slow on purpose)..."
node _tools/watch-exotics.js 2>&1 | tee -a "$LOG" | grep -E "IMPORTED|ADDED|candidates|ERR"
node <<'NODE' 2>&1 | tee -a "$LOG"
const fs=require('fs');
const man=JSON.parse(fs.readFileSync('_tools/manual.json','utf8'));
const esc=s=>String(s==null?'':s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const CSS=`:root{--blue:#0d47a1;--line:#e3e8f0;--text:#0f1f36;--muted:#5c6b82}*{box-sizing:border-box}body{margin:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;background:#f5f7fa;color:var(--text)}
header{background:var(--blue);color:#fff;padding:18px 20px;display:flex;align-items:center;gap:12px}header a{color:#fff;text-decoration:none;font-weight:700;font-size:14px;opacity:.9}header h1{font-size:20px;margin:0;font-weight:800}
.wrap{max-width:1100px;margin:0 auto;padding:20px}.sub{color:var(--muted);font-size:14px;margin:0 0 18px}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));gap:16px}
.card{background:#fff;border:1px solid var(--line);border-radius:14px;overflow:hidden;text-decoration:none;color:inherit;display:flex;flex-direction:column;transition:box-shadow .15s,transform .15s}.card:hover{box-shadow:0 10px 28px rgba(13,40,80,.14);transform:translateY(-2px)}
.ph{position:relative;aspect-ratio:4/3;background:#eef2f8}.ph img{width:100%;height:100%;object-fit:cover;display:block}.noph{display:flex;align-items:center;justify-content:center;height:100%;color:var(--muted);font-size:14px}
.count{position:absolute;right:10px;bottom:10px;background:rgba(6,28,68,.85);color:#fff;font-size:12px;font-weight:700;padding:4px 10px;border-radius:11px}.body{padding:14px}.price{font-size:22px;font-weight:800;color:var(--blue)}
.title{font-weight:700;margin:4px 0;font-size:15px;line-height:1.3}.loc{color:var(--muted);font-size:13px}.cta{margin-top:10px;color:var(--blue);font-weight:700;font-size:13px}.empty{color:var(--muted);padding:40px 0;text-align:center}footer{color:var(--muted);font-size:12px;text-align:center;padding:24px}`;
function page(type,emoji,file){
  const rows=man.filter(e=>e.type===type).sort((a,b)=>String(b.addedTs||b.added||'').localeCompare(String(a.addedTs||a.added||'')));
  const card=e=>{const img=(e.imgs&&e.imgs[0])||'';const price=e.price?('$'+Number(e.price).toLocaleString()):'-';const more=(e.imgs&&e.imgs.length>1)?('<div class="count">'+e.imgs.length+' photos</div>'):'';
    return `<a class="card" href="${esc(e.src)}" target="_blank" rel="noopener"><div class="ph">${img?`<img loading="lazy" src="${esc(img)}" alt="${esc(e.model)}">`:'<div class="noph">no photo</div>'}${more}</div><div class="body"><div class="price">${esc(price)}</div><div class="title">${esc(e.model)}</div><div class="loc">${esc(e.location||'')}</div><div class="cta">View on Craigslist &rarr;</div></div></a>`;};
  const html=`<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${type} for sale near Las Vegas - Deals</title><style>${CSS}</style></head><body><header><a href="/">&larr; Deals</a><h1>${emoji} ${type}s for sale near Las Vegas</h1></header><div class="wrap"><p class="sub">${rows.length} on Craigslist within 100 miles of Las Vegas. Tap a car to open the original ad.</p><div class="grid">${rows.map(card).join('\n')||'<div class="empty">None right now - check back soon.</div>'}</div></div><footer>Refreshed from Craigslist &middot; classiccarsforsale-co</footer></body></html>`;
  fs.writeFileSync(file,html);console.log(file+': '+rows.length+' cars');return rows.length;}
page('Lamborghini','🏎️','lamborghini.html');page('Ferrari','🐎','ferrari.html');
// tabs on the Deals home page (plain links, class tablink, so the filter script leaves them alone)
let idx=fs.readFileSync('index.html','utf8');const before=idx;
const S='display:inline-flex;align-items:center;gap:5px;padding:8px 16px;border-radius:999px;font-size:14px;font-weight:800;text-decoration:none;cursor:pointer';
const LAM='<a class="tablink tab-lambo" href="/lamborghini" style="'+S+';border:1.5px solid #1b7a3a;color:#1b7a3a">🏎️ Lamborghini</a>';
const FER='<a class="tablink tab-ferrari" href="/ferrari" style="'+S+';border:1.5px solid #b3202a;color:#b3202a">🐎 Ferrari</a>';
idx=idx.replace(/<a class="tablink tab-(?:lambo|ferrari)"[^>]*>[^<]*<\/a>\s*/g,'');
const anchor=/(<a class="tablink"[^>]*href="\/batman"[^>]*>[^<]*<\/a>|<button class="chip chip-deals"[^>]*>[^<]*<\/button>)/;
idx=idx.replace(anchor,'$1\n        '+LAM+'\n        '+FER);
if(idx!==before){fs.writeFileSync('index.html.bak-exotics',before);fs.writeFileSync('index.html',idx);console.log('tabs added to the Deals home page');}else{console.log('tabs: no change (already there, or the spot was not found)');}
NODE
echo "-- putting it live --" | tee -a "$LOG"
node _tools/rest-deploy.js >> "$LOG" 2>&1
sleep 3
for p in lamborghini ferrari; do echo "LIVE /$p: HTTP $(curl -sL -o /dev/null -w '%{http_code}' https://classiccarsforsale-co.web.app/$p)"; done
echo "Tabs on the Deals home page: $(curl -s https://classiccarsforsale-co.web.app/ | grep -oE 'tab-lambo|tab-ferrari' | sort -u | tr '\n' ' ')"
echo "Done. Full log: $LOG   (your list was backed up as _tools/manual.json.bak-exotics)"
