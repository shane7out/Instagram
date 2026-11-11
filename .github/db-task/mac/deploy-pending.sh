#!/bin/bash
# Run on the Mac (ONE command). Does the two waiting owner-page deploys, in the safe order, and tells you plainly whether each worked:
#   1. the SECURITY FIX (makes lead/receipt text safe in your Leads, CRM, Rewards admin and Advertisers pages)
#   2. the new PROSPECT CRM (Car Sales + Real Estate people lists, search, CSV import/export)
#   curl -sL "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/deploy-pending.sh?$(date +%s)" -o /tmp/deploy-pending.sh && bash /tmp/deploy-pending.sh
set +e
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac"
CB="?cb=$(date +%s)"
R1=0; R2=0
echo "=== 1 of 2: security fix ==="
curl -sL -o /tmp/deploy-xss-fix.sh "$RAWB/deploy-xss-fix.sh$CB" && bash /tmp/deploy-xss-fix.sh; R1=$?
echo
echo "=== 2 of 2: Prospect CRM with Car Sales and Real Estate lists ==="
curl -sL -o /tmp/deploy-kt-crm-cars.sh "$RAWB/deploy-kt-crm-cars.sh$CB" && bash /tmp/deploy-kt-crm-cars.sh; R2=$?
echo
echo "=============== SUMMARY ==============="
[ "$R1" = "0" ] && echo "Security fix:  DONE" || echo "Security fix:  NOT CONFIRMED (copy everything above and send it to Claude)"
[ "$R2" = "0" ] && echo "Prospect CRM:  DONE" || echo "Prospect CRM:  NOT CONFIRMED (copy everything above and send it to Claude)"
