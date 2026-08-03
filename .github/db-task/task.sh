#!/bin/bash
# Dump one sapi search response to learn the item format.
set -e
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36"
curl -s -A "$UA" \
  "https://sapi.craigslist.org/web/v8/postings/search/full?batch=1-0-360-0-0&cc=US&lang=en&query=batman%201966&searchPath=sss" -o r.json
echo "size: $(wc -c < r.json)"
echo "--- top-level keys ---"
jq -r '.data | keys | join(", ")' r.json
echo "--- decode keys ---"
jq -r '.data.decode | keys | join(", ")' r.json 2>/dev/null || true
echo "--- totalResultCount ---"
jq -r '.data.totalResultCount // "n/a"' r.json
echo "--- first 3 items (raw) ---"
jq -c '.data.items[0:3]' r.json
echo "--- minPostingId etc ---"
jq -c '.data.decode.minPostingId? , .data.decode.minPostedDate? , .data.decode.locations[0:3]?' r.json 2>/dev/null || true
