#!/bin/bash
# Run on the Mac. Puts back the database rules exactly as they were before
# deploy-rules.sh ran (from the copy saved in ~/lvr-rules-backups/).
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
FILE="${1:-$HOME/lvr-rules-backups/LATEST-BEFORE.json}"
[ -f "$FILE" ] || { echo "No backup found at $FILE"; exit 1; }
TOKEN=$(gcloud auth print-access-token 2>/dev/null)
[ -n "$TOKEN" ] || { echo "No gcloud login found"; exit 1; }
CODE=$(curl -s -o /tmp/undo-rules-out.txt -w "%{http_code}" -X PUT -H "Content-Type: application/json" --data-binary @"$FILE" "https://lvr-data-a60c1-default-rtdb.firebaseio.com/.settings/rules.json?access_token=$TOKEN")
echo "Restore -> HTTP $CODE"
[ "$CODE" = "200" ] && echo "Your previous rules are back in place." || head -c 300 /tmp/undo-rules-out.txt
