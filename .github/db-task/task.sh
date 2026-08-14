#!/bin/bash
# DIAGNOSTIC: what's live on the Deals site + what cache rules is it serving with?
set -e
echo "===== response headers for / ====="
curl -sI "https://classiccarsforsale-co.web.app/" | grep -iE "cache-control|etag|last-modified|age:" || true
echo
echo "===== live content (cache-busted) ====="
curl -s "https://classiccarsforsale-co.web.app/?cb=$(date +%s)" -o live.html
echo "bytes: $(wc -c < live.html)"
echo "v6 blocks: $(grep -c 'DEALS-REFRESH-v6' live.html)"
echo "v7 blocks: $(grep -c 'DEALS-REFRESH-v7' live.html)"
echo "baked button: $(grep -c '<button id=\"refreshbtn\"' live.html)"
echo "lastupd: $(grep -o '<div class="lastupd" id="lastupd">[^<]*' live.html | head -1)"
echo
echo "===== coins page (cache-busted) ====="
curl -sL "https://classiccarsforsale-co.web.app/coins?cb=$(date +%s)" -o coins.html
echo "hosted imgs: $(grep -c 'raw.githubusercontent' coins.html)"
echo "craigslist imgs: $(grep -c 'images.craigslist.org' coins.html)"
echo
echo "===== a hosted image actually loads? ====="
IMG=$(grep -o 'https://raw.githubusercontent[^"]*' coins.html | head -1)
echo "sample: $IMG"
[ -n "$IMG" ] && curl -sL -o /tmp/img.jpg -w "img status %{http_code}, %{size_download} bytes, type %{content_type}\n" "$IMG"
