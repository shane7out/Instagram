#!/bin/bash
# Pull the latest manual.json export log (whatever happened - pass or the new
# local self-test catching the bug before upload) so Claude can read it from
# the sandbox, which can't reach firebaseio.com directly.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
mkdir -p .github/db-task/fetched
curl -s "$DB/_debug/diag.json" --max-time 30 | python3 -c "import json,sys; print(json.load(sys.stdin))" > .github/db-task/fetched/deals-manual-export-log.txt
echo "=== log ==="
cat .github/db-task/fetched/deals-manual-export-log.txt
echo
echo "=== latest runId pointer (only set if upload stage was reached) ==="
curl -s "$DB/_debug/deals_manual_json_latest.json" --max-time 20

git config user.name "db-task-bot"
git config user.email "db-task-bot@users.noreply.github.com"
git add .github/db-task/fetched/deals-manual-export-log.txt
if git diff --cached --quiet; then
  echo "nothing new to commit"
else
  git commit -m "fetch: manual.json export self-test log"
  git push origin HEAD:claude/master-file-e6ofy0
  echo "pushed"
fi
