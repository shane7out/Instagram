#!/bin/bash
# Run on the Mac (one command):
#   curl -sL "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/deploy-rewards-admin.sh?$(date +%s)" -o /tmp/deploy-rewards-admin.sh && bash /tmp/deploy-rewards-admin.sh
# MEMBER DATA PROTECTION, step 4 (2026-11-11): teaches the Rewards admin page (lvr-points-admin) to read each member's phone, email, birthday and link token from EITHER the old place
# or the new hidden place. Nothing visible changes today (the old place still has them); this must be live BEFORE the members are moved. Takes the page's CURRENT LIVE copy,
# applies small text replacements (Rewards admin, plus the VIP sign-up page lvr-rewards.html so new sign-ups also use the hidden spot), checks the page still parses, puts it back. Safe to run twice. Nothing in the database is touched.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac"
LIVE="https://lvr-data-a60c1.web.app"
DASH="/Users/mac/lv-dash-work"
CB="?cb=$(date +%s)"
LOG=/tmp/rwadm.txt; : > "$LOG"
cd "$DASH" || { echo "NO DASH DIR ($DASH) - nothing changed."; exit 1; }
rm -rf /tmp/rwadm-new && mkdir -p /tmp/rwadm-new
curl -sL -o /tmp/rwadm.json "$RAWB/member-data-step4.json$CB"
[ -s /tmp/rwadm.json ] || { echo "Could not get the change list - nothing changed."; exit 1; }
PAGES="lvr-points-admin.html lvr-rewards.html"
DOPAGES=""
for f in $PAGES; do
  CODE=$(curl -s -o "/tmp/rwadm-new/$f" -w '%{http_code}' "$LIVE/$f$CB"); SZ=$(wc -c < "/tmp/rwadm-new/$f")
  if [ "$CODE" = "200" ] && [ "$SZ" -gt 4000 ] && grep -q '</head>' "/tmp/rwadm-new/$f"; then DOPAGES="$DOPAGES $f"; else echo "skip $f (HTTP $CODE)" >> "$LOG"; fi
done
[ -z "$DOPAGES" ] && { echo "No page could be fetched - nothing changed."; exit 1; }
export DOPAGES
node <<'NODE' >> "$LOG" 2>&1
const fs = require('fs'), cp = require('child_process');
const pairs = JSON.parse(fs.readFileSync('/tmp/rwadm.json', 'utf8'));
let bad = 0;
for (const f of process.env.DOPAGES.trim().split(/\s+/)) {
  const p = '/tmp/rwadm-new/' + f; let s = fs.readFileSync(p, 'utf8'); let done = 0, already = 0, missing = 0;
  for (const [o, n] of pairs[f] || []) {
    if (s.includes(n)) already++; else if (s.includes(o)) { s = s.split(o).join(n); done++; } else { missing++; console.log(f + ': a spot was not found (page differs): ' + o.slice(0, 60)); }
  }
  const blocks = [...s.matchAll(/<script>([\s\S]*?)<\/script>/g)];
  blocks.forEach((m, i) => { fs.writeFileSync('/tmp/_rw_block.js', m[1]); const r = cp.spawnSync('node', ['--check', '/tmp/_rw_block.js'], { encoding: 'utf8' }); if (r.status) { console.log(f + ' script block ' + i + ' FAILED the syntax check'); bad++; } });
  if (missing) { console.log(f + ': a replacement was not found, page left UNCHANGED (all-or-nothing)'); bad++; continue; }
  fs.writeFileSync(p, s); console.log(f + ': ' + done + ' changed, ' + already + ' already safe, ' + missing + ' not found, ' + blocks.length + ' script blocks parse');
}
process.exit(bad ? 2 : 0);
NODE
if [ "$?" != "0" ]; then echo "A page failed its checks - NOTHING was uploaded."; cat "$LOG"; exit 1; fi
for f in $DOPAGES; do cp "$DASH/$f" "$DASH/$f.bak-rwadm" 2>/dev/null; cp "/tmp/rwadm-new/$f" "$DASH/$f"; done
curl -sL -o deploy-overlay.js "$RAWB/deploy-overlay.js$CB"
export OVERLAY_FILES="$(echo $DOPAGES)"
echo "-- deploying --" >> "$LOG"
node deploy-overlay.js >> "$LOG" 2>&1
sleep 4
ALLOK=1
for f in $DOPAGES; do
  CODE=$(curl -s -o "/tmp/live-rw-$f" -w '%{http_code}' "$LIVE/$f?cb=$(date +%s)")
  if [ "$CODE" = "200" ] && [ "$(wc -c < /tmp/live-rw-$f)" -gt 4000 ]; then echo "OK   $f is live (updated)" | tee -a "$LOG"; else echo "FAIL $f (HTTP $CODE) - not confirmed" | tee -a "$LOG"; ALLOK=0; fi
done
cat "$LOG" | grep -E "changed|not found|skip"
if [ "$ALLOK" = "1" ]; then echo "REWARDS ADMIN UPDATE LIVE: all done."; else echo "NOT ALL CONFIRMED - see above (log: $LOG)."; exit 1; fi
