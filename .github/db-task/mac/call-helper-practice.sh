#!/bin/bash
# Run on the Mac (one command). PRACTICE tool: live suggestions from a practice conversation. Never use it with real customers.
#   curl -sL --retry 8 --retry-delay 1 --connect-timeout 15 --speed-limit 3000 --speed-time 6 --max-time 150 "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/call-helper-practice.sh?$(date +%s)" -o /tmp/call-helper-practice.sh && bash /tmp/call-helper-practice.sh
# You type your AI service key HERE in Terminal (hidden, never saved to a file, never sent anywhere except the AI service, never put in the repo or in chat).
# It starts a small page on this Mac only (127.0.0.1) and opens it in your browser. Press Control-C in Terminal to stop; the key is forgotten when it stops.
set +e
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac"
command -v node >/dev/null 2>&1 || { echo "Node is not installed on this Mac - tell Claude."; exit 1; }
D="$HOME/call-helper-practice"; mkdir -p "$D"
for F in call-helper-practice.js call-helper-practice.html; do
  curl -sL --retry 8 --retry-delay 1 --connect-timeout 15 --speed-limit 3000 --speed-time 6 --max-time 150 -o "$D/$F" "$RAWB/$F?cb=$(date +%s)"
done
node --check "$D/call-helper-practice.js" || { echo "The program did not download correctly - nothing started."; exit 1; }
grep -q "Call helper (practice)" "$D/call-helper-practice.html" || { echo "The page did not download correctly - nothing started."; exit 1; }
echo "PRACTICE ONLY: use it with a friend or yourself, never with a real customer."
read -r -s -p "AI service key (hidden, not saved): " CALL_HELPER_KEY; echo
[ -n "$CALL_HELPER_KEY" ] || { echo "No key typed - nothing started."; exit 1; }
export CALL_HELPER_KEY
( sleep 2; open "http://127.0.0.1:8777/" ) >/dev/null 2>&1 &
node "$D/call-helper-practice.js"
unset CALL_HELPER_KEY
