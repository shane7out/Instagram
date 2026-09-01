#!/bin/bash
# DIAGNOSTIC: are the St Rita's / directory GitHub Pages links live yet?
set -e
echo "===== live URL checks ====="
for u in "https://shane7out.github.io/Instagram/" \
         "https://shane7out.github.io/Instagram/st-ritas/" \
         "https://shane7out.github.io/Instagram/st-ritas/availability.html" \
         "https://shane7out.github.io/Instagram/st-ritas/data/availability.json"; do
  echo "$u -> $(curl -sL -o /dev/null -w '%{http_code}' --max-time 25 "$u")"
done
echo
echo "===== what a request actually returns (first 200 chars) ====="
curl -sL --max-time 25 "https://shane7out.github.io/Instagram/st-ritas/" | head -c 200; echo
