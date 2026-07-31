#!/bin/bash
# Add Gabriels Kitchen Las Vegas with IG handle from screenshot.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json" -o crec.json
curl -s "$DB/dashboard/customrecords.json" -o cust.json
BEFORE=$(jq 'keys|length' crec.json)
if grep -qiE "gabriel.?s ?kitchen|north ?end ?pizza|gabrielskitchen" crec.json cust.json; then
  echo "SKIP: already in db"
  exit 0
fi
NUM=$(jq '[.[]|.num?|numbers]|max' crec.json)
NUM=$((NUM+1))
curl -s -X PATCH -H "Content-Type: application/json" \
  -d "{\"$NUM\":{\"name\":\"Gabriels Kitchen Las Vegas\",\"instagram\":\"@gabrielskitchenlasvegas\",\"num\":$NUM,\"notes\":\"Manually added - Boston style pizzeria (North End Pizza)\"}}" \
  "$DB/dashboard_crec.json" > /dev/null
echo "ADDED: Gabriels Kitchen Las Vegas (num $NUM)"
echo "record: $(curl -s "$DB/dashboard_crec/$NUM.json")"
echo "count: $BEFORE -> $(curl -s "$DB/dashboard_crec.json" | jq 'keys|length')"
