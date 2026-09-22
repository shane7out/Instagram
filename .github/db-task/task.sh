#!/bin/bash
# Add Don Rice Bar (@donricebar) - Japanese donburi bowl restaurant, Las Vegas.
# Restaurant -> dashboard_crec. IG-profile screenshot, so the handle goes on
# the record and no Bad IG flag.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json"          -o crec.json
curl -s "$DB/dashboard/customrecords.json" -o cust.json
curl -s "$DB/dashboard_exp_crec.json"      -o exp.json
BEFORE=$(jq 'keys|length' crec.json)
echo "crec before: $BEFORE"

if grep -qiE 'donricebar|don[ _-]?rice[ _-]?bar' crec.json cust.json exp.json; then
  echo "SKIP: already in db —"
  grep -oiE '.{0,90}don[ _-]?rice[ _-]?bar.{0,90}' crec.json cust.json exp.json | head -5
  exit 0
fi

NUM=$(jq '[.[]|.num?|numbers]|max' crec.json); NUM=$((NUM+1))
echo "assigning num $NUM"

curl -s -X PATCH -H "Content-Type: application/json" -d "{
  \"$NUM\": {
    \"name\": \"Don Rice Bar\",
    \"instagram\": \"@donricebar\",
    \"num\": $NUM,
    \"notes\": \"Manually added from IG profile screenshot - traditional Japanese donburi bowls. Open daily 11am-9pm. Multiple Las Vegas locations. 2,057 followers, 51 posts. donricebar.com\"
  }}" "$DB/dashboard_crec.json" > /dev/null

AFTER=$(curl -s "$DB/dashboard_crec.json" | jq 'keys|length')
echo "crec after: $AFTER  (was $BEFORE)"
curl -s "$DB/dashboard_crec/$NUM.json" | jq .
