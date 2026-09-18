#!/bin/bash
# Add Mom's Basement Theatre (@moms.basement.theatre) - comedy club / improv
# training space, Las Vegas. Comedy club -> dashboard_exp_crec. IG-profile
# screenshot, so the handle goes on the record and no Bad IG flag.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_exp_crec.json" -o exp.json
curl -s "$DB/dashboard_crec.json"     -o crec.json
curl -s "$DB/dashboard/customrecords.json" -o cust.json
BEFORE=$(jq 'keys|length' exp.json)
echo "exp_crec before: $BEFORE"

if grep -qiE 'moms\.?basement\.?theatre|mom.?s[ _-]basement' exp.json crec.json cust.json; then
  echo "SKIP: already in db —"
  grep -oiE '.{0,90}mom.?s[ _-]?basement.{0,90}' exp.json crec.json cust.json | head -5
  exit 0
fi

NUM=$(jq '[.[]|.num?|numbers]|max' exp.json); NUM=$((NUM+1))
echo "assigning num $NUM"

curl -s -X PATCH -H "Content-Type: application/json" -d "{
  \"$NUM\": {
    \"name\": \"Mom's Basement Theatre\",
    \"instagram\": \"@moms.basement.theatre\",
    \"num\": $NUM,
    \"notes\": \"Manually added from IG profile screenshot - comedy club, official home of LV Improv. Stand-up, drop-in classes, ComedySportz every Saturday, True Story storytelling show. DMs open for trainings/classes/workshops. 1,547 followers, 436 posts. linktr.ee/momsbasementtheatre, momsbasementtheatre.com\"
  }}" "$DB/dashboard_exp_crec.json" > /dev/null

AFTER=$(curl -s "$DB/dashboard_exp_crec.json" | jq 'keys|length')
echo "exp_crec after: $AFTER  (was $BEFORE)"
curl -s "$DB/dashboard_exp_crec/$NUM.json" | jq .
