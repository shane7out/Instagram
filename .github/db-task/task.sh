#!/bin/bash
# READ-ONLY: verify v7 live — baked button, photo-fixed coins/land, relay log.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
echo "===== _debug/diag relay ====="
curl -s "$DB/_debug/diag.json"
echo
echo "===== live checks (cache-busted) ====="
curl -s "https://classiccarsforsale-co.web.app/?cb=$(date +%s)" -o live.html
echo "v7 blocks: $(grep -c 'DEALS-REFRESH-v7' live.html || true)"
echo "baked button: $(grep -c '<button id=\"refreshbtn\"' live.html || true)"
echo "lastupd+button: $(grep -o '<div class="lastupd" id="lastupd">[^<]*</div><button id="refreshbtn"' live.html | head -1)"
curl -sL "https://classiccarsforsale-co.web.app/coins?cb=$(date +%s)" -o coins.html
echo "coins hosted imgs: $(grep -c 'raw.githubusercontent' coins.html || true) | craigslist leftovers: $(grep -c 'images.craigslist.org' coins.html || true)"
curl -sL "https://classiccarsforsale-co.web.app/land-eaglepoint?cb=$(date +%s)" -o land.html
echo "land hosted imgs: $(grep -c 'raw.githubusercontent' land.html || true)"
IMG=$(grep -o 'https://raw.githubusercontent[^"]*' coins.html | head -1)
if [ -n "$IMG" ]; then curl -sL -o /tmp/i.jpg -w "sample img: %{http_code}, %{size_download}b, %{content_type}\n" "$IMG"; else echo "no hosted img found"; fi
