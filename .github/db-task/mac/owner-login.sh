#!/bin/bash
# ONE command for the owner login. Run on the Mac (paste this whole line into Terminal):
#   curl -sL "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/owner-login.sh?$(date +%s)" -o /tmp/owner-login.sh && bash /tmp/owner-login.sh
#
# What it does, in order (you are asked before each part):
#   Part 1 (owner-setup.sh): creates YOUR owner login. First do the one click in the Firebase console it tells you about
#          (Authentication > Sign-in method > Email/Password > Enable), then it asks for your email and a password.
#   Part 2 (deploy-owner-rules.sh): locks the Points settings, approvals and pool so only you, signed in, can change them.
#   Part 3 (keytech-lockdown.sh): puts sign-in (no PIN) on your CRM / Leads / Advertiser tools, then locks your lead list,
#          page-view log and CRM so only you, signed in, can read them. Visitors can still send leads and be counted.
# Parts 2 and 3 save a copy of the current rules first and put them back automatically if any check fails.
# Your email and password go only to Google's sign-in service. Nothing here prints them.
BASE="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac"
echo
echo "=== PART 1 of 2: create your owner login ==="
curl -sL "$BASE/owner-setup.sh?$(date +%s)" -o /tmp/owner-setup.sh && bash /tmp/owner-setup.sh
if [ ! -s "$HOME/.lvr/owner-uid" ]; then
  echo
  echo "Part 1 did not finish (no owner id saved), so I stopped before changing any rules. Nothing was locked."
  echo "Fix what it said above, then run this same command again."
  exit 1
fi
echo
echo "=== PART 2 of 2: lock the Points settings to your login ==="
read -p "Part 1 worked. Press Return to lock the settings (Ctrl+C to stop here): " _
curl -sL "$BASE/deploy-owner-rules.sh?$(date +%s)" -o /tmp/deploy-owner-rules.sh && bash /tmp/deploy-owner-rules.sh
echo
echo "=== PART 3 of 3: lock your Key Technologies leads, page views and CRM to your login ==="
echo "(This replaces the old PIN screens with real sign-in and shuts strangers out of your lead list.)"
read -p "Press Return to do it (Ctrl+C to stop here; you can run it later with keytech-lockdown.sh): " _
curl -sL "$BASE/keytech-lockdown.sh?$(date +%s)" -o /tmp/keytech-lockdown.sh && bash /tmp/keytech-lockdown.sh
echo
echo "Done. Open the Points admin page: you will see an Owner sign-in button at the bottom right. Sign in once there."
echo "Then tell Claude 'owner login done' and Claude will check from the outside that a stranger is locked out."
