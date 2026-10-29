#!/bin/bash
# Run on the Mac. Does everything in the right order, with one command:
#   STEP 1  safe database rules (saves a backup first, undoes itself if a check fails)
#   STEP 2  owner tools and sign-up pages go live (Points admin, Bonus tab, restaurant portal, coupons...)
# If step 1 does not report ALL CHECKS PASSED, step 2 is NOT run and nothing else changes.
set +e
RAW="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac"
CB="?cb=$(date +%s)"   # a fresh address every run, so GitHub never hands back an old copy
OUT=/tmp/golive-rules.txt
echo "=============================================="
echo " STEP 1 of 2: safety rules for the points data"
echo "=============================================="
curl -sL "$RAW/deploy-rules.sh$CB" | bash 2>&1 | tee "$OUT"
if ! grep -q "ALL CHECKS PASSED" "$OUT"; then
  echo
  echo "!! Step 1 did not finish cleanly, so I stopped. Your old rules are still in place."
  echo "!! Tell Claude what the screen above says."
  exit 1
fi
echo
echo "=============================================="
echo " STEP 2 of 2: owner tools + sign-up pages"
echo "=============================================="
curl -sL "$RAW/deploy-key-room.sh$CB" | bash 2>&1 | tail -40
echo
echo "=============================================="
echo " ALL DONE. Tell Claude 'finished' and I will check everything is live."
echo "=============================================="
