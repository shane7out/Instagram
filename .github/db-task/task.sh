#!/bin/bash
# Verify two CI-flagged "dead" Craigslist listings really are expired (false-positive check).
set -e
check() {
  echo "=== $1"
  CODE=$(curl -sL -o /tmp/p.html -w '%{http_code}' -A "Mozilla/5.0" "$1")
  echo "status: $CODE, bytes: $(wc -c < /tmp/p.html)"
  grep -oiE "this posting has been (deleted|flagged)[^<]*|this posting has expired[^<]*|page not found" /tmp/p.html | head -2 || echo "no dead-marker in body"
  grep -oE "<title>[^<]*</title>" /tmp/p.html | head -1 || true
}
check "https://www.craigslist.org/view/d/northridge-2017-tesla-model-100d-will/do7h4GWhUbG2bEvamrNePH"
check "https://www.craigslist.org/view/d/san-luis-obispo-2021-tesla-model-long/6dkuLgp5rjEwvkLkALcGis"
