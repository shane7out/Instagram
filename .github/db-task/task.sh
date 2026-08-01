#!/bin/bash
# Add Pipeline Malasadas with IG handle from screenshot.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json" -o crec.json
curl -s "$DB/dashboard/customrecords.json" -o cust.json
BEFORE=$(jq 'keys|length' crec.json)
if grep -qiE "pipeline ?malasada|malasada" crec.json cust.json; then
  echo "SKIP: already in db"
  exit 0
fi
NUM=$(jq '[.[]|.num?|numbers]|max' crec.json)
NUM=$((NUM+1))
curl -s -X PATCH -H "Content-Type: application/json" \
  -d "{\"$NUM\":{\"name\":\"Pipeline Malasadas\",\"instagram\":\"@pipelinemalasadas\",\"num\":$NUM,\"notes\":\"Manually added - Hawaiian malasada bakery/truck\"}}" \
  "$DB/dashboard_crec.json" > /dev/null
echo "ADDED: Pipeline Malasadas (num $NUM)"
echo "record: $(curl -s "$DB/dashboard_crec/$NUM.json")"
echo "count: $BEFORE -> $(curl -s "$DB/dashboard_crec.json" | jq 'keys|length')"
