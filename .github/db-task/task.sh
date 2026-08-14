#!/bin/bash
# READ-ONLY: verify v5 deploy — relay log + live checks (button, land tab/page, batman gone).
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
echo "===== _debug/diag relay ====="
curl -s "$DB/_debug/diag.json"
echo
echo "===== live checks ====="
curl -s "https://classiccarsforsale-co.web.app/?v=$(date +%s)" -o live.html
echo "v5 blocks: $(grep -c 'DEALS-REFRESH-v5' live.html)"
echo "fixed button: $(grep -c 'position:fixed;top:14px;right:14px' live.html)"
echo "lastupd: $(grep -o '<div class="lastupd" id="lastupd">[^<]*' live.html | head -1)"
echo "land tab: $(grep -c 'href="/land-eaglepoint"' live.html)"
echo "batman tablink: $(grep -c '🦇 Batman Cards</a>' live.html || true)"
echo "/land-eaglepoint: $(curl -sL -o /dev/null -w '%{http_code}' https://classiccarsforsale-co.web.app/land-eaglepoint)"
