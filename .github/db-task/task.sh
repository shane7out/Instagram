#!/bin/bash
# Probe: can this runner search Craigslist? Test HTML search, sapi JSON API, and the areas reference.
set +e
echo "=== probe 1: classic HTML search page ==="
curl -s -o p1.html -w "status=%{http_code} size=%{size_download}\n" \
  -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36" \
  "https://lasvegas.craigslist.org/search/sss?query=batman+1966+cards"
grep -c "cl-search-result\|result-row\|nearby" p1.html 2>/dev/null
head -c 300 p1.html; echo

echo "=== probe 2: sapi JSON API ==="
curl -s -o p2.json -w "status=%{http_code} size=%{size_download}\n" \
  -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36" \
  "https://sapi.craigslist.org/web/v8/postings/search/full?batch=32-0-360-0-0&cc=US&lang=en&query=batman%201966%20cards&searchPath=sss"
head -c 300 p2.json; echo

echo "=== probe 3: areas reference (list of all CL regions) ==="
curl -s -o p3.json -w "status=%{http_code} size=%{size_download}\n" \
  "https://reference.craigslist.org/Areas"
head -c 300 p3.json; echo
