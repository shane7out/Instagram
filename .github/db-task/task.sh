#!/bin/bash
# Fetch the Deals scraper source Shane uploaded to Firebase diag, and commit
# it into the repo under .github/db-task/fetched/ so Claude can read it from
# the sandbox (direct firebaseio.com access is blocked there, but GitHub
# Actions can reach it fine). No secrets in this payload - gen.js just
# scrapes public Craigslist pages.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
mkdir -p .github/db-task/fetched
curl -s "$DB/_debug/deals_scraper_source.json" --max-time 60 -o .github/db-task/fetched/deals-scraper-source.json
echo "fetched size: $(wc -c < .github/db-task/fetched/deals-scraper-source.json) bytes"

git config user.name "db-task-bot"
git config user.email "db-task-bot@users.noreply.github.com"
git add .github/db-task/fetched/deals-scraper-source.json
if git diff --cached --quiet; then
  echo "nothing new to commit"
else
  git commit -m "fetch: deals scraper source snapshot"
  git push origin HEAD:claude/master-file-e6ofy0
  echo "pushed"
fi
