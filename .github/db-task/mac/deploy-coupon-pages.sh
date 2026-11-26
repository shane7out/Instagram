#!/bin/bash
# STEP 6 of everything.sh: the restaurant coupon pages (own page + QR code per restaurant, customer list for the restaurant).
# Order matters: the two pages go live first, then the database rules that keep customer details private to you.
# (The rules step asks for your owner sign-in, like step 1.)
set +e
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac"
get() { curl -sL --retry 8 --retry-delay 1 --connect-timeout 15 --speed-limit 3000 --speed-time 6 --max-time 150 "$RAWB/$1?$(date +%s)" -o "/tmp/$1" && [ -s "/tmp/$1" ]; }
get deploy-lvr-coupons.sh || { echo "Could not download deploy-lvr-coupons.sh - nothing changed."; exit 1; }
get deploy-owner-rules.sh || { echo "Could not download deploy-owner-rules.sh - nothing changed."; exit 1; }
echo "--- 6a: putting the restaurant coupon pages live ---"
bash /tmp/deploy-lvr-coupons.sh 2>&1 | tee /tmp/deploy-lvr-coupons.sh.log
if ! grep -q "live /lvr-coupon.html status: 200" /tmp/deploy-lvr-coupons.sh.log || ! grep -q "gate 1, old PIN 0" /tmp/deploy-lvr-coupons.sh.log; then
  echo; echo ">>> The coupon pages did not come up cleanly, so I did NOT touch the database rules. Send Claude a screenshot."; exit 1
fi
echo; echo "--- 6b: locking the customer details to you (database rules) ---"
bash /tmp/deploy-owner-rules.sh 2>&1 | tee /tmp/deploy-owner-rules.sh.log
if grep -q "ALL CHECKS PASSED" /tmp/deploy-owner-rules.sh.log; then echo; echo "COUPON PAGES LIVE: pages and rules both passed."; else echo; echo ">>> The rules step did not pass (your old rules were put back if anything failed). Send Claude a screenshot."; exit 1; fi
