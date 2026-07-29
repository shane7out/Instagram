#!/bin/bash
# Yelp-migration batch 2 of the big sweep: 23 restaurant candidates +
# 1 experience (Miss Behaves Mavericks). Carrot & Daikon skipped (California).
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

add_rest "Finesse Catering and Events" "finesse ?catering"
add_rest "The Great Greek Mediterranean Grill" "great ?greek"
add_rest "The Pinky Ring by Bruno Mars" "pinky ?ring"
add_rest "Cafe Landwer" "landwer"
add_rest "Pups and Cups Coffee" "pups ?(and|&)? ?cups"
add_rest "Las Vegas Custom Cakes" "vegas ?custom ?cakes"
add_rest "Siempre J.B." "siempre"
add_rest "Echo - Taste & Sound" "taste ?& ?sound|taste ?and ?sound"
add_rest "The Taco Stand" "the ?taco ?stand"
add_rest "Casa Playa" "casa ?playa"
add_rest "Vegas Poke Co" "pok.? ?co|vegaspoke"
add_rest "322 Pizza Bar" "322 ?pizza"
add_rest "Bazaar Mar by Jose Andres" "bazaar ?mar"
add_rest "Mariscos El Cachetes" "cachetes"
add_rest "El Manantial Restaurant" "manantial"
add_rest "Tacos Los Barrios" "los ?barrios"
add_rest "Tacos El Gordo" "el ?gordo"
add_rest "TARU" "[\"@ ]taru"
add_rest "Raku" "aburiya|\"raku\""
add_rest "Ramen Kobo" "ramen ?kobo"
add_rest "TRES Social Tapas" "tres ?social"
add_rest "Noodle Nest" "noodle ?nest"
add_rest "8 East" "8 ?east"

add_exp "Miss Behaves Mavericks" "miss ?behave" "Performing arts show downtown"

echo "final: crec $BEFORE -> $(curl -s "$DB/dashboard_crec.json" | jq 'keys|length'), exp $(curl -s "$DB/dashboard_exp_crec.json" | jq 'keys|length')"
