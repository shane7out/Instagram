#!/bin/bash
# Add SUSHI MON - Sahara with IG handle (or fill handle if a Sahara record exists).
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
curl -s "$DB/dashboard_crec.json" -o crec.json
curl -s "$DB/dashboard/customrecords.json" -o cust.json
echo "existing sushi mon records:"
jq -c '[.[]|select((.name//"")|test("sushi ?mon";"i"))|{name,instagram,num}]' crec.json
jq -c '[.[]|select(((.name//""))|test("sushi ?mon";"i"))|{name,instagram}]' cust.json

# already a Sahara-specific record?
if grep -qiE "sushi ?mon.*sahara|sahara.*sushi ?mon" crec.json cust.json; then
  echo "SKIP: Sushi Mon Sahara already present"
  exit 0
fi
BEFORE=$(jq 'keys|length' crec.json)
NUM=$(jq '[.[]|.num?|numbers]|max' crec.json)
NUM=$((NUM+1))
curl -s -X PATCH -H "Content-Type: application/json" \
  -d "{\"$NUM\":{\"name\":\"Sushi Mon - Sahara\",\"instagram\":\"@sushimonsahara8320\",\"num\":$NUM,\"notes\":\"Manually added - AYCE sushi, 8320 W Sahara Ave\"}}" \
  "$DB/dashboard_crec.json" > /dev/null
echo "ADDED: Sushi Mon - Sahara (num $NUM)"
echo "count: $BEFORE -> $(curl -s "$DB/dashboard_crec.json" | jq 'keys|length')"
# r3
