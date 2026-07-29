#!/bin/bash
# Yelp-migration rule: Sul & Beans, Vanderpump A Paris, Hola Habibi,
# Guieb Cafe, Lit Wings. Add missing as name-only + Bad IG.
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

add_if_missing "Sul & Beans" "sul.{0,3}beans"
add_if_missing "Vanderpump A Paris" "vanderpump.{0,4}paris"
grep -qiE "vanderpump" crec.json cust.json && echo "note: another Vanderpump venue exists in db" || true
add_if_missing "Hola Habibi" "hola ?habibi"
add_if_missing "Guieb Cafe" "guieb"
add_if_missing "Lit Wings" "lit ?wings"

echo "final count: $BEFORE -> $(curl -s "$DB/dashboard_crec.json" | jq 'keys|length')"
