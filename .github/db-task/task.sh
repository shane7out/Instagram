#!/bin/bash
# Add Liquid Diet (@liquid.diet.dtlv) - speakeasy cocktail bar, Las Vegas Arts
# District. Bar -> dashboard_crec. IG-profile screenshot, so the handle goes
# on the record and no Bad IG flag.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json"          -o crec.json
curl -s "$DB/dashboard/customrecords.json" -o cust.json
curl -s "$DB/dashboard_exp_crec.json"      -o exp.json
BEFORE=$(jq 'keys|length' crec.json)
echo "crec before: $BEFORE"

if grep -qiE 'liquid\.diet\.dtlv|liquid[ _-]?diet' crec.json cust.json exp.json; then
  echo "SKIP: already in db —"
  grep -oiE '.{0,90}liquid[ _-]?diet.{0,90}' crec.json cust.json exp.json | head -5
  exit 0
fi

NUM=$(jq '[.[]|.num?|numbers]|max' crec.json); NUM=$((NUM+1))
echo "assigning num $NUM"

curl -s -X PATCH -H "Content-Type: application/json" -d "{
  \"$NUM\": {
    \"name\": \"Liquid Diet\",
    \"instagram\": \"@liquid.diet.dtlv\",
    \"num\": $NUM,
    \"notes\": \"Manually added from IG profile screenshot - hidden speakeasy cocktail bar, Arts District. Found in the alley between Commerce and Main, just south of Imperial. Open Weds-Sun 5pm-1am. Craft cocktail program (liquid nitrogen presentations, fresh fruit). Turned 3 years old (event Sept 13, new merch/DJ). 7,447 followers, 71 posts.\"
  }}" "$DB/dashboard_crec.json" > /dev/null

AFTER=$(curl -s "$DB/dashboard_crec.json" | jq 'keys|length')
echo "crec after: $AFTER  (was $BEFORE)"
curl -s "$DB/dashboard_crec/$NUM.json" | jq .
