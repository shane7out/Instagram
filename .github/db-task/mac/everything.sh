#!/bin/bash
# THE ONE MAC COMMAND (Shane, 2026-11-25: "I'll go to the Mac one more time"). Runs everything that is waiting, in the right order, and stops if the database-rules step does not pass:
#   1) database rules (leads, CRM, page views, waiting list and the rest locked to you; your PIN can open the website information)
#   2) Prospect CRM paste tool
#   3) the Key Technologies DM room with the new professional messages
#   4) blue look on the dashboard and the owner pages, the restaurant message restored (no introduction at the top), Johnny Mac's chip removed, the owner key opens the PIN pad
#   5) weekly database backup (set up once)
# FIRST it asks once for the contact email that goes at the end of every message (restaurant DM signature + Ads-tab emails). It is typed here, never stored in the public repository; Return keeps what is on the dashboard now.
# You type the owner email (on the keyboard) and the owner password twice (steps 1 and 4). Nothing is saved except the backup sign-in token on this Mac (~/.lvr).
#   curl -sL --retry 8 --retry-delay 1 --connect-timeout 15 --speed-limit 3000 --speed-time 6 --max-time 150 "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/everything.sh?$(date +%s)" -o /tmp/everything.sh && bash /tmp/everything.sh
set +e
echo
echo "Which email should every message end with, so replies come to you?"
echo "(for example Shane@keytechnologies.si - or just press Return to keep what is on the dashboard now)"
while true; do
  printf "Contact email: "; read -r REPLY_EMAIL < /dev/tty
  REPLY_EMAIL="$(echo "$REPLY_EMAIL" | tr -d ' ')"
  if [ -z "$REPLY_EMAIL" ]; then echo "  OK - keeping the current one."; break; fi
  if echo "$REPLY_EMAIL" | grep -Eq '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'; then echo "  OK - every message will end with $REPLY_EMAIL"; break; fi
  echo "  That does not look like an email address - try again."
done
export REPLY_EMAIL
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac"
step() {  # step "title" script-name
  echo; echo "=================================================="; echo "  $1"; echo "=================================================="
  curl -sL --retry 8 --retry-delay 1 --connect-timeout 15 --speed-limit 3000 --speed-time 6 --max-time 150 "$RAWB/$2?$(date +%s)" -o "/tmp/$2" || { echo "Could not download $2 - STOPPED."; exit 1; }
  bash "/tmp/$2" 2>&1 | tee "/tmp/$2.log"
}
SA="${START_AT:-1}"
if [ "$SA" -le 1 ]; then
step "STEP 1 of 5 - database rules" deploy-key-rules.sh
fi
if ! grep -q "ALL CHECKS PASSED" /tmp/deploy-key-rules.sh.log; then
  echo; echo ">>> The rules step did NOT pass, so I stopped before changing anything else. Take a screenshot of this window and send it to Claude."; exit 1
fi
if [ "$SA" -le 2 ]; then step "STEP 2 of 5 - Prospect CRM tool" deploy-kt-crm-cars.sh; fi
if [ "$SA" -le 3 ]; then step "STEP 3 of 5 - Key Technologies DM room (professional business messages, blue look, PIN pad)" deploy-kt-outreach.sh; fi
if [ "$SA" -le 4 ]; then step "STEP 4 of 5 - blue look, owner PIN pad, restaurant message restored, Ads tab message toggle, Johnny Mac's chip out" deploy-dashboard-keypad.sh; fi
if [ "$SA" -le 5 ]; then step "STEP 5 of 5 - weekly backup" backup-setup.sh; fi
echo; echo "=================================================="
echo "  SUMMARY"
echo "=================================================="
grep -q "ALL CHECKS PASSED" /tmp/deploy-key-rules.sh.log && echo "1 rules ........ passed" || echo "1 rules ........ CHECK"
grep -q "PROSPECT CRM LIVE" /tmp/deploy-kt-crm-cars.sh.log && echo "2 CRM tool ..... live" || echo "2 CRM tool ..... CHECK"
grep -q "KEYPADMATCH01\|RELEASED" /tmp/deploy-dashboard-keypad.sh.log && grep -q "RELEASED" /tmp/deploy-dashboard-keypad.sh.log && echo "4 blue + PIN + restaurant message ... released" || echo "4 blue + PIN + restaurant message ... CHECK"
grep -q "Weekly backup scheduled" /tmp/backup-setup.sh.log && echo "5 backup ....... scheduled, first backup made" || echo "5 backup ....... CHECK"
echo; echo "Now take a screenshot of this whole window and send it to Claude. Then you never need the Mac for this again."
