#!/bin/bash
# Yelp-migration rule: add missing place name-only + Bad IG flag.
# This round: Trap Wingz -> crec 50817, badig true.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json" -o crec.json
BEFORE=$(jq 'keys|length' crec.json)
if grep -qiE "trap ?wing" crec.json; then
  echo "GUARD: Trap Wingz already present - aborting"
  exit 1
fi
MAX=$(jq '[.[]|.num?|numbers]|max' crec.json)
if [ "$MAX" -ge 50817 ]; then
  echo "GUARD: num space moved (max=$MAX) - aborting"
  exit 1
fi

curl -s -X PATCH -H "Content-Type: application/json" \
  -d '{"50817":{"name":"Trap Wingz","instagram":"","num":50817,"notes":"Yelp migration - IG needed"}}' \
  "$DB/dashboard_crec.json" > /dev/null
curl -s -X PATCH -H "Content-Type: application/json" \
  -d '{"50817":true}' "$DB/dashboard/badig.json" > /dev/null

echo "record: $(curl -s "$DB/dashboard_crec/50817.json")"
echo "badig flag: $(curl -s "$DB/dashboard/badig/50817.json")"
echo "count: $BEFORE -> $(curl -s "$DB/dashboard_crec.json" | jq 'keys|length')"
