#!/bin/bash
# Add Yu by Sijie (@yubysijie) - Chinese fusion restaurant, Las Vegas.
# Restaurant -> dashboard_crec. IG-profile screenshot, so the handle goes on
# the record and no Bad IG flag.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json"          -o crec.json
curl -s "$DB/dashboard/customrecords.json" -o cust.json
curl -s "$DB/dashboard_exp_crec.json"      -o exp.json
BEFORE=$(jq 'keys|length' crec.json)
echo "crec before: $BEFORE"

if grep -qiE 'yubysijie|yu[ _-]?by[ _-]?sijie' crec.json cust.json exp.json; then
  echo "SKIP: already in db —"
  grep -oiE '.{0,90}yu[ _-]?by[ _-]?sijie.{0,90}' crec.json cust.json exp.json | head -5
  exit 0
fi

NUM=$(jq '[.[]|.num?|numbers]|max' crec.json); NUM=$((NUM+1))
echo "assigning num $NUM"

curl -s -X PATCH -H "Content-Type: application/json" -d "{
  \"$NUM\": {
    \"name\": \"Yu by Sijie\",
    \"instagram\": \"@yubysijie\",
    \"num\": $NUM,
    \"address\": \"400 S Rampart Blvd, Suite 190, Las Vegas, NV\",
    \"notes\": \"Manually added from IG profile screenshot - Chinese fusion restaurant (Yu by Sijie / Si Jie). Soup dumplings, Peking duck, liquid-nitrogen tableside presentations. Bio is IG-flagged 'AI-generated profile' (the description text, not the restaurant itself - it's a real location with its own address). 826 followers, 12 posts. yubysijie.com\"
  }}" "$DB/dashboard_crec.json" > /dev/null

AFTER=$(curl -s "$DB/dashboard_crec.json" | jq 'keys|length')
echo "crec after: $AFTER  (was $BEFORE)"
curl -s "$DB/dashboard_crec/$NUM.json" | jq .
