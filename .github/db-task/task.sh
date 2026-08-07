#!/bin/bash
# Add Chubby's Pub with IG handle from IG-profile screenshot.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
curl -s "$DB/dashboard_crec.json" -o crec.json
curl -s "$DB/dashboard/customrecords.json" -o cust.json
BEFORE=$(jq 'keys|length' crec.json)
if grep -qiE "chubby.?s ?pub|chubbyspub" crec.json cust.json; then
  echo "SKIP: already in db"; exit 0
fi
NUM=$(jq '[.[]|.num?|numbers]|max' crec.json); NUM=$((NUM+1))
curl -s -X PATCH -H "Content-Type: application/json" \
  -d "{\"$NUM\":{\"name\":\"Chubby's Pub\",\"instagram\":\"@chubbyspublv\",\"num\":$NUM,\"notes\":\"Manually added - neighborhood bar/pub, Las Vegas\"}}" \
  "$DB/dashboard_crec.json" > /dev/null
echo "ADDED: Chubby's Pub (num $NUM)"
echo "count: $BEFORE -> $(curl -s "$DB/dashboard_crec.json" | jq 'keys|length')"
