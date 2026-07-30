#!/bin/bash
# Fix: The Cromwell was skipped because Marquee's note mentions it.
# Check the name field properly, then add.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_exp_crec.json" -o exp.json
N=$(jq '[.[]|select((.name//"")|test("cromwell";"i"))]|length' exp.json)
if [ "$N" != "0" ]; then
  echo "SKIP: a Cromwell record truly exists"
  exit 0
fi
ENUM=$(jq '[.[]|.num?|numbers]|max' exp.json)
ENUM=$((ENUM+1))
curl -s -X PATCH -H "Content-Type: application/json" \
  -d "{\"$ENUM\":{\"name\":\"The Cromwell\",\"instagram\":\"\",\"num\":$ENUM,\"notes\":\"Boutique hotel & casino on the Strip - IG needed (Yelp migration)\"}}" \
  "$DB/dashboard_exp_crec.json" > /dev/null
echo "ADDED EXP: The Cromwell (num $ENUM)"
echo "exp count: $(curl -s "$DB/dashboard_exp_crec.json" | jq 'keys|length')"
