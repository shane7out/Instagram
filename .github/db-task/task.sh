#!/bin/bash
# Add Mt. Charleston Lodge with IG handle from screenshot.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json" -o crec.json
curl -s "$DB/dashboard/customrecords.json" -o cust.json
BEFORE=$(jq 'keys|length' crec.json)
if grep -qiE "charleston ?lodge" crec.json cust.json; then
  echo "SKIP: already in db"
  exit 0
fi
NUM=$(jq '[.[]|.num?|numbers]|max' crec.json)
NUM=$((NUM+1))
curl -s -X PATCH -H "Content-Type: application/json" \
  -d "{\"$NUM\":{\"name\":\"Mt. Charleston Lodge\",\"instagram\":\"@mtcharlestonlodgelv\",\"num\":$NUM,\"notes\":\"Manually added - Pine Dining restaurant at the lodge\"}}" \
  "$DB/dashboard_crec.json" > /dev/null
echo "ADDED: Mt. Charleston Lodge (num $NUM)"
echo "record: $(curl -s "$DB/dashboard_crec/$NUM.json")"
echo "count: $BEFORE -> $(curl -s "$DB/dashboard_crec.json" | jq 'keys|length')"
