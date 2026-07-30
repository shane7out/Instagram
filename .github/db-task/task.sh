#!/bin/bash
# Yelp-migration batch: 20 restaurant candidates + 2 experiences
# (The Cromwell, ZAI Las Vegas).
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json" -o crec.json
curl -s "$DB/dashboard/customrecords.json" -o cust.json
curl -s "$DB/dashboard_exp_crec.json" -o exp.json
BEFORE=$(jq 'keys|length' crec.json)
NUM=$(jq '[.[]|.num?|numbers]|max' crec.json)
ENUM=$(jq '[.[]|.num?|numbers]|max' exp.json)
echo "start: crec=$BEFORE (max $NUM), exp max $ENUM"

add_rest() {
  local name="$1" pat="$2"
  if grep -qiE "$pat" crec.json || grep -qiE "$pat" cust.json; then
    echo "SKIP: $name"; return
  fi
  NUM=$((NUM+1))
  curl -s -X PATCH -H "Content-Type: application/json" \
    -d "{\"$NUM\":{\"name\":\"$name\",\"instagram\":\"\",\"num\":$NUM,\"notes\":\"Yelp migration - IG needed\"}}" \
    "$DB/dashboard_crec.json" > /dev/null
  curl -s -X PATCH -H "Content-Type: application/json" -d "{\"$NUM\":true}" "$DB/dashboard/badig.json" > /dev/null
  echo "ADDED: $name (num $NUM)"
}
add_exp() {
  local name="$1" pat="$2" note="$3"
  if grep -qiE "$pat" exp.json; then echo "SKIP (exp): $name"; return; fi
  ENUM=$((ENUM+1))
  curl -s -X PATCH -H "Content-Type: application/json" \
    -d "{\"$ENUM\":{\"name\":\"$name\",\"instagram\":\"\",\"num\":$ENUM,\"notes\":\"$note - IG needed (Yelp migration)\"}}" \
    "$DB/dashboard_exp_crec.json" > /dev/null
  echo "ADDED EXP: $name (num $ENUM)"
}

add_rest "Naked City Pizza" "naked ?city"
add_rest "Whats Zaap? Thai Food" "zaap"
add_rest "Jammyland" "jammyland"
add_rest "Papi Steak" "papi ?steak"
add_rest "S Bar Las Vegas" "\"s ?bar|sbarlv"
add_rest "Buddy Vs Ristorante" "buddy ?v"
add_rest "Bottiglia" "bottiglia"
add_rest "Proper Eats Food Hall" "proper ?eats"
add_rest "La Mona Rosa" "mona ?rosa"
add_rest "Luchini Italian Restaurant" "luchini"
add_rest "Krispy Krunchy Chicken at Shortline Express" "krispy ?krunchy"
add_rest "Ole Churros" "ole ?churros"
add_rest "Mint Indian Bistro" "mint ?indian"
add_rest "Carversteak" "carver ?steak|carversteak"
add_rest "Rumi Room Persian Indo-Pak Cuisine" "rumi ?room"
add_rest "Pier 88 Boiling Seafood & Bar" "pier ?88"
add_rest "Electra Cocktail Club" "electra"
add_rest "Little Avalon" "little ?avalon"
add_rest "Crazy Pita Rotisserie & Grill" "crazy ?pita"
add_rest "Rosallie Le French Cafe" "rosallie"
add_rest "Viva" "\"viva\""

add_exp "The Cromwell" "cromwell" "Boutique hotel & casino on the Strip"
add_exp "ZAI Las Vegas" "zai" "Cocktail bar & dance club on Fremont"

echo "final: crec $BEFORE -> $(curl -s "$DB/dashboard_crec.json" | jq 'keys|length'), exp $(curl -s "$DB/dashboard_exp_crec.json" | jq 'keys|length')"
