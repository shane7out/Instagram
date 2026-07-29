#!/bin/bash
# Add Wok To Walk: name only (no address, no IG), and flag it Bad IG.
# Record -> dashboard_crec/50816; flag -> dashboard/badig/50816 = true
# (per-key write, matching the dashboard's own badIGMap sync).
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json" -o crec.json
BEFORE=$(jq 'keys|length' crec.json)
if grep -qiE "wok ?to ?walk" crec.json; then
  echo "GUARD: Wok To Walk already present - aborting with no writes"
  exit 1
fi
MAX=$(jq '[.[]|.num?|numbers]|max' crec.json)
if [ "$MAX" -ge 50816 ]; then
  echo "GUARD: num space moved (max=$MAX) - aborting"
  exit 1
fi

curl -s -X PATCH -H "Content-Type: application/json" \
  -d '{"50816":{"name":"Wok To Walk","instagram":"","num":50816,"notes":"Manually added - no IG found"}}' \
  "$DB/dashboard_crec.json" > /dev/null

curl -s -X PATCH -H "Content-Type: application/json" \
  -d '{"50816":true}' "$DB/dashboard/badig.json" > /dev/null

echo "record: $(curl -s "$DB/dashboard_crec/50816.json")"
echo "badig flag: $(curl -s "$DB/dashboard/badig/50816.json")"
echo "count: $BEFORE -> $(curl -s "$DB/dashboard_crec.json" | jq 'keys|length')"
