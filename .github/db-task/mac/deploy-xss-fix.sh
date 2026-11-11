#!/bin/bash
# Run on the Mac (one command):
#   curl -sL "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/deploy-xss-fix.sh?$(date +%s)" -o /tmp/deploy-xss-fix.sh && bash /tmp/deploy-xss-fix.sh
# SECURITY FIX (2026-11-11): the Leads, Prospect CRM, Rewards admin and Advertisers pages showed some lead/receipt fields without making them safe first,
# so a stranger could plant code in a lead that would run in YOUR signed-in page. This takes each page's CURRENT LIVE copy, makes those few spots safe
# (text-only replacements, nothing else changes), checks the page still parses, and puts it back. A page that cannot be fetched or checked is skipped.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac"
LIVE="https://lvr-data-a60c1.web.app"
DASH="/Users/mac/lv-dash-work"
CB="?cb=$(date +%s)"
LOG=/tmp/xssfix.txt; : > "$LOG"
cd "$DASH" || { echo "NO DASH DIR ($DASH) - nothing changed."; exit 1; }
rm -rf /tmp/xssfix-new && mkdir -p /tmp/xssfix-new
curl -sL -o /tmp/xssfix.json "$RAWB/xss-fix.json$CB"
[ -s /tmp/xssfix.json ] || { echo "Could not get the fix list - nothing changed."; exit 1; }
PAGES="key-leads.html kt-crm.html lvr-points-admin.html key-advertisers.html"
DOPAGES=""
for f in $PAGES; do
  CODE=$(curl -s -o "/tmp/xssfix-new/$f" -w '%{http_code}' "$LIVE/$f$CB"); SZ=$(wc -c < "/tmp/xssfix-new/$f")
  if [ "$CODE" = "200" ] && [ "$SZ" -gt 4000 ] && grep -q '</head>' "/tmp/xssfix-new/$f"; then DOPAGES="$DOPAGES $f"; else echo "skip $f (HTTP $CODE)" >> "$LOG"; fi
done
[ -z "$DOPAGES" ] && { echo "No page could be fetched - nothing changed."; exit 1; }
export DOPAGES
node <<'NODE' >> "$LOG" 2>&1
const fs = require('fs'), cp = require('child_process');
const pairs = JSON.parse(fs.readFileSync('/tmp/xssfix.json', 'utf8'));
let bad = 0;
for (const f of process.env.DOPAGES.trim().split(/\s+/)) {
  const p = '/tmp/xssfix-new/' + f; let s = fs.readFileSync(p, 'utf8'); let done = 0, already = 0, missing = 0;
  for (const [o, n] of pairs[f] || []) {
    if (s.includes(o)) { s = s.split(o).join(n); done++; } else if (s.includes(n)) already++; else { missing++; console.log(f + ': a spot was not found (page differs): ' + o.slice(0, 60)); }
  }
  const blocks = [...s.matchAll(/<script>([\s\S]*?)<\/script>/g)];
  blocks.forEach((m, i) => { fs.writeFileSync('/tmp/_xf_block.js', m[1]); const r = cp.spawnSync('node', ['--check', '/tmp/_xf_block.js'], { encoding: 'utf8' }); if (r.status) { console.log(f + ' script block ' + i + ' FAILED the syntax check'); bad++; } });
  fs.writeFileSync(p, s); console.log(f + ': ' + done + ' made safe, ' + already + ' already safe, ' + missing + ' not found, ' + blocks.length + ' script blocks parse');
}
process.exit(bad ? 2 : 0);
NODE
if [ "$?" != "0" ]; then echo "A page failed its checks - NOTHING was uploaded."; cat "$LOG"; exit 1; fi
for f in $DOPAGES; do cp "$DASH/$f" "$DASH/$f.bak-xssfix" 2>/dev/null; cp "/tmp/xssfix-new/$f" "$DASH/$f"; done
curl -sL -o deploy-overlay.js "$RAWB/deploy-overlay.js$CB"
export OVERLAY_FILES="$(echo $DOPAGES)"
echo "-- deploying --" >> "$LOG"
node deploy-overlay.js >> "$LOG" 2>&1
sleep 4
ALLOK=1
for f in $DOPAGES; do
  CODE=$(curl -s -o "/tmp/live-xf-$f" -w '%{http_code}' "$LIVE/$f?cb=$(date +%s)")
  if [ "$CODE" = "200" ] && [ "$(wc -c < /tmp/live-xf-$f)" -gt 4000 ]; then echo "OK   $f is live (fixed)" | tee -a "$LOG"; else echo "FAIL $f (HTTP $CODE) - not confirmed" | tee -a "$LOG"; ALLOK=0; fi
done
cat "$LOG" | grep -E "made safe|not found|skip"
if [ "$ALLOK" = "1" ]; then echo "SECURITY FIX LIVE: all done."; else echo "NOT ALL CONFIRMED - see above (log: $LOG)."; exit 1; fi
