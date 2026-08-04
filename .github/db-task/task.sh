#!/bin/bash
# Yelp migration batch: IMG_8029-8033 (24 restaurants + Absinthe -> experiences).
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
  local jname; jname=$(printf '%s' "$name" | sed 's/"/\\"/g')
  curl -s -X PATCH -H "Content-Type: application/json" \
    -d "{\"$NUM\":{\"name\":\"$jname\",\"instagram\":\"\",\"num\":$NUM,\"notes\":\"Yelp migration - IG needed\"}}" \
    "$DB/dashboard_crec.json" > /dev/null
  curl -s -X PATCH -H "Content-Type: application/json" -d "{\"$NUM\":true}" "$DB/dashboard/badig.json" > /dev/null
  echo "ADDED: $name (num $NUM)"
}
add_exp() {
  local name="$1" pat="$2" note="$3" n
  n=$(jq --arg p "$pat" '[.[]|select((.name//"")|test($p;"i"))]|length' exp.json)
  if [ "$n" != "0" ]; then echo "SKIP (exp): $name"; return; fi
  ENUM=$((ENUM+1))
  curl -s -X PATCH -H "Content-Type: application/json" \
    -d "{\"$ENUM\":{\"name\":\"$name\",\"instagram\":\"\",\"num\":$ENUM,\"notes\":\"$note - IG needed (Yelp migration)\"}}" \
    "$DB/dashboard_exp_crec.json" > /dev/null
  echo "ADDED EXP: $name (num $ENUM)"
}

add_rest "Monzu Italian Oven + Bar" "monz."
add_rest "Tous Les Jours - Rainbow" "tous ?les ?jours"
add_rest "Greek Bistro" "greek ?bistro"
add_rest "Fire Tacos Food Truck" "fire ?tacos"
add_rest "Triple George Grill" "triple ?george"
add_rest "Let's Get Pho" "let.?s ?get ?pho"
add_rest "Taco Man Grill" "taco ?man"
add_rest "Take It Easy Roasters" "take ?it ?easy"
add_rest "Zenaida's Cafe" "zenaida"
add_rest "Omoide Noodles & Bowls" "omoide"
add_rest "Pho Thanh Huong" "thanh ?huong"
add_rest "168 K-BBQ by Hanu" "168 ?k.?bbq|by ?hanu"
add_rest "Smile Shota" "smile ?shota"
add_rest "Mabel's Bar & Q by Chef Michael Symon" "mabel.?s ?bar"
add_rest "Manizza's Pizza" "manizza"
add_rest "Cafe De Flores" "de ?flores"
add_rest "Crossroads Kitchen" "crossroads ?kitchen"
add_rest "Tarantino's Vegan" "tarantino"
add_rest "Boba Cafe" "boba ?cafe"
add_rest "Echo & Rig" "echo .{0,3}rig"
add_rest "Foxtail Coffee" "foxtail ?coffee"
add_rest "Un Poko Krazy" "un ?poko"
add_rest "Oodle Noodle" "oodle ?noodle"
add_rest "Gjelina" "gjelina"
add_exp "Absinthe" "absinthe" "Show at Caesars Palace"

echo "final: crec $BEFORE -> $(curl -s "$DB/dashboard_crec.json" | jq 'keys|length'), exp $(curl -s "$DB/dashboard_exp_crec.json" | jq 'keys|length')"
