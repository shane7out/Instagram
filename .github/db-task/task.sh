#!/bin/bash
# Add The Irish Spot (@the.irish.spot) - Irish pub/bar & grill, Las Vegas.
# Restaurant/bar -> dashboard_crec. IG-profile screenshot, so the handle
# goes on the record and no Bad IG flag.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json"          -o crec.json
curl -s "$DB/dashboard/customrecords.json" -o cust.json
curl -s "$DB/dashboard_exp_crec.json"      -o exp.json
BEFORE=$(jq 'keys|length' crec.json)
echo "crec before: $BEFORE"

if grep -qiE 'the\.irish\.spot|irish[ _-]?spot' crec.json cust.json exp.json; then
  echo "SKIP: already in db —"
  grep -oiE '.{0,90}irish[ _-]?spot.{0,90}' crec.json cust.json exp.json | head -5
  exit 0
fi

NUM=$(jq '[.[]|.num?|numbers]|max' crec.json); NUM=$((NUM+1))
echo "assigning num $NUM"

curl -s -X PATCH -H "Content-Type: application/json" -d "{
  \"$NUM\": {
    \"name\": \"The Irish Spot\",
    \"instagram\": \"@the.irish.spot\",
    \"num\": $NUM,
    \"phone\": \"702-389-3808\",
    \"address\": \"1350 E Tropicana Ave, Las Vegas, NV\",
    \"notes\": \"Manually added from IG profile screenshot - Irish pub, bar & grill. Shows all Premier League games. Known for a huge fish n chips (viral reels, 6.9K-50.7K views). 5,802 followers, 96 posts. theirishspot.com\"
  }}" "$DB/dashboard_crec.json" > /dev/null

AFTER=$(curl -s "$DB/dashboard_crec.json" | jq 'keys|length')
echo "crec after: $AFTER  (was $BEFORE)"
curl -s "$DB/dashboard_crec/$NUM.json" | jq .
