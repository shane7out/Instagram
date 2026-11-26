#!/bin/bash
# One-shot (run on the Mac): deploy the new LVR coupon-advertising program as
# two standalone pages on lvr-data-a60c1.web.app - same Firebase project/
# database as the main dashboard, new top-level node /lvr_coupons.
#
#   lvr-coupon.html        - the customer page, one per restaurant (?biz=<page name>), reached by QR code or link.
#                             Customer enters name + email (phone optional). Email marketing and TEXT marketing are
#                             two separate unticked boxes; the text box only turns on once a phone number is typed,
#                             and the exact wording they agreed to is saved with the sign-up. Same email twice
#                             gets the same code back. Never reads anyone else's details.
#
#   lvr-team.html         - each employee's own live page (private link from the Team screen): their QR code to show guests,
#                             and keys earned / sign-ups today / sign-ups in all, updating by itself within seconds of
#                             each sign-up. Shows no customer details.
#
#   lvr-optout.html       - "Stop all messages": a guest types their email and/or phone and is on the do-not-message list at once
#                             (every list and download in the admin page leaves them out). Linked from the sign-up page.
#
#   lvr-redeem.html       - the restaurant's staff type a guest's code (no login): good / already used / expired, and one tap
#                             to redeem. A code works once, and only within the coupon's days (rules enforce both).
#
#   lvr-coupons-admin.html - OWNER SIGN-IN (no PIN in the page). For each restaurant: edit the offer, QR code and
#                             printable counter sign, the customer list (name, email, phone, OK-to-email, OK-to-text with
#                             the saved consent wording), download everyone / the email list / the text list for the
#                             restaurant, mark a coupon used, remove a customer.
#
# The database rules for this (deploy-owner-rules.sh) make customer details readable only by the signed-in owner.
# deploy-coupon-pages.sh runs this file and then the rules, in that order, as step 6 of everything.sh.
# Tested in a real browser against the database emulator (rules/run-coupon-pages-test.sh, 35 checks) and the rules
# themselves (rules/run-coupon-rules-test.sh, 40 checks).
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac"
DASH="/Users/mac/lv-dash-work"
LOG=/tmp/lvrcoupondeploy.txt
: > "$LOG"

cd "$DASH" || { echo "NO DASH DIR ($DASH)"; exit 1; }

curl -sL --retry 8 --retry-delay 1 --connect-timeout 15 --speed-limit 3000 --speed-time 6 --max-time 150 -o lvr-coupon.html "$RAWB/lvr-coupon.html"
curl -sL --retry 8 --retry-delay 1 --connect-timeout 15 --speed-limit 3000 --speed-time 6 --max-time 150 -o lvr-coupons-admin.html "$RAWB/lvr-coupons-admin.html"
curl -sL --retry 8 --retry-delay 1 --connect-timeout 15 --speed-limit 3000 --speed-time 6 --max-time 150 -o lvr-team.html "$RAWB/lvr-team.html"
echo "lvr-team.html: $(wc -c < lvr-team.html) bytes" >> "$LOG"
curl -sL --retry 8 --retry-delay 1 --connect-timeout 15 --speed-limit 3000 --speed-time 6 --max-time 150 -o lvr-redeem.html "$RAWB/lvr-redeem.html"
echo "lvr-redeem.html: $(wc -c < lvr-redeem.html) bytes" >> "$LOG"
curl -sL --retry 8 --retry-delay 1 --connect-timeout 15 --speed-limit 3000 --speed-time 6 --max-time 150 -o lvr-optout.html "$RAWB/lvr-optout.html"
echo "lvr-optout.html: $(wc -c < lvr-optout.html) bytes" >> "$LOG"
echo "lvr-coupon.html: $(wc -c < lvr-coupon.html) bytes" >> "$LOG"
echo "lvr-coupons-admin.html: $(wc -c < lvr-coupons-admin.html) bytes" >> "$LOG"

# sanity: every inline script block in both files must parse before anything ships
FAIL=0
for f in lvr-coupon.html lvr-coupons-admin.html lvr-team.html lvr-redeem.html lvr-optout.html; do
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
curl -sL --retry 8 --retry-delay 1 --connect-timeout 15 --speed-limit 3000 --speed-time 6 --max-time 150 -o deploy-overlay.js "$RAWB/deploy-overlay.js"
DEP="deploy-overlay.js"
if [ -n "$DEP" ]; then
  echo "-- deploying ($DEP) --" >> "$LOG"
  OVERLAY_FILES="lvr-coupon.html lvr-coupons-admin.html lvr-team.html lvr-redeem.html lvr-optout.html" node "$DEP" >> "$LOG" 2>&1
else
  echo "NO DASHBOARD DEPLOYER FOUND in $DASH" >> "$LOG"
fi

sleep 3
echo "-- live check --" >> "$LOG"
echo "live /lvr-coupon.html status: $(curl -s -o /tmp/lvrcoupon-live.html -w '%{http_code}' 'https://lvr-data-a60c1.web.app/lvr-coupon.html')" >> "$LOG"
echo "live /lvr-team.html status: $(curl -s -o /tmp/lvrteam-live.html -w '%{http_code}' https://lvr-data-a60c1.web.app/lvr-team.html)" >> "$LOG"
echo "live /lvr-redeem.html status: $(curl -s -o /tmp/lvrredeem-live.html -w '%{http_code}' https://lvr-data-a60c1.web.app/lvr-redeem.html)" >> "$LOG"
echo "live /lvr-optout.html status: $(curl -s -o /tmp/lvroptout-live.html -w '%{http_code}' https://lvr-data-a60c1.web.app/lvr-optout.html)" >> "$LOG"
echo "live /lvr-coupons-admin.html status: $(curl -s -o /tmp/lvrcouponadmin-live.html -w '%{http_code}' https://lvr-data-a60c1.web.app/lvr-coupons-admin.html)" >> "$LOG"
echo "claim page is the new one (private duplicate check): $(grep -c 'emailKey' /tmp/lvrcoupon-live.html 2>/dev/null || echo 0)" >> "$LOG"
echo "admin page has the owner sign-in and no PIN: gate $(grep -c 'OWNER-SIGNIN-GATE' /tmp/lvrcouponadmin-live.html 2>/dev/null || echo 0), old PIN $(grep -c '137900' /tmp/lvrcouponadmin-live.html 2>/dev/null || echo 0)" >> "$LOG"

echo "" >> "$LOG"
echo "Customer link for Vanilla Rice (make the restaurant page in the admin tool first):" >> "$LOG"
echo "  https://lvr-data-a60c1.web.app/lvr-coupon.html?biz=vanilla-rice" >> "$LOG"
echo "Admin tool: https://lvr-data-a60c1.web.app/lvr-coupons-admin.html" >> "$LOG"
echo "The admin page opens with your owner sign-in (no PIN stored in it)." >> "$LOG"

node -e 'const fs=require("fs");fetch("'"$DB"'/_debug/diag.json",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify(fs.readFileSync("/tmp/lvrcoupondeploy.txt","utf8").slice(-5000))}).then(()=>console.log("LOG SENT — tell Claude done")).catch(e=>console.log("send failed "+e.message))'
echo "==== done ===="; cat "$LOG"
