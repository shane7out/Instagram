#!/bin/bash
# Add Tacos El Panzon with IG handle from screenshot.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
curl -s "$DB/dashboard_crec.json" -o crec.json
curl -s "$DB/dashboard/customrecords.json" -o cust.json
BEFORE=$(jq 'keys|length' crec.json)
if grep -qiE "el ?panzon|panz.n|tacoselpanzon" crec.json cust.json; then
  echo "SKIP: already in db"; exit 0
fi
NUM=$(jq '[.[]|.num?|numbers]|max' crec.json); NUM=$((NUM+1))
curl -s -X PATCH -H "Content-Type: application/json" \
  -d "{\"$NUM\":{\"name\":\"Tacos El Panzon\",\"instagram\":\"@tacoselpanzonlv\",\"num\":$NUM,\"notes\":\"Manually added - Tijuana-style tacos, N Las Vegas Blvd\"}}" \
  "$DB/dashboard_crec.json" > /dev/null
echo "ADDED: Tacos El Panzon (num $NUM)"
echo "count: $BEFORE -> $(curl -s "$DB/dashboard_crec.json" | jq 'keys|length')"
