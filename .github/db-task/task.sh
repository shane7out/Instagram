#!/bin/bash
# Snapshot the dating site so the login/signup flow can be read before patching.
set +e
OUT=.github/db-task/fetched
mkdir -p "$OUT"
curl -sL --max-time 90 -o "$OUT/live-dating.html" https://lvr-data-a60c1.web.app/dating.html
echo "dating.html: $(wc -c < "$OUT/live-dating.html") bytes"
grep -ao 'APP_VERSION=[0-9]*\|DATING_VERSION=[0-9]*\|VERSION\s*=\s*[0-9]*' "$OUT/live-dating.html" | head -5

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -A "$OUT"
git commit -m "snapshot: live dating site" || { echo "nothing to commit"; exit 0; }
for i in 1 2 3 4; do git push origin HEAD:claude/master-file-e6ofy0 && break; sleep $((i*3)); git pull --rebase origin claude/master-file-e6ofy0; done
