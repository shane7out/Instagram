#!/bin/bash
# Yelp-migration batch: 22 restaurant candidates + 2 experiences
# (After Las Vegas dance club, Arte Museum).
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

add_rest "Farm Basket" "farm ?basket"
add_rest "Taverna Costera" "costera"
add_rest "Lammys Bakehouse" "lammy"
add_rest "Mariposa Cocina & Cocktails" "mariposa"
add_rest "Borracha Mexican Cantina" "borracha"
add_rest "Le Thai" "le ?thai"
add_rest "CHICA" "chica[\", ]"
add_rest "Geos Tacos" "geo.?s ?tacos"
add_rest "Chin Chin" "chin ?chin"
add_rest "Scarpetta" "scarpetta"
add_rest "Servehzah Bottle Shop & Tap Room" "servehzah"
add_rest "The Sand Dollar Downtown" "sand ?dollar"
add_rest "Horse Trailer Hideout" "horse ?trailer"
add_rest "Broken Yolk Cafe" "broken ?yolk"
add_rest "Stallones Italian Eatery" "stallone"
add_rest "Mastros Ocean Club" "mastro"
add_rest "Stray Pirate" "stray ?pirate"
add_rest "Fugazzeta Pizza & Empanadas" "fugazzeta"
add_rest "Als Garage" "al.?s ?garage"
add_rest "Banchan" "banchan"
add_rest "WaBa Grill" "waba"
add_rest "Kase Sake & Sushi" "kase"

add_exp "After Las Vegas" "after ?las ?vegas" "Dance club on E Sahara"
add_exp "Arte Museum" "arte ?museum" "Immersive art museum on the Strip"

echo "final: crec $BEFORE -> $(curl -s "$DB/dashboard_crec.json" | jq 'keys|length'), exp $(curl -s "$DB/dashboard_exp_crec.json" | jq 'keys|length')"
