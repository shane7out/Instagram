#!/bin/bash
# Yelp-migration batch: 18 restaurant candidates + The Venetian (exp).
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
  local n
  n=$(jq --arg p "$pat" '[.[]|select((.name//"")|test($p;"i"))]|length' exp.json)
  if [ "$n" != "0" ]; then echo "SKIP (exp): $name"; return; fi
  ENUM=$((ENUM+1))
  curl -s -X PATCH -H "Content-Type: application/json" \
    -d "{\"$ENUM\":{\"name\":\"$name\",\"instagram\":\"\",\"num\":$ENUM,\"notes\":\"$note - IG needed (Yelp migration)\"}}" \
    "$DB/dashboard_exp_crec.json" > /dev/null
  echo "ADDED EXP: $name (num $ENUM)"
}

add_rest "Kona Bros Coffee" "kona ?bros"
add_rest "Pizza Pie Guy" "pizza ?pie ?guy"
add_rest "Early Birds - A Breakfast Spot" "early ?birds"
add_rest "Ohjah Japanese Steakhouse" "ohjah ?japanese"
add_rest "Ohjah Noodle House" "ohjah ?noodle"
add_rest "Joe Vicaris Andiamo Steakhouse" "andiamo"
add_rest "Guido Pie" "guido ?pie"
add_rest "Goong Korean BBQ" "goong"
add_rest "Aspire Coffee House" "aspire ?coffee"
add_rest "Island Fin Poke" "island ?fin"
add_rest "Strip House Steakhouse" "strip ?house"
add_rest "SEVEN:45" "seven.?45"
add_rest "Jeremiahs Italian Ice" "jeremiah"
add_rest "Main St Provisions" "provisions"
add_rest "Pot Master Street Food" "pot ?master"
add_rest "Bacon Nation" "bacon ?nation"
add_rest "Hwaro 2" "hwaro"
add_rest "Panpanccs" "panpancc"
add_rest "Broadway Burger Bar and Grill" "broadway ?burger"

add_exp "The Venetian Resort" "venetian" "Strip resort & casino"

echo "final: crec $BEFORE -> $(curl -s "$DB/dashboard_crec.json" | jq 'keys|length'), exp $(curl -s "$DB/dashboard_exp_crec.json" | jq 'keys|length')"
