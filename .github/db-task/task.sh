#!/bin/bash
# Add Sofra Taverna (@sofra_taverna) — Mediterranean/Balkan restaurant, Las Vegas.
# Restaurant -> dashboard_crec. IG-profile screenshot, so the handle goes on the
# record and no Bad IG flag.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json"          -o crec.json
curl -s "$DB/dashboard/customrecords.json" -o cust.json
curl -s "$DB/dashboard_exp_crec.json"      -o exp.json
BEFORE=$(jq 'keys|length' crec.json)
echo "crec before: $BEFORE"

if grep -qiE 'sofra_taverna|sofra[ _-]?taverna' crec.json cust.json exp.json; then
  echo "SKIP: already in db —"
  grep -oiE '.{0,90}sofra[ _-]?taverna.{0,90}' crec.json cust.json exp.json | head -5
  exit 0
fi

NUM=$(jq '[.[]|.num?|numbers]|max' crec.json); NUM=$((NUM+1))
echo "assigning num $NUM"

curl -s -X PATCH -H "Content-Type: application/json" -d "{
  \"$NUM\": {
    \"name\": \"Sofra Taverna\",
    \"instagram\": \"@sofra_taverna\",
    \"num\": $NUM,
    \"notes\": \"Manually added from IG profile screenshot - Mediterranean/Balkan restaurant, made-from-scratch Balkan recipes. Kebabs, beef shawarma pizza, burgers, dips. Sister cafe of @alchemycoffee_summerlin. Mon-Fri 11AM-9PM, Sat-Sun 10AM-8PM. 644 followers, 26 posts. sofratavernalv.com\"
  }}" "$DB/dashboard_crec.json" > /dev/null

AFTER=$(curl -s "$DB/dashboard_crec.json" | jq 'keys|length')
echo "crec after: $AFTER  (was $BEFORE)"
curl -s "$DB/dashboard_crec/$NUM.json" | jq .

# is the sister cafe already on file? (not adding it, just reporting)
echo "-- alchemycoffee_summerlin present? --"
grep -oiE '.{0,60}alchemy[ _-]?coffee.{0,60}' crec.json cust.json exp.json | head -3 || echo "not found in db"
