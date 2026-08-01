#!/bin/bash
# Inspect what matched "malasada"; add Pipeline Malasadas only if it's a different shop.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json" -o crec.json
curl -s "$DB/dashboard/customrecords.json" -o cust.json
echo "crec matches:"
jq -c '[.[]|select((.name//"")+(.instagram//"")+(.notes//"")|test("malasada|pipeline";"i"))]' crec.json
echo "cust matches:"
jq -c '[.[]|select(((.name//"")+(.instagram//"")+(.notes//""))|test("malasada|pipeline";"i"))|{name,instagram}]' cust.json

if jq -e '[.[]|select((.name//"")+(.instagram//"")|test("pipeline";"i"))]|length>0' crec.json > /dev/null || \
   jq -e '[.[]|select(((.name//"")+(.instagram//""))|test("pipeline";"i"))]|length>0' cust.json > /dev/null; then
  echo "SKIP: Pipeline itself already in db"
  exit 0
fi
BEFORE=$(jq 'keys|length' crec.json)
NUM=$(jq '[.[]|.num?|numbers]|max' crec.json)
NUM=$((NUM+1))
curl -s -X PATCH -H "Content-Type: application/json" \
  -d "{\"$NUM\":{\"name\":\"Pipeline Malasadas\",\"instagram\":\"@pipelinemalasadas\",\"num\":$NUM,\"notes\":\"Manually added - Hawaiian malasada bakery/truck\"}}" \
  "$DB/dashboard_crec.json" > /dev/null
echo "ADDED: Pipeline Malasadas (num $NUM)"
echo "count: $BEFORE -> $(curl -s "$DB/dashboard_crec.json" | jq 'keys|length')"
