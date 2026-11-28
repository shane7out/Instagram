#!/bin/bash
# Run on the Mac. Puts back the database rules exactly as they were before deploy-dashboard-lock.sh ran (the dashboard lists become readable and writable by anyone again, as before).
curl -sL --retry 8 --retry-delay 1 --connect-timeout 15 --speed-limit 3000 --speed-time 6 --max-time 150 "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/undo-rules.sh?$(date +%s)" -o /tmp/undo-rules.sh && bash /tmp/undo-rules.sh "$HOME/lvr-rules-backups/LATEST-BEFORE-DASHLOCK.json"
