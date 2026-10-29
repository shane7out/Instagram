#!/bin/bash
# One-shot (run on the Mac): deploy the new LVR coupon-advertising program as
# two standalone pages on lvr-data-a60c1.web.app - same Firebase project/
# database as the main dashboard, new top-level node /lvr_coupons.
#
#   lvr-coupon.html        - customer-facing claim page (no PIN).
#                             Opened as ?biz=<slug>, e.g. for the Vanilla Rice
#                             pitch: lvr-coupon.html?biz=vanilla-rice
#                             Customer enters name/email/phone (marketing
#                             opt-in always optional, never required to claim
#                             - matches what was promised in the outreach DM),
#                             gets a unique coupon code shown on-screen to
#                             redeem in-restaurant. Honors active/expiresAt/
#                             maxClaims on the program; shows a real "X of Y
#                             left" count, never a fabricated one. Reuses an
#                             existing claim's code instead of creating a
#                             duplicate when the same email/phone claims
#                             twice.
#
#   lvr-coupons-admin.html - PIN-gated (137900) admin tool for Shane: create/
#                             edit coupon programs per restaurant (offer,
#                             photo, expiration, max claims, active toggle),
#                             copy each program's claim link, view/mark-
#                             redeemed/delete claims per program.
#
# Both tested with mocked Firebase data via Playwright before shipping (claim
# page: missing/not-found/inactive/expired/maxed-out states, scarcity count,
# successful claim, dedup reuse, validation; admin tool: PIN gate, program
# list, create/edit, claims view, mark-redeemed, delete) - no JS errors.
# Reuses the same proven deploy-overlay.js every other dashboard/tool patch
# uses.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac"
DASH="/Users/mac/lv-dash-work"
LOG=/tmp/lvrcoupondeploy.txt
: > "$LOG"

cd "$DASH" || { echo "NO DASH DIR ($DASH)"; exit 1; }

curl -sL -o lvr-coupon.html "$RAWB/lvr-coupon.html"
curl -sL -o lvr-coupons-admin.html "$RAWB/lvr-coupons-admin.html"
echo "lvr-coupon.html: $(wc -c < lvr-coupon.html) bytes" >> "$LOG"
echo "lvr-coupons-admin.html: $(wc -c < lvr-coupons-admin.html) bytes" >> "$LOG"

# sanity: every inline script block in both files must parse before anything ships
FAIL=0
for f in lvr-coupon.html lvr-coupons-admin.html; do
  node <<NODE >> "$LOG" 2>&1
const fs = require('fs'), cp = require('child_process');
const s = fs.readFileSync('$f', 'utf8');
const scripts = [...s.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/g)].map(m => m[1]);
if (!scripts.length) { console.log('$f: NO SCRIPT BLOCK FOUND'); process.exit(2); }
fs.writeFileSync('/tmp/_lvrcoupon_block.js', scripts.join('\n;\n'));
const r = cp.spawnSync('node', ['--check', '/tmp/_lvrcoupon_block.js'], { encoding: 'utf8' });
if (r.status) { console.log('$f: SYNTAX CHECK FAILED:\n' + (r.stderr || '')); process.exit(2); }
console.log('$f: syntax check OK');
NODE
  if [ "$?" != "0" ]; then
    echo "$f FAILED syntax check — removing it" >> "$LOG"
    rm -f "$f"
    FAIL=1
  fi
done

if [ "$FAIL" = "1" ]; then
  echo "ONE OR MORE FILES FAILED — not deploying the bad one(s)" >> "$LOG"
fi

# ---------------------------------------------------------------------------
# deploy + verify (same deployer the dashboard patches already use)
# Always pull the latest deploy-overlay.js and tell it which files to ship
# (fixed 2026-10-27 - it used to silently overlay ONLY index.html+
# version.json no matter what else was in the folder, so this and every
# other standalone tool was never actually going live).
# ---------------------------------------------------------------------------
curl -sL -o deploy-overlay.js "$RAWB/deploy-overlay.js"
DEP="deploy-overlay.js"
if [ -n "$DEP" ]; then
  echo "-- deploying ($DEP) --" >> "$LOG"
  OVERLAY_FILES="lvr-coupon.html lvr-coupons-admin.html" node "$DEP" >> "$LOG" 2>&1
else
  echo "NO DASHBOARD DEPLOYER FOUND in $DASH" >> "$LOG"
fi

sleep 3
echo "-- live check --" >> "$LOG"
echo "live /lvr-coupon.html status: $(curl -s -o /tmp/lvrcoupon-live.html -w '%{http_code}' 'https://lvr-data-a60c1.web.app/lvr-coupon.html')" >> "$LOG"
echo "live /lvr-coupons-admin.html status: $(curl -s -o /tmp/lvrcouponadmin-live.html -w '%{http_code}' https://lvr-data-a60c1.web.app/lvr-coupons-admin.html)" >> "$LOG"
echo "claim page has claimForm logic: $(grep -c 'claimForm' /tmp/lvrcoupon-live.html 2>/dev/null || echo 0)" >> "$LOG"
echo "admin page has pin-screen: $(grep -c 'id=\"pin-screen\"' /tmp/lvrcouponadmin-live.html 2>/dev/null || echo 0)" >> "$LOG"

echo "" >> "$LOG"
echo "Customer claim link for Vanilla Rice (create this program first in the admin tool):" >> "$LOG"
echo "  https://lvr-data-a60c1.web.app/lvr-coupon.html?biz=vanilla-rice" >> "$LOG"
echo "Admin tool: https://lvr-data-a60c1.web.app/lvr-coupons-admin.html" >> "$LOG"
echo "Admin PIN: 137900 (change it by editing the 'var PIN =' line in lvr-coupons-admin.html and re-running this deploy)" >> "$LOG"

node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/lvrcoupondeploy.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT — tell Claude done")).catch(e=>console.log("send failed "+e.message))'
echo "==== done ===="; cat "$LOG"
