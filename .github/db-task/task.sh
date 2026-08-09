#!/bin/bash
# Fetch the LIVE Deals site index.html and commit it back so Claude can design the
# refresh-button / updated-date patches against the real markup.
set -e
curl -sL -o .github/db-task/fetched/live-deals.html "https://classiccarsforsale-co.web.app/"
echo "live-deals.html: $(wc -c < .github/db-task/fetched/live-deals.html) bytes"
echo "--- 'Updated' markup context ---"
grep -oE '.{160}[Uu]pdated.{160}' .github/db-task/fetched/live-deals.html | head -5 || true
echo "--- 'available' markup context ---"
grep -oE '.{160}available.{160}' .github/db-task/fetched/live-deals.html | head -5 || true
git config user.name "Claude"
git config user.email "noreply@anthropic.com"
git add .github/db-task/fetched/live-deals.html
git commit -m "fetched: snapshot live Deals index.html" || echo "no change"
git push
