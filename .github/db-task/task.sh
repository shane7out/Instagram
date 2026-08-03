#!/bin/bash
# Yelp migration batch: IMG_8009-8011 (13 restaurants + 2 experiences).
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

add_rest "Houston TX Hot Chicken" "houston ?tx|houston.{0,10}chicken"
add_rest "Cabo Wabo Cantina" "cabo ?wabo"
add_rest "Top Sushi & Oyster" "top ?sushi"
add_rest "Tacos Los Barrios" "los ?barrios"
add_rest "La Casita De Dona Machi" "casita|do.?a ?machi"
add_rest "Poke Market" "poke ?market"
add_rest "Chef's Roma Kitchen" "roma ?kitchen"
add_rest "Pizza Rock" "pizza ?rock"
add_rest "Locals Hawaiian Style Poke" "locals ?hawaiian"
add_rest "Lost Sweets" "lost ?sweets"
add_rest "Japaneiro" "japaneiro"
add_rest "Ferraro's Ristorante" "ferraro"
add_rest "Umezono Sushi and Japanese Grill" "umezono"
add_exp "Home2 Suites by Hilton I-215 Curve" "home ?2 ?suites|home2" "Hotel"
add_exp "Ganzy Karaoke" "ganzy" "Karaoke bar on S Rainbow"

echo "final: crec $BEFORE -> $(curl -s "$DB/dashboard_crec.json" | jq 'keys|length'), exp $(curl -s "$DB/dashboard_exp_crec.json" | jq 'keys|length')"
