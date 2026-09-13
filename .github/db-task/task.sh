#!/bin/bash
# Add Maiz Mama (@maizmamalv) - fast-casual Mexican, newly opened in Las Vegas.
# Restaurant -> dashboard_crec. IG-profile screenshot, so the handle goes on the
# record and no Bad IG flag.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json"          -o crec.json
curl -s "$DB/dashboard/customrecords.json" -o cust.json
curl -s "$DB/dashboard_exp_crec.json"      -o exp.json
BEFORE=$(jq 'keys|length' crec.json)
echo "crec before: $BEFORE"

if grep -qiE 'maizmamalv|maiz[ _-]?mama' crec.json cust.json exp.json; then
  echo "SKIP: already in db —"
  grep -oiE '.{0,90}maiz[ _-]?mama.{0,90}' crec.json cust.json exp.json | head -5
  exit 0
fi

NUM=$(jq '[.[]|.num?|numbers]|max' crec.json); NUM=$((NUM+1))
echo "assigning num $NUM"

curl -s -X PATCH -H "Content-Type: application/json" -d "{
  \"$NUM\": {
    \"name\": \"Maiz Mama\",
    \"instagram\": \"@maizmamalv\",
    \"num\": $NUM,
    \"notes\": \"Manually added from IG profile screenshot - NEWLY OPENED, bio says 'NOW OPEN IN VEGAS'. Fast-casual Mexican: handmade tortillas, trompo-roasted meats, customizable tacos, bowls, burritos. Only 11 posts / 370 followers, so very early - good timing for outreach. maizmama.com\"
  }}" "$DB/dashboard_crec.json" > /dev/null

AFTER=$(curl -s "$DB/dashboard_crec.json" | jq 'keys|length')
echo "crec after: $AFTER  (was $BEFORE)"
curl -s "$DB/dashboard_crec/$NUM.json" | jq .
