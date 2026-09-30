#!/bin/bash
# Add French Riviera Tropezienne Bakery - Bistrot (@frenchrivierabakery) -
# French bakery/bistro, downtown Las Vegas. Restaurant -> dashboard_crec.
# IG-profile screenshot, so the handle goes on the record and no Bad IG flag.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json"          -o crec.json
curl -s "$DB/dashboard/customrecords.json" -o cust.json
curl -s "$DB/dashboard_exp_crec.json"      -o exp.json
BEFORE=$(jq 'keys|length' crec.json)
echo "crec before: $BEFORE"

if grep -qiE 'frenchrivierabakery|french[ _-]?riviera' crec.json cust.json exp.json; then
  echo "SKIP: already in db —"
  grep -oiE '.{0,90}french[ _-]?riviera.{0,90}' crec.json cust.json exp.json | head -5
  exit 0
fi

NUM=$(jq '[.[]|.num?|numbers]|max' crec.json); NUM=$((NUM+1))
echo "assigning num $NUM"

curl -s -X PATCH -H "Content-Type: application/json" -d "{
  \"$NUM\": {
    \"name\": \"French Riviera Tropezienne Bakery - Bistrot\",
    \"instagram\": \"@frenchrivierabakery\",
    \"num\": $NUM,
    \"address\": \"401 S 6th St, Las Vegas, NV\",
    \"notes\": \"Manually added from IG profile screenshot - French bakery and bistro, downtown Las Vegas. New French bistro, dinner Thursday-Saturday 6-10pm. Tropezienne pastries, mussels, steak frites. 8,615 followers, 565 posts. frenchrivieravegas.com\"
  }}" "$DB/dashboard_crec.json" > /dev/null

AFTER=$(curl -s "$DB/dashboard_crec.json" | jq 'keys|length')
echo "crec after: $AFTER  (was $BEFORE)"
curl -s "$DB/dashboard_crec/$NUM.json" | jq .
