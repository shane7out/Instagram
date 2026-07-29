#!/bin/bash
# Yelp-migration mega batch: 22 restaurant candidates + 2 experiences
# (Shops at Crystals, Drai's Nightclub). Sparrow + Wolf already built-in.
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

add_rest "Tous Les Jours" "tous ?les ?jours"
add_rest "Born And Raised" "born ?and ?raised"
add_rest "Rosa Mexicano" "rosa ?mexicano"
add_rest "Slice House by Tony Gemignani" "slice ?house"
add_rest "Cheese and Grace" "cheese ?and ?grace"
add_rest "Lady M Cake Boutique" "lady ?m ?cake|ladym"
add_rest "Jason Aldeans Kitchen + Bar" "jason ?aldean"
add_rest "Paina Cafe" "paina"
add_rest "Brooklyns Best Pizza & Pasta" "brooklyn.?s ?best"
add_rest "Mother Wolf" "mother ?wolf"
add_rest "Fishers Deli" "fisher.?s ?deli"
add_rest "STK Steakhouse" "stk ?steak|eatstk|stklasvegas"
add_rest "Halgatteok" "halgatteok"
add_rest "ShangHai Taste" "shanghai ?taste"
add_rest "Waffles Cafe" "waffles ?cafe"
add_rest "Big Mamas Wings & Things" "big ?mamas? ?wings"
add_rest "McMullans Irish Pub" "mcmullan"
add_rest "Birria - Bite los Arcos" "bite ?los ?arcos"
add_rest "Hello Hibachi" "hello ?hibachi"
add_rest "702 Prep" "702 ?prep"
add_rest "Bar Boheme" "bar ?boheme"
add_rest "Carlitros Mariscos" "carlitros"

add_exp "The Shops at Crystals" "crystals" "Luxury shopping center on the Strip"
add_exp "Drais Nightclub" "drai.?s" "Rooftop nightclub at The Cromwell"

echo "final: crec $BEFORE -> $(curl -s "$DB/dashboard_crec.json" | jq 'keys|length'), exp $(curl -s "$DB/dashboard_exp_crec.json" | jq 'keys|length')"
