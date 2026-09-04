#!/bin/bash
# Add Santa Fe Station (@santafestationlv) — casino property in NW Las Vegas.
# Casino/hotel/attraction -> dashboard_exp_crec. IG-profile screenshot, so the
# handle goes on the record and no Bad IG flag.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_exp_crec.json" -o exp.json
curl -s "$DB/dashboard_crec.json"     -o crec.json
curl -s "$DB/dashboard/customrecords.json" -o cust.json
BEFORE=$(jq 'keys|length' exp.json)
echo "exp_crec before: $BEFORE"

if grep -qiE 'santafestationlv|santa[ _-]?fe[ _-]?station' exp.json crec.json cust.json; then
  echo "SKIP: already in db —"
  grep -oiE '.{0,90}santa[ _-]?fe[ _-]?station.{0,90}' exp.json crec.json cust.json | head -5
  exit 0
fi

NUM=$(jq '[.[]|.num?|numbers]|max' exp.json); NUM=$((NUM+1))
echo "assigning num $NUM"

curl -s -X PATCH -H "Content-Type: application/json" -d "{
  \"$NUM\": {
    \"name\": \"Santa Fe Station\",
    \"instagram\": \"@santafestationlv\",
    \"num\": $NUM,
    \"notes\": \"Manually added from IG profile screenshot - casino, NW Las Vegas. Gaming, dining, bowling, movies, concerts. On-site: The Brass Fork, Stoney's North Forty. 40.2K followers, 844 posts. santafestation.com\"
  }}" "$DB/dashboard_exp_crec.json" > /dev/null

AFTER=$(curl -s "$DB/dashboard_exp_crec.json" | jq 'keys|length')
echo "exp_crec after: $AFTER  (was $BEFORE)"
curl -s "$DB/dashboard_exp_crec/$NUM.json" | jq .
