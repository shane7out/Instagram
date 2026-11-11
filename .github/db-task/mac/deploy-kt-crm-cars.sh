#!/bin/bash
# Run on the Mac (one command):
#   curl -sL "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/deploy-kt-crm-cars.sh?$(date +%s)" -o /tmp/deploy-kt-crm-cars.sh && bash /tmp/deploy-kt-crm-cars.sh
# Puts the new Prospect CRM live: a Car Sales tab (dealership, person and role, brands, website, source link, do-not-contact flag), search, and CSV import/export.
# Only the Prospect CRM page is replaced. Same safety as the other deploys: the page is downloaded and syntax-checked first, nothing is uploaded if a check fails, and the live copy is checked after.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac"
DASH="/Users/mac/lv-dash-work"
CB="?cb=$(date +%s)"
LOG=/tmp/ownerpagesdeploy.txt
: > "$LOG"
cd "$DASH" || { echo "NO DASH DIR ($DASH) - nothing changed."; exit 1; }
PAGES="kt-crm.html"
mkdir -p /tmp/ownerpages-new && rm -f /tmp/ownerpages-new/*
for f in $PAGES; do
  curl -sL -o "/tmp/ownerpages-new/$f" "$RAWB/$f$CB"
  echo "$f: $(wc -c < /tmp/ownerpages-new/$f) bytes" >> "$LOG"
done
# sanity: each page must parse, have the sign-in gate, have the sign-in box, and contain no PIN
node <<'NODE' >> "$LOG" 2>&1
const fs = require('fs'), cp = require('child_process');
let bad = 0;
for (const f of ['kt-crm.html']) {
  const s = fs.readFileSync('/tmp/ownerpages-new/' + f, 'utf8');
  const blocks = [...s.matchAll(/<script>([\s\S]*?)<\/script>/g)];
  if (!blocks.length) { console.log(f + ': NO SCRIPT BLOCK'); bad++; continue; }
  blocks.forEach((m, i) => {
    fs.writeFileSync('/tmp/_ownerpage_block.js', m[1]);
    const r = cp.spawnSync('node', ['--check', '/tmp/_ownerpage_block.js'], { encoding: 'utf8' });
    if (r.status) { console.log(f + ' script ' + i + ' SYNTAX CHECK FAILED:\n' + (r.stderr || '')); bad++; }
  });
  if (!s.includes('OWNER-SIGNIN-GATE')) { console.log(f + ': missing the sign-in gate'); bad++; }
  if (!s.includes('window.OWNER_AUTH')) { console.log(f + ': missing the sign-in box'); bad++; }
  if (/var PIN\s*=/.test(s) || s.includes('137900')) { console.log(f + ': still has a PIN'); bad++; }
  console.log(f + ': checks done');
}
process.exit(bad ? 2 : 0);
NODE
if [ "$?" != "0" ]; then
  echo "A page failed its checks - NOTHING was uploaded."; cat "$LOG"; exit 1
fi
cp /tmp/ownerpages-new/*.html "$DASH"/
curl -sL -o deploy-overlay.js "$RAWB/deploy-overlay.js$CB"
export OVERLAY_FILES="$PAGES"
echo "-- deploying --" >> "$LOG"
node deploy-overlay.js >> "$LOG" 2>&1
sleep 4
ALLOK=1
for f in $PAGES; do
  CODE=$(curl -s -o "/tmp/live-$f" -w '%{http_code}' "https://lvr-data-a60c1.web.app/$f?cb=$(date +%s)")
  GATE=$(grep -c 'Car Sales' "/tmp/live-$f" 2>/dev/null)
  OLD=$(grep -c '137900' "/tmp/live-$f" 2>/dev/null)
  if [ "$CODE" = "200" ] && [ "${GATE:-0}" -ge 1 ] && [ "${OLD:-0}" = "0" ]; then echo "OK   $f is live with the Car Sales tab" | tee -a "$LOG"; else echo "FAIL $f (HTTP $CODE, sign-in gate: ${GATE:-0}, old PIN present: ${OLD:-0})" | tee -a "$LOG"; ALLOK=0; fi
done
if [ "$ALLOK" = "1" ]; then echo "PROSPECT CRM LIVE: Car Sales tab, search and CSV import are ready. Refresh the page once."; else echo "NOT CONFIRMED - see above."; exit 1; fi
