#!/bin/bash
# Yelp migration batch: IMG_7990-7992 (14 new candidates, all restaurants/bars/cafes).
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json" -o crec.json
curl -s "$DB/dashboard/customrecords.json" -o cust.json
BEFORE=$(jq 'keys|length' crec.json)
NUM=$(jq '[.[]|.num?|numbers]|max' crec.json)
echo "start: crec=$BEFORE (max $NUM)"

add_rest() {
  local name="$1" pat="$2"
  if grep -qiE "$pat" crec.json || grep -qiE "$pat" cust.json; then
    echo "SKIP: $name"
    return
  fi
  NUM=$((NUM+1))
  local jname
  jname=$(printf '%s' "$name" | sed 's/"/\\"/g')
  curl -s -X PATCH -H "Content-Type: application/json" \
    -d "{\"$NUM\":{\"name\":\"$jname\",\"instagram\":\"\",\"num\":$NUM,\"notes\":\"Yelp migration - IG needed\"}}" \
    "$DB/dashboard_crec.json" > /dev/null
  curl -s -X PATCH -H "Content-Type: application/json" -d "{\"$NUM\":true}" "$DB/dashboard/badig.json" > /dev/null
  echo "ADDED: $name (num $NUM)"
}

add_rest "Squeeze In" "squeeze ?in"
add_rest "Mo' Bettahs Hawaiian Style Food" "mo.? ?bettah"
add_rest "Smokints BBQ & Bar" "smokint"
add_rest "Public Works Coffee" "public ?works"
add_rest "Cloud Tea" "cloud ?tea|clouffee"
add_rest "Baguette Cafe" "baguette ?cafe"
add_rest "Sultans Wagyu Grill" "sultan"
add_rest "Hattie Marie's Texas BBQ" "hattie"
add_rest "Oscar's Steakhouse" "oscar.?s ?steak"
add_rest "Rock N' Potato" "rock ?n.? ?potato"
add_rest "Aware Coffee" "aware ?coffee"
add_rest "Yu-Or-Mi" "yu.?or.?mi"
add_rest "Yu or Mi Sushi" "yu.?or.?mi ?sushi"
add_rest "Galpao Gaucho Brazilian Steakhouse" "galp|gaucho"

echo "final: crec $BEFORE -> $(curl -s "$DB/dashboard_crec.json" | jq 'keys|length')"
