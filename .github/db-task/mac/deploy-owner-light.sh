#!/bin/bash
# Run on the Mac (one command):
#   curl -sL "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/deploy-owner-light.sh?$(date +%s)" -o /tmp/deploy-owner-light.sh && bash /tmp/deploy-owner-light.sh
# Gives your private owner pages a LIGHT background and the blue key (Shane, 2026-11-10). It takes each page's CURRENT LIVE copy, adds ONE colour-only style block
# and recolours the key mark, and puts it back. No script, text or data is changed, and nothing else that is waiting in the repo goes live with it.
# Pages: Prospect CRM, Leads, Advertisers, Key Room, Rewards (Points) admin, Coupons admin, Invoice. A page that cannot be fetched is skipped. Nothing is uploaded if a check fails.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac"
LIVE="https://lvr-data-a60c1.web.app"
DASH="/Users/mac/lv-dash-work"
CB="?cb=$(date +%s)"
LOG=/tmp/ownerlight.txt
: > "$LOG"
cd "$DASH" || { echo "NO DASH DIR ($DASH) - nothing changed."; exit 1; }
PAGES="kt-crm.html key-leads.html key-advertisers.html key-room.html lvr-points-admin.html lvr-coupons-admin.html lvr-invoice.html"
rm -rf /tmp/ownerlight-new && mkdir -p /tmp/ownerlight-new
curl -sL -o /tmp/ownerlight-snippet.html "$RAWB/owner-light.snippet.html$CB"
echo "style block: $(wc -c < /tmp/ownerlight-snippet.html) bytes" >> "$LOG"
if ! grep -q 'ktowner-light' /tmp/ownerlight-snippet.html; then echo "Could not get the style block - nothing changed."; exit 1; fi
DOPAGES=""
for f in $PAGES; do
  CODE=$(curl -s -o "/tmp/ownerlight-new/$f" -w '%{http_code}' "$LIVE/$f$CB")
  SZ=$(wc -c < "/tmp/ownerlight-new/$f")
  if [ "$CODE" = "200" ] && [ "$SZ" -gt 4000 ] && grep -q '</head>' "/tmp/ownerlight-new/$f"; then DOPAGES="$DOPAGES $f"; echo "got live $f ($SZ bytes)" >> "$LOG"; else echo "skip $f (HTTP $CODE, $SZ bytes)" | tee -a "$LOG"; rm -f "/tmp/ownerlight-new/$f"; fi
done
[ -z "$DOPAGES" ] && { echo "No page could be fetched - nothing changed."; exit 1; }
export DOPAGES
node <<'NODE' >> "$LOG" 2>&1
const fs = require('fs'), cp = require('child_process');
const snippet = fs.readFileSync('/tmp/ownerlight-snippet.html', 'utf8').trim();
const MAP = { fffdf0:'bfe6ff', ffe45c:'4fb9ff', e49a00:'1a8be0', b87300:'0a6fb8', ffd23a:'2aa3f2', fff2a0:'8fd3ff', d48f00:'0a7fd0', f7d26a:'4cb9ff', e3a617:'1a8be0', b97a00:'0a6fb8', '8d5a00':'0a4f8f', d9a111:'2a9ae8', f0c64a:'66c3ff', a86f00:'0a5fa8' };
let bad = 0;
for (const f of process.env.DOPAGES.trim().split(/\s+/)) {
  const p = '/tmp/ownerlight-new/' + f; let s = fs.readFileSync(p, 'utf8');
  s = s.replace(/<style id="ktowner-light">[\s\S]*?<\/style>/g, '');
  s = s.replace(/<linearGradient id="(k[a-z]*\d*)"[^>]*>[\s\S]*?<\/linearGradient>/g, m => m.replace(/(stop-color=")#([0-9a-fA-F]{6})(")/g, (a, b, c, d) => b + '#' + (MAP[c.toLowerCase()] || c) + d));
  s = s.replace('</head>', snippet + '</head>');
  const blocks = [...s.matchAll(/<script>([\s\S]*?)<\/script>/g)];
  blocks.forEach((m, i) => { fs.writeFileSync('/tmp/_ol_block.js', m[1]); const r = cp.spawnSync('node', ['--check', '/tmp/_ol_block.js'], { encoding: 'utf8' }); if (r.status) { console.log(f + ' script ' + i + ' SYNTAX CHECK FAILED'); bad++; } });
  fs.writeFileSync(p, s); console.log(f + ': light style added, key recoloured, ' + blocks.length + ' script blocks parse');
}
process.exit(bad ? 2 : 0);
NODE
if [ "$?" != "0" ]; then echo "A page failed its checks - NOTHING was uploaded."; cat "$LOG"; exit 1; fi
for f in $DOPAGES; do cp "$DASH/$f" "$DASH/$f.bak-ownerlight" 2>/dev/null; cp "/tmp/ownerlight-new/$f" "$DASH/$f"; done
curl -sL -o deploy-overlay.js "$RAWB/deploy-overlay.js$CB"
export OVERLAY_FILES="$(echo $DOPAGES)"
echo "-- deploying --" >> "$LOG"
node deploy-overlay.js >> "$LOG" 2>&1
sleep 4
ALLOK=1
for f in $DOPAGES; do
  CODE=$(curl -s -o "/tmp/live-ol-$f" -w '%{http_code}' "$LIVE/$f?cb=$(date +%s)")
  HAS=$(grep -c 'ktowner-light' "/tmp/live-ol-$f" 2>/dev/null)
  if [ "$CODE" = "200" ] && [ "${HAS:-0}" -ge 1 ]; then echo "OK   $f is live with the light look" | tee -a "$LOG"; else echo "FAIL $f (HTTP $CODE) - not confirmed" | tee -a "$LOG"; ALLOK=0; fi
done
if [ "$ALLOK" = "1" ]; then echo "OWNER PAGES LIGHT: all done. Refresh each page once (pull down or Cmd+Shift+R)."; else echo "NOT ALL CONFIRMED - see above (log: $LOG)."; exit 1; fi
