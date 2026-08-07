#!/bin/bash
# READ-ONLY diagnostic: check the 8 ghost advertiser records (in both adv_crec and adv_deleted).
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
curl -s "$DB/dashboard_adv_crec.json" -o adv.json
curl -s "$DB/dashboard_adv_deleted.json" -o del.json
echo "adv_crec total: $(jq 'keys|length' adv.json)"
echo "adv_deleted total: $(jq 'keys|length' del.json 2>/dev/null || echo 'n/a')"
echo "--- checking the 8 nums ---"
for N in 17650 17653 17681 17704 17724 17790 17794 17797; do
  INCREC=$(jq --arg n "$N" 'has($n)' adv.json)
  INDEL=$(jq --arg n "$N" 'has($n)' del.json 2>/dev/null || echo false)
  NAME=$(jq -r --arg n "$N" '.[$n].name // "?"' adv.json)
  echo "num $N | in adv_crec: $INCREC | in adv_deleted: $INDEL | name: $NAME"
done
echo "--- ghost = in BOTH ---"
