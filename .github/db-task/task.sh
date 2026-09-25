#!/bin/bash
# Add AlohaMulans (@alohamulans) - Hawaii/Vegas local shop & pop-up market vendor.
# Non-food business -> dashboard_adv_crec. IG-profile screenshot, so the handle
# goes on the record and no Bad IG flag.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_adv_crec.json"      -o adv.json
curl -s "$DB/dashboard_crec.json"          -o crec.json
curl -s "$DB/dashboard/customrecords.json" -o cust.json
curl -s "$DB/dashboard_infl_crec.json"     -o infl.json
BEFORE=$(jq 'keys|length' adv.json)
echo "adv before: $BEFORE"

if grep -qiE 'alohamulans|aloha[ _-]?mulans' adv.json crec.json cust.json infl.json; then
  echo "SKIP: already in db —"
  grep -oiE '.{0,90}aloha[ _-]?mulans.{0,90}' adv.json crec.json cust.json infl.json | head -5
  exit 0
fi

NUM=$(jq '[.[]|.num?|numbers]|max' adv.json); NUM=$((NUM+1))
echo "assigning num $NUM"

curl -s -X PATCH -H "Content-Type: application/json" -d "{
  \"$NUM\": {
    \"name\": \"AlohaMulans\",
    \"instagram\": \"@alohamulans\",
    \"num\": $NUM,
    \"notes\": \"Manually added from IG profile screenshot - Hawaii/Las Vegas local shop, sells apparel and gifts at pop-up markets (Shop & Seek Desert Dusk, October Makeke, Pumpkins & Palaka Makeke). Owner goes by Mulan. 2,486 followers, 761 posts. nvhub.net and other links in bio.\"
  }}" "$DB/dashboard_adv_crec.json" > /dev/null

AFTER=$(curl -s "$DB/dashboard_adv_crec.json" | jq 'keys|length')
echo "adv after: $AFTER  (was $BEFORE)"
curl -s "$DB/dashboard_adv_crec/$NUM.json" | jq .
