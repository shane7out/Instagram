#!/bin/bash
# Fetch the live Torch Dating page and commit it into the repo for patching.
set -e
curl -s https://lvr-data-a60c1.web.app/dating.html -o .github/db-task/fetched/live-dating.html
SIZE=$(wc -c < .github/db-task/fetched/live-dating.html)
echo "fetched dating.html: $SIZE bytes"
if [ "$SIZE" -lt 10000 ]; then
  echo "FILE TOO SMALL - not committing"
  head -c 500 .github/db-task/fetched/live-dating.html
  exit 1
fi
grep -c "SPARK_V" .github/db-task/fetched/live-dating.html || true
git config user.name "db-task"
git config user.email "actions@users.noreply.github.com"
git add .github/db-task/fetched/live-dating.html
git commit -m "db-task: snapshot live dating.html for patching"
git push origin claude/master-file-e6ofy0
echo "committed and pushed"
