#!/bin/bash
# Yelp migration batch: IMG_8024-8028 (25 candidates, all restaurants/bars/cafes).
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
    echo "SKIP: $name"; return
  fi
  NUM=$((NUM+1))
  local jname; jname=$(printf '%s' "$name" | sed 's/"/\\"/g')
  curl -s -X PATCH -H "Content-Type: application/json" \
    -d "{\"$NUM\":{\"name\":\"$jname\",\"instagram\":\"\",\"num\":$NUM,\"notes\":\"Yelp migration - IG needed\"}}" \
    "$DB/dashboard_crec.json" > /dev/null
  curl -s -X PATCH -H "Content-Type: application/json" -d "{\"$NUM\":true}" "$DB/dashboard/badig.json" > /dev/null
  echo "ADDED: $name (num $NUM)"
}

add_rest "Other Mama" "other ?mama"
add_rest "Signora Pizza" "signora"
add_rest "Pampas" "\"pampas"
add_rest "Pacific Island Taste" "pacific ?island"
add_rest "The Library" "the library"
add_rest "The Smashed Pig Gastropub" "smashed ?pig"
add_rest "Ghost Donkey" "ghost ?donkey"
add_rest "Angry Crab Shack" "angry ?crab"
add_rest "Rang's Cocina Moderne" "rang.?s ?cocina"
add_rest "Blue Martini" "blue ?martini"
add_rest "Salt & Ivy" "salt .{0,3}ivy"
add_rest "The Palace Station Oyster Bar" "palace station oyster"
add_rest "Alexxa's" "alexxa"
add_rest "HaSalon" "hasalon"
add_rest "Makers & Finders" "makers .{0,3}finders"
add_rest "Jaleo" "\"jaleo"
add_rest "Table Thai Bar & Bistro" "table ?thai"
add_rest "Brooklyn's Best Pizza & Pasta" "brooklyn.?s ?best"
add_rest "Anima by Edo" "anima ?by ?edo"
add_rest "Kabob Grill" "kabob ?grill"
add_rest "Aloha Mamacita" "aloha ?mamacita"
add_rest "The Nori" "\"the nori|>the nori"
add_rest "Griddlecakes" "griddlecake"
add_rest "Stephano's Greek & Mediterranean Grill" "stephano"
add_rest "SoyMexican Veggie-Vegan Eatery" "soy ?mexican"

echo "final: crec $BEFORE -> $(curl -s "$DB/dashboard_crec.json" | jq 'keys|length')"
