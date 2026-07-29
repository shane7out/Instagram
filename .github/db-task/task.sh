#!/bin/bash
# Yelp-migration rule: check five places, add whichever are missing as
# name-only records with the Bad IG flag. Nums allocated from current max+1.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json" -o crec.json
curl -s "$DB/dashboard/customrecords.json" -o cust.json
BEFORE=$(jq 'keys|length' crec.json)
NUM=$(jq '[.[]|.num?|numbers]|max' crec.json)
echo "starting count=$BEFORE, max num=$NUM"

add_if_missing() {
  local name="$1" pat="$2"
  if grep -qiE "$pat" crec.json || grep -qiE "$pat" cust.json; then
    echo "SKIP (already in db): $name"
    return
  fi
  NUM=$((NUM+1))
  curl -s -X PATCH -H "Content-Type: application/json" \
    -d "{\"$NUM\":{\"name\":\"$name\",\"instagram\":\"\",\"num\":$NUM,\"notes\":\"Yelp migration - IG needed\"}}" \
    "$DB/dashboard_crec.json" > /dev/null
  curl -s -X PATCH -H "Content-Type: application/json" \
    -d "{\"$NUM\":true}" "$DB/dashboard/badig.json" > /dev/null
  echo "ADDED: $name (num $NUM, badig=$(curl -s "$DB/dashboard/badig/$NUM.json"))"
}

add_if_missing "Culichi Town" "culichi"
add_if_missing "Daikon Vegan Sushi" "daikon"
add_if_missing "China Mama Express" "china ?mama ?express"
grep -qiE "china ?mama" crec.json cust.json && echo "note: a 'China Mama' (non-Express) match exists somewhere" || true
add_if_missing "Alexis Park Resort" "alexis ?park"
add_if_missing "Lucino's Pizza" "lucino"

echo "final count: $BEFORE -> $(curl -s "$DB/dashboard_crec.json" | jq 'keys|length')"
