#!/bin/bash
# Run on the Mac. Puts back the rules exactly as they were before deploy-key-rules.sh ran.
curl -sL "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/undo-rules.sh?$(date +%s)" -o /tmp/undo-rules.sh && bash /tmp/undo-rules.sh "$HOME/lvr-rules-backups/LATEST-BEFORE-KEY.json"
