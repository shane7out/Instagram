#!/bin/bash
# Add Taps & Barrels Beerhouse (@tapsandbarrelslv) - self-pour craft beer
# taproom, SW Las Vegas. Bar/pub -> dashboard_crec. IG-profile screenshot, so
# the handle goes on the record and no Bad IG flag.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json"          -o crec.json
curl -s "$DB/dashboard/customrecords.json" -o cust.json
curl -s "$DB/dashboard_exp_crec.json"      -o exp.json
BEFORE=$(jq 'keys|length' crec.json)
echo "crec before: $BEFORE"

if grep -qiE 'tapsandbarrelslv|taps[ _&-]*(and)?[ _&-]*barrels' crec.json cust.json exp.json; then
  echo "SKIP: already in db —"
  grep -oiE '.{0,90}taps[ _&-]*(and)?[ _&-]*barrels.{0,90}' crec.json cust.json exp.json | head -5
  exit 0
fi

NUM=$(jq '[.[]|.num?|numbers]|max' crec.json); NUM=$((NUM+1))
echo "assigning num $NUM"

curl -s -X PATCH -H "Content-Type: application/json" -d "{
  \"$NUM\": {
    \"name\": \"Taps & Barrels Beerhouse\",
    \"instagram\": \"@tapsandbarrelslv\",
    \"num\": $NUM,
    \"notes\": \"Manually added from IG profile screenshot - pub, self-pour craft beer taproom, 36 rotating draft taps, Southwest Las Vegas. Bio says 'Open now!' and their pinned reel claims first self-pour beerhouse in Vegas (301K views). 10.8K followers, 208 posts. Already follows the account. Runs trivia; food menu too. tapsbarrelslv.com\"
  }}" "$DB/dashboard_crec.json" > /dev/null

AFTER=$(curl -s "$DB/dashboard_crec.json" | jq 'keys|length')
echo "crec after: $AFTER  (was $BEFORE)"
curl -s "$DB/dashboard_crec/$NUM.json" | jq .
