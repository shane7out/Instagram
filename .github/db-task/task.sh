#!/bin/bash
# Add El Rey to dashboard_crec (num 50815). Same schema and guards.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json" -o crec.json
BEFORE=$(jq 'keys|length' crec.json)
if grep -qi "elreylasvegas" crec.json; then
  echo "GUARD: elreylasvegas already present - aborting with no writes"
  exit 1
fi

MAX=$(jq '[.[]|.num?|numbers]|max' crec.json)
if [ "$MAX" -ge 50815 ]; then
  echo "GUARD: num space moved (max=$MAX) - aborting, needs fresh look"
  exit 1
fi

curl -s -X PATCH -H "Content-Type: application/json" \
  -d '{"50815":{"name":"El Rey","instagram":"@elreylasvegas","num":50815,"notes":"Manually added"}}' \
  "$DB/dashboard_crec.json" > /dev/null

curl -s "$DB/dashboard_crec.json" -o crec2.json
echo "== record count before/after =="
echo "$BEFORE -> $(jq 'keys|length' crec2.json)"
if grep -qi "elreylasvegas" crec2.json; then echo "elreylasvegas: IN the database"; else echo "elreylasvegas: MISSING"; fi
