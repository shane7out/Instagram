#!/bin/bash
# Add Sky Combat Ace (experience) with IG handle from IG-profile screenshot.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
curl -s "$DB/dashboard_exp_crec.json" -o exp.json
BEFORE=$(jq 'keys|length' exp.json)
if jq -e '[.[]|.name//""|test("sky ?combat";"i")]|any' exp.json > /dev/null; then
  echo "SKIP: already in db"; exit 0
fi
NUM=$(jq '[.[]|.num?|numbers]|max // 0' exp.json); NUM=$((NUM+1))
curl -s -X PATCH -H "Content-Type: application/json" \
  -d "{\"$NUM\":{\"name\":\"Sky Combat Ace\",\"instagram\":\"@skycombatace\",\"num\":$NUM,\"notes\":\"Manually added - aerobatic stunt plane experience, Las Vegas\"}}" \
  "$DB/dashboard_exp_crec.json" > /dev/null
echo "ADDED: Sky Combat Ace (num $NUM)"
echo "count: $BEFORE -> $(curl -s "$DB/dashboard_exp_crec.json" | jq 'keys|length')"
