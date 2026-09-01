#!/bin/bash
# DIAGNOSTIC: did deploy-sites-pill.sh run? what's live on the dashboard right now?
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
echo "===== _debug/diag relay (last Mac script log) ====="
curl -s "$DB/_debug/diag.json" | head -c 1500
echo
echo
echo "===== live dashboard ====="
curl -s "https://lvr-data-a60c1.web.app/?cb=$(date +%s)" -o dash.html
echo "bytes: $(wc -c < dash.html)"
echo "APP_VERSION: $(grep -oE 'APP_VERSION=[0-9]+' dash.html | head -1)"
echo "has /sites.html link: $(grep -c '/sites.html' dash.html || true)"
echo "has All Sites text: $(grep -c 'All Sites' dash.html || true)"
echo
echo "===== is the page itself deployed? ====="
echo "/sites.html -> $(curl -sL -o /dev/null -w '%{http_code}' https://lvr-data-a60c1.web.app/sites.html)"
echo
echo "===== the exact Deals-pill markup my regex must match ====="
python3 - <<'PY'
import re
s=open('dash.html',encoding='utf-8',errors='replace').read()
i=s.find('classiccarsforsale-co.web.app')
print(repr(s[max(0,i-120):i+220]) if i>=0 else 'DEALS ANCHOR NOT PRESENT')
print()
m=re.search(r'(<a href="https://classiccarsforsale-co\.web\.app"[\s\S]*?>Deals</a>)', s)
print('regex matches Deals pill:', bool(m))
PY
