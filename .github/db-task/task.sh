#!/bin/bash
# Add Wholesale Classic Cars (car dealership) to dashboard_adv_crec.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_adv_crec.json" -o adv.json
BEFORE=$(jq 'keys|length' adv.json)
echo "start: adv=$BEFORE"
echo "sample record: $(jq -c 'to_entries|.[0]' adv.json)"

if grep -qiE "wholesale ?classic|classic ?car" adv.json; then
  echo "SKIP: already in adv_crec"
  exit 0
fi

NUM=$(jq '[.[]|.num?|numbers]|max' adv.json)
NUM=$((NUM+1))
curl -s -X PATCH -H "Content-Type: application/json" \
  -d "{\"$NUM\":{\"cat\":\"Auto Dealer\",\"email\":\"\",\"ig\":\"\",\"name\":\"Wholesale Classic Cars\",\"num\":$NUM}}" \
  "$DB/dashboard_adv_crec.json" > /dev/null
echo "ADDED: Wholesale Classic Cars (num $NUM)"
echo "record: $(curl -s "$DB/dashboard_adv_crec/$NUM.json")"
echo "final: adv $BEFORE -> $(curl -s "$DB/dashboard_adv_crec.json" | jq 'keys|length')"
