#!/bin/bash
# Yelp migration batch: IMG_7820-7824 (18 new candidates, all restaurants).
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

add_rest "Hachi" "hachi"
add_rest "Emeril's New Orleans Fish House" "emeril"
add_rest "HAPAHAOLES Hawaiian Street Tacos" "hapa ?haole|hapahaole"
add_rest "Tailgate Social" "tailgate ?social"
add_rest "Rachel's Kitchen" "rachel.?s ?kitchen"
add_rest "Piero's Italian Cuisine" "piero'?s"
add_rest "Divine Dosa & Biryani" "divine ?dosa"
add_rest "Fine Company" "fine ?company"
add_rest "Umiya Sushi" "umiya"
add_rest "Snooze an A.M. Eatery" "snooze"
add_rest "Bleu Kitchen Garlic Noodle Bar" "bleu ?kitchen"
add_rest "Parlour Brunch & Late Night Burger Bar" "parlour ?brunch"
add_rest "Osteria Fiorella" "fiorella"
add_rest "Sgrizzi By Chef Marc" "sgrizzi"
add_rest "Cafe Mong" "cafe ?mong"
add_rest "Hash House A Go Go" "hash ?house"
add_rest "Other Mama" "other ?mama"
add_rest "Signora Pizza" "signora"

echo "final: crec $BEFORE -> $(curl -s "$DB/dashboard_crec.json" | jq 'keys|length')"
