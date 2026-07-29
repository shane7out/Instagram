#!/bin/bash
# Judgment call: move Alexis Park Resort (crec 50819) to LV Experiences
# (exp 60008), clear its badig flag, PATCH-null the crec record.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

REC=$(curl -s "$DB/dashboard_crec/50819.json")
echo "crec 50819: $REC"
if [ "$REC" = "null" ]; then
  echo "already moved or absent - nothing to do"
  exit 0
fi

curl -s -X PATCH -H "Content-Type: application/json" \
  -d '{"60008":{"name":"Alexis Park Resort","instagram":"","num":60008,"notes":"Resort & event spaces - IG needed (Yelp migration)"}}' \
  "$DB/dashboard_exp_crec.json" > /dev/null
echo "added to experiences as 60008"

curl -s -X PATCH -H "Content-Type: application/json" -d '{"50819":null}' "$DB/dashboard_crec.json" > /dev/null
curl -s -X PATCH -H "Content-Type: application/json" -d '{"50819":null}' "$DB/dashboard/badig.json" > /dev/null

echo "crec 50819 now: $(curl -s "$DB/dashboard_crec/50819.json")"
echo "badig 50819 now: $(curl -s "$DB/dashboard/badig/50819.json")"
echo "experiences count: $(curl -s "$DB/dashboard_exp_crec.json" | jq 'keys|length')"
echo "restaurant count: $(curl -s "$DB/dashboard_crec.json" | jq 'keys|length')"
