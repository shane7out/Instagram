#!/bin/bash
# Run on the Mac (one command):
#   curl -sL "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/deploy-restaurant-rewards-name.sh?$(date +%s)" -o /tmp/deploy-restaurant-rewards-name.sh && bash /tmp/deploy-restaurant-rewards-name.sh
# RENAME on the LVR dashboard hosting: the words "LVR Rewards" / "LVR Rewards Program" / "LVR Points" become "Restaurant Rewards" on the member sign-up page (lvr-rewards.html)
# and the Rewards admin page (lvr-points-admin.html). Only visible words change. "Las Vegas Restaurants (LVR)" as the company name, page addresses, database names and every PIN, rule and member record stay exactly as they are.
# Takes each page's CURRENT LIVE copy, checks every script still parses, and if anything fails uploads nothing. Safe to run twice. Keeps a .bak-rrname copy of each page.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac"
LIVE="https://lvr-data-a60c1.web.app"
DASH="/Users/mac/lv-dash-work"
CB="?cb=$(date +%s)"
LOG=/tmp/rrname.txt; : > "$LOG"
cd "$DASH" || { echo "NO DASH DIR ($DASH) - nothing changed."; exit 1; }
rm -rf /tmp/rrname-new && mkdir -p /tmp/rrname-new
PAGES="lvr-rewards.html lvr-points-admin.html"
DOPAGES=""
for f in $PAGES; do
  CODE=$(curl -s -o "/tmp/rrname-new/$f" -w '%{http_code}' "$LIVE/$f$CB"); SZ=$(wc -c < "/tmp/rrname-new/$f")
  if [ "$CODE" = "200" ] && [ "$SZ" -gt 4000 ] && grep -q '</head>' "/tmp/rrname-new/$f"; then DOPAGES="$DOPAGES $f"; else echo "skip $f (HTTP $CODE)" >> "$LOG"; fi
done
[ -z "$DOPAGES" ] && { echo "No page could be fetched - nothing changed."; exit 1; }
export DOPAGES
node <<'NODE' >> "$LOG" 2>&1
const fs = require('fs'), cp = require('child_process');
let bad = 0;
for (const f of process.env.DOPAGES.trim().split(/\s+/)) {
  const p = '/tmp/rrname-new/' + f; let s = fs.readFileSync(p, 'utf8'); const before = (s.match(/LVR (Rewards|Points)/gi) || []).length;
  s = s.split('LVR Rewards Program').join('Restaurant Rewards Program').split('LVR REWARDS').join('RESTAURANT REWARDS')
       .split('LVR Rewards').join('Restaurant Rewards').split('LVR Points').join('Restaurant Rewards').split('LVR rewards').join('Restaurant Rewards');
  const after = (s.match(/LVR (Rewards|Points)/gi) || []).length;
  const blocks = [...s.matchAll(/<script>([\s\S]*?)<\/script>/g)]; let ok = true;
  blocks.forEach((m, i) => { fs.writeFileSync('/tmp/_rr_block.js', m[1]); const r = cp.spawnSync('node', ['--check', '/tmp/_rr_block.js'], { encoding: 'utf8' }); if (r.status) { ok = false; console.log(f + ' script block ' + i + ' FAILED: ' + (r.stderr || '').split('\n')[0]); } });
  if (!ok) { bad++; continue; }
  fs.writeFileSync(p, s); console.log(f + ': ' + before + ' spots changed (' + after + ' left), ' + blocks.length + ' script blocks parse');
}
process.exit(bad ? 2 : 0);
NODE
if [ "$?" != "0" ]; then echo "A page failed its checks - NOTHING was uploaded."; cat "$LOG"; exit 1; fi
for f in $DOPAGES; do cp "$DASH/$f" "$DASH/$f.bak-rrname" 2>/dev/null; cp "/tmp/rrname-new/$f" "$DASH/$f"; done
curl -sL -o deploy-overlay.js "$RAWB/deploy-overlay.js$CB"
export OVERLAY_FILES="$(echo $DOPAGES)"
echo "-- deploying --" >> "$LOG"
node deploy-overlay.js >> "$LOG" 2>&1
sleep 4
ALLOK=1
for f in $DOPAGES; do
  CODE=$(curl -s -o "/tmp/live-rr-$f" -w '%{http_code}' "$LIVE/$f?cb=$(date +%s)")
  if [ "$CODE" = "200" ] && grep -q 'Restaurant Rewards' "/tmp/live-rr-$f"; then echo "OK   $f is live with the new name" | tee -a "$LOG"; else echo "FAIL $f (HTTP $CODE) - not confirmed" | tee -a "$LOG"; ALLOK=0; fi
done
grep -E "changed|skip|FAILED" "$LOG"
if [ "$ALLOK" = "1" ]; then echo "RENAME LIVE: all done."; else echo "NOT ALL CONFIRMED - see above (log: $LOG)."; exit 1; fi
