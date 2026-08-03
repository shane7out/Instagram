#!/bin/bash
# Yelp migration batch: IMG_7993-7997 (24 candidates; OMNIA -> experiences; 888 Sushi has IG handle).
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

add_rest_ig() {
  local name="$1" pat="$2" ig="$3"
  if grep -qiE "$pat" crec.json || grep -qiE "$pat" cust.json; then
    echo "SKIP: $name"
    return
  fi
  NUM=$((NUM+1))
  curl -s -X PATCH -H "Content-Type: application/json" \
    -d "{\"$NUM\":{\"name\":\"$name\",\"instagram\":\"$ig\",\"num\":$NUM,\"notes\":\"Yelp migration\"}}" \
    "$DB/dashboard_crec.json" > /dev/null
  echo "ADDED+IG: $name (num $NUM, $ig)"
}

add_exp() {
  local name="$1" pat="$2" note="$3"
  local n
  n=$(jq --arg p "$pat" '[.[]|select((.name//"")|test($p;"i"))]|length' exp.json)
  if [ "$n" != "0" ]; then echo "SKIP (exp): $name"; return; fi
  ENUM=$((ENUM+1))
  curl -s -X PATCH -H "Content-Type: application/json" \
    -d "{\"$ENUM\":{\"name\":\"$name\",\"instagram\":\"\",\"num\":$ENUM,\"notes\":\"$note - IG needed (Yelp migration)\"}}" \
    "$DB/dashboard_exp_crec.json" > /dev/null
  echo "ADDED EXP: $name (num $ENUM)"
}

add_rest "Michael Mina" "michael ?mina"
add_rest "Kaiseki Yuzu" "kaiseki|yuzu"
add_rest "Almond & Oat Coffee Bar" "almond"
add_rest "Antidote LV" "antidote"
add_rest "Rouge Room" "rouge ?room"
add_rest "El Taco" "\"el taco"
add_rest "Bourbon Steak by Michael Mina" "bourbon ?steak"
add_rest "Broken Coffee" "broken ?coffee"
add_rest "Netflix Bites" "netflix"
add_rest_ig "888 Sushi and Robata" "888 ?sushi|888sushirobata" "@888sushirobata"
add_rest "Gorilla Korean Grill" "gorilla"
add_rest "Juan's Flaming Fajitas & Cantina" "juan.?s ?flaming|flaming ?fajita"
add_rest "Q Bistro" "q ?bistro"
add_rest "Lawry's The Prime Rib" "lawry"
add_rest "Tim Ho Wan" "tim ?ho ?wan"
add_rest "Golden Steer Steakhouse" "golden ?steer"
add_rest "Lavo" "\blavo\b"
add_rest "Bruster's Real Ice Cream" "bruster"
add_rest "Del Frisco's Double Eagle Steakhouse" "del ?frisco"
add_rest "Caspian's Rock & Roe" "caspian"
add_rest "Emmitt's Vegas" "emmitt"
add_rest "Sugar Factory Las Vegas" "sugar ?factory"
add_rest "Fiorella" "fiorella"
add_exp "OMNIA Nightclub" "omnia" "Nightclub at Caesars Palace"

echo "final: crec $BEFORE -> $(curl -s "$DB/dashboard_crec.json" | jq 'keys|length'), exp $(curl -s "$DB/dashboard_exp_crec.json" | jq 'keys|length')"
