#!/bin/bash
# Yelp-migration batch: 19 restaurant candidates (one with a known IG from the
# user's Yelp note) + 3 experiences (Mandalay Bay, Play Playground, Marquee).
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
  local name="$1" pat="$2" ig="${3:-}"
  if grep -qiE "$pat" crec.json || grep -qiE "$pat" cust.json; then
    echo "SKIP: $name"; return
  fi
  NUM=$((NUM+1))
  local notes="Yelp migration - IG needed"
  [ -n "$ig" ] && notes="Yelp migration - IG from owner note"
  curl -s -X PATCH -H "Content-Type: application/json" \
    -d "{\"$NUM\":{\"name\":\"$name\",\"instagram\":\"$ig\",\"num\":$NUM,\"notes\":\"$notes\"}}" \
    "$DB/dashboard_crec.json" > /dev/null
  if [ -z "$ig" ]; then
    curl -s -X PATCH -H "Content-Type: application/json" -d "{\"$NUM\":true}" "$DB/dashboard/badig.json" > /dev/null
  fi
  echo "ADDED: $name (num $NUM${ig:+, ig=$ig})"
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

add_rest "Board and Graze" "board ?(and|&) ?graze"
add_rest "Miami Grill" "miami ?grill"
add_rest "Ruths Chris Steak House" "ruth.?s ?chris"
add_rest "Lot J Tacos" "lot ?j"
add_rest "The Golden Tiki" "golden ?tiki"
add_rest "1923 Prohibition Bar" "prohibition"
add_rest "Tekka Bar: Handroll & Sake" "tekka|tekks" "@tekksbarhandrollsake"
add_rest "Takumi Izakaya" "takumi"
add_rest "Oyshi Sushi" "oyshi"
add_rest "Ace King BBQ" "ace ?king"
add_rest "Double Helix Wine & Whiskey Lounge" "double ?helix"
add_rest "Matiki Island BBQ" "matiki"
add_rest "Laguna Pool House & Kitchen" "laguna ?pool"
add_rest "CUT by Wolfgang Puck" "cut ?by ?wolfgang"
add_rest "Havana 1957" "havana ?1957"
add_rest "Master Kims Korean BBQ" "master ?kim"
add_rest "The Beast" "beast"
add_rest "Mr Moto Pizza" "moto ?pizza"
add_rest "The Bagel Nook - Summerlin" "bagel ?nook"
add_rest "Atomic Liquors" "atomic ?liquor"

add_exp "Mandalay Bay Resort & Casino" "mandalay" "Strip resort & casino"
add_exp "Play Playground" "play ?playground" "Adult playground bar at Luxor"
add_exp "Marquee Nightclub" "marquee" "Nightclub at The Cosmopolitan"

echo "final: crec $BEFORE -> $(curl -s "$DB/dashboard_crec.json" | jq 'keys|length'), exp $(curl -s "$DB/dashboard_exp_crec.json" | jq 'keys|length')"
