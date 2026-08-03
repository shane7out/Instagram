#!/bin/bash
# Add Moonlight Karaoke Lounge to LV Experiences (IMG_8008).
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_exp_crec.json" -o exp.json
ENUM=$(jq '[.[]|.num?|numbers]|max' exp.json)
n=$(jq '[.[]|select((.name//"")|test("moonlight";"i"))]|length' exp.json)
if [ "$n" != "0" ]; then
  echo "SKIP (exp): Moonlight Karaoke Lounge"
  exit 0
fi
ENUM=$((ENUM+1))
curl -s -X PATCH -H "Content-Type: application/json" \
  -d "{\"$ENUM\":{\"name\":\"Moonlight Karaoke Lounge\",\"instagram\":\"\",\"num\":$ENUM,\"notes\":\"Karaoke lounge in Henderson - IG needed (Yelp migration)\"}}" \
  "$DB/dashboard_exp_crec.json" > /dev/null
echo "ADDED EXP: Moonlight Karaoke Lounge (num $ENUM)"
echo "final: exp $(curl -s "$DB/dashboard_exp_crec.json" | jq 'keys|length')"
