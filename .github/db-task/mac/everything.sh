#!/bin/bash
# THE ONE MAC COMMAND (Shane, 2026-11-25: "I'll go to the Mac one more time"). Runs everything that is waiting, in the right order, and stops if the database-rules step does not pass:
#   1) database rules (leads, CRM, page views, waiting list and the rest locked to you; your PIN can open the website information)
#   2) Prospect CRM paste tool
#   3) blue look on the dashboard and the owner pages, Johnny Mac's chip removed, the owner key opens the PIN pad
#   4) weekly database backup (set up once)
# You type the owner email (on the keyboard) and the owner password twice (steps 1 and 4). Nothing is saved except the backup sign-in token on this Mac (~/.lvr).
#   curl -sL "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/everything.sh?$(date +%s)" -o /tmp/everything.sh && bash /tmp/everything.sh
set +e
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac"
step() {  # step "title" script-name
  echo; echo "=================================================="; echo "  $1"; echo "=================================================="
  curl -sL "$RAWB/$2?$(date +%s)" -o "/tmp/$2" || { echo "Could not download $2 - STOPPED."; exit 1; }
  bash "/tmp/$2" 2>&1 | tee "/tmp/$2.log"
}
step "STEP 1 of 4 - database rules" deploy-key-rules.sh
if ! grep -q "ALL CHECKS PASSED" /tmp/deploy-key-rules.sh.log; then
  echo; echo ">>> The rules step did NOT pass, so I stopped before changing anything else. Take a screenshot of this window and send it to Claude."; exit 1
fi
step "STEP 2 of 4 - Prospect CRM tool" deploy-kt-crm-cars.sh
step "STEP 3 of 4 - blue look, owner PIN pad, Johnny Mac's chip out" deploy-dashboard-keypad.sh
step "STEP 4 of 4 - weekly backup" backup-setup.sh
echo; echo "=================================================="
echo "  SUMMARY"
echo "=================================================="
grep -q "ALL CHECKS PASSED" /tmp/deploy-key-rules.sh.log && echo "1 rules ........ passed" || echo "1 rules ........ CHECK"
grep -q "PROSPECT CRM LIVE" /tmp/deploy-kt-crm-cars.sh.log && echo "2 CRM tool ..... live" || echo "2 CRM tool ..... CHECK"
grep -q "RELEASED" /tmp/deploy-dashboard-keypad.sh.log && echo "3 blue + PIN ... released" || echo "3 blue + PIN ... CHECK"
grep -q "Weekly backup scheduled" /tmp/backup-setup.sh.log && echo "4 backup ....... scheduled, first backup made" || echo "4 backup ....... CHECK"
echo; echo "Now take a screenshot of this whole window and send it to Claude. Then you never need the Mac for this again."
