#!/bin/bash
# Snapshot the-atl.web.app (Storage Containers page) so Claude can copy its refresh mechanism.
set -e
mkdir -p .github/db-task/fetched
curl -sL -o .github/db-task/fetched/live-atl.html "https://the-atl.web.app/"
echo "live-atl.html: $(wc -c < .github/db-task/fetched/live-atl.html) bytes"
# grab any same-site JS files it references
grep -oE 'src="/[^"]+\.js[^"]*"' .github/db-task/fetched/live-atl.html | sed 's/src="//;s/"//' | sort -u | while read -r p; do
  f=$(basename "${p%%\?*}")
  curl -sL -o ".github/db-task/fetched/atl-$f" "https://the-atl.web.app$p"
  echo "atl-$f: $(wc -c < ".github/db-task/fetched/atl-$f") bytes"
done
echo "--- fetch/refresh hints in page ---"
grep -oE 'fetch\([^)]*\)' .github/db-task/fetched/live-atl.html .github/db-task/fetched/atl-*.js 2>/dev/null | head -20 || true
git config user.name "Claude"
git config user.email "noreply@anthropic.com"
git add .github/db-task/fetched/
git commit -m "fetched: snapshot the-atl site (refresh mechanism reference)" || echo "no change"
git push
