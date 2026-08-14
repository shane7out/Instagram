#!/bin/bash
# DEEP AUDIT: live site state, real CSP header, script permissions, data nodes, page health.
set -e
S="https://classiccarsforsale-co.web.app"
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
echo "===== 1. REAL RESPONSE HEADERS (incl CSP) ====="
curl -sI "$S/" | grep -iE "content-security|cache-control|strict-transport|x-frame" || echo "(no CSP/cache headers)"
echo
echo "===== 2. LIVE INDEX STATE ====="
curl -s "$S/?cb=$(date +%s)" -o live.html
for pat in "DEALS-REFRESH-v7" "DEALS-REFRESH-v8" 'src="/deals-refresh.js' '<button id="refreshbtn"' "land-eaglepoint" "🦇"; do
  echo "$pat: $(grep -c "$pat" live.html || true)"
done
echo "lastupd: $(grep -o '<div class="lastupd" id="lastupd">[^<]*' live.html | head -1)"
echo "cards in HTML: $(grep -c '<article class="card' live.html || true)"
echo
echo "===== 3. /deals-refresh.js live? ====="
curl -s -o drjs.txt -w "status %{http_code}, %{size_download} bytes\n" "$S/deals-refresh.js"
echo
echo "===== 4. app.js writes to firebaseio (proves connect path incl PUT)? ====="
curl -s "$S/app.js" -o app.js
grep -oE "method:['\"]?(PUT|POST|PATCH)" app.js | sort | uniq -c || echo "(no write verbs found)"
grep -c "firebaseio" app.js
echo
echo "===== 5. RTDB _deals nodes ====="
echo "updated: $(curl -s $DB/_deals/updated.json)"
echo "removed count: $(curl -s $DB/_deals/removed.json | python3 -c 'import json,sys; d=json.load(sys.stdin); print(len(d) if d else 0)')"
echo "request: $(curl -s $DB/_deals/refresh_request.json) | handled: $(curl -s $DB/_deals/refresh_handled.json)"
echo
echo "===== 6. coins + land pages ====="
curl -sL "$S/coins?cb=$(date +%s)" -o c.html
echo "coins: hosted=$(grep -c raw.githubusercontent c.html || true) craigslist=$(grep -c images.craigslist.org c.html || true) cards=$(grep -c 'class=\"card\"' c.html || true)"
curl -sL "$S/land-eaglepoint?cb=$(date +%s)" -o l.html
echo "land: hosted=$(grep -c raw.githubusercontent l.html || true) cards=$(grep -c 'class=\"card\"' l.html || true)"
echo
echo "===== 7. over-30-day cards still in HTML (client must hide) ====="
python3 - <<'PY'
import re
s=open('live.html').read()
ages=[int(m) for m in re.findall(r'listedage">(\d+) days? on the market', s)]
print("cards with age label:", len(ages), "| over 30 days:", sum(1 for a in ages if a>30), "| max age:", max(ages) if ages else 0)
PY
