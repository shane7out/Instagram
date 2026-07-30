#!/bin/bash
# Yelp-migration batch: 23 restaurant candidates + Durango Casino & Resort (exp).
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

add_rest "BabyStacks Cafe" "babystacks"
add_rest "18bin" "18 ?bin"
add_rest "Scrambled" "\"scrambled"
add_rest "Tamba" "tamba"
add_rest "Doya Jjambbong" "doya"
add_rest "Sushi Mon" "sushi ?mon"
add_rest "Bel-Aire Lounge" "bel.?aire"
add_rest "Boba Foxy" "boba ?foxy"
add_rest "Tacos & Beer" "tacos ?(&|and) ?beer"
add_rest "Proper Sandwich" "proper ?sandwich"
add_rest "Palm Sugar" "palm ?sugar"
add_rest "Trattoria Italia" "trattoria ?itali"
add_rest "Horizon Shine" "horizon ?shine"
add_rest "The Coffee Class" "coffee ?class"
add_rest "The Boiling Crab" "boiling ?crab"
add_rest "Rebellion Pizza" "rebellion"
add_rest "La Casa De Juliette" "juliette"
add_rest "Cajun Crackin" "cajun ?crackin"
add_rest "The Laundry Room" "laundry ?room"
add_rest "Fogo de Chao" "fogo"
add_rest "KoMex Fusion" "komex"
add_rest "Liquid Acai Eatery" "liquid ?acai"
add_rest "Shang Artisan Noodle" "shang ?artisan"

add_exp "Durango Casino & Resort" "durango" "Off-Strip resort & casino"

echo "final: crec $BEFORE -> $(curl -s "$DB/dashboard_crec.json" | jq 'keys|length'), exp $(curl -s "$DB/dashboard_exp_crec.json" | jq 'keys|length')"
