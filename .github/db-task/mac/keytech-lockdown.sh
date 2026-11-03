#!/bin/bash
# Run on the Mac AFTER owner-login.sh part 1 has created your owner login (owner-login.sh runs this for you at the end).
# Locks your Key Technologies data to your login, in the order that cannot break your pages:
#   STEP 1  put the sign-in versions of the CRM / Leads / Advertiser tools live (no PIN any more)
#   STEP 2  lock the lead list, page-view log and CRM so only you, signed in, can read them
#           (website visitors can still send a lead and still be counted)
# If step 1 does not confirm all pages live, step 2 is NOT run and nothing is locked.
set +e
RAW="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac"
CB="?cb=$(date +%s)"
if [ ! -s "$HOME/.lvr/owner-uid" ]; then
  echo "No owner login found on this Mac yet. Run the owner login first (owner-login.sh) - nothing changed."; exit 1
fi
echo "=============================================="
echo " STEP 1 of 2: owner tools go live with sign-in"
echo "=============================================="
curl -sL "$RAW/deploy-owner-pages.sh$CB" -o /tmp/deploy-owner-pages.sh && bash /tmp/deploy-owner-pages.sh 2>&1 | tee /tmp/keytech-step1.txt
if ! grep -q "OWNER PAGES LIVE" /tmp/keytech-step1.txt; then
  echo; echo "!! Step 1 did not finish cleanly, so I stopped. Nothing was locked. Tell Claude what the screen above says."; exit 1
fi
echo
echo "=============================================="
echo " STEP 2 of 2: lock leads, page views and CRM"
echo "=============================================="
curl -sL "$RAW/deploy-key-rules.sh$CB" -o /tmp/deploy-key-rules.sh && bash /tmp/deploy-key-rules.sh 2>&1 | tee /tmp/keytech-step2.txt
echo
if grep -q "ALL CHECKS PASSED" /tmp/keytech-step2.txt; then
  echo "DONE. Your leads, page views and CRM are locked to your login. Tell Claude 'keytech lockdown done' and I will check from the outside that a stranger is shut out."
else
  echo "Step 2 did not confirm. Your old rules are still in place (or were put back automatically). Tell Claude what the screen above says."
fi
