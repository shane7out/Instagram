#!/bin/bash
# Yelp migration batch: IMG_8072 (5 restaurants/bars/cafes).
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
curl -s "$DB/dashboard_crec.json" -o crec.json
curl -s "$DB/dashboard/customrecords.json" -o cust.json
BEFORE=$(jq 'keys|length' crec.json)
NUM=$(jq '[.[]|.num?|numbers]|max' crec.json)
echo "start: crec=$BEFORE (max $NUM)"

add_rest() {
  local name="$1" pat="$2"
  if grep -qiE "$pat" crec.json || grep -qiE "$pat" cust.json; then echo "SKIP: $name"; return; fi
  NUM=$((NUM+1))
  local jname; jname=$(printf '%s' "$name" | sed 's/"/\\"/g')
  curl -s -X PATCH -H "Content-Type: application/json" \
    -d "{\"$NUM\":{\"name\":\"$jname\",\"instagram\":\"\",\"num\":$NUM,\"notes\":\"Yelp migration - IG needed\"}}" \
    "$DB/dashboard_crec.json" > /dev/null
  curl -s -X PATCH -H "Content-Type: application/json" -d "{\"$NUM\":true}" "$DB/dashboard/badig.json" > /dev/null
  echo "ADDED: $name (num $NUM)"
}

add_rest "Easy's Cocktail Lounge" "easy.?s ?cocktail"
add_rest "Lucy's Waffles & Ice Cream" "lucy.?s ?waffles"
add_rest "Vesta Coffee Roasters" "vesta ?coffee"
add_rest "Chatos Tacos" "chatos"
add_rest "Humo Barbecue" "humo ?barbe"

echo "final: crec $BEFORE -> $(curl -s "$DB/dashboard_crec.json" | jq 'keys|length')"
