#!/bin/bash
# Diagnose why coin-page images don't render: test the CDN image URLs.
set +e
curl -s https://classiccarsforsale-co.web.app/coins -o coins.html
echo "coins.html size: $(wc -c < coins.html)"
echo "=== first 3 img srcs ==="
grep -oE 'src="https://images.craigslist.org/[^"]+"' coins.html | head -3
echo "=== fetch each (no referer) ==="
for u in $(grep -oE 'https://images.craigslist.org/[^"]+' coins.html | head -3); do
  echo "$(curl -s -o /dev/null -w '%{http_code} %{size_download} %{content_type}' "$u")  $u"
done
echo "=== with a foreign referer (simulate browser on our site) ==="
for u in $(grep -oE 'https://images.craigslist.org/[^"]+' coins.html | head -1); do
  echo "$(curl -s -o /dev/null -w '%{http_code} %{size_download}' -e 'https://classiccarsforsale-co.web.app/coins' "$u")  $u"
done
