#!/bin/bash
# Snapshot gate.js from the live Deals site — suspect it's killing the refresh button's click handler.
set -e
curl -sL -o .github/db-task/fetched/live-gate.js "https://classiccarsforsale-co.web.app/gate.js"
echo "gate.js: $(wc -c < .github/db-task/fetched/live-gate.js) bytes"
head -c 600 .github/db-task/fetched/live-gate.js; echo
git config user.name "Claude"
git config user.email "noreply@anthropic.com"
git add .github/db-task/fetched/live-gate.js
git commit -m "fetched: gate.js snapshot" || echo "no change"
git push
