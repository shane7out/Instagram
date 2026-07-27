#!/bin/bash
# Batch 4: three restaurant adds (nums 50810-50812), plus a READ-ONLY peek at
# dashboard_adv_crec's schema for a possible advertiser add to follow.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json" -o crec.json
BEFORE=$(jq 'keys|length' crec.json)
for h in casaderaku sorellinalasvegas durangotacoshop7; do
  if grep -qi "$h" crec.json; then
    echo "GUARD: $h already present - aborting with no writes"
    exit 1
  fi
done

MAX=$(jq '[.[]|.num?|numbers]|max' crec.json)
if [ "$MAX" -ge 50810 ]; then
  echo "GUARD: num space moved (max=$MAX) - aborting, needs fresh look"
  exit 1
fi

cat > adds.json <<'JSON'
{
  "50810": {"name":"Casa de Raku","instagram":"@casaderaku","num":50810,"notes":"Manually added"},
  "50811": {"name":"Sorellina Cucina Italiana","instagram":"@sorellinalasvegas","num":50811,"notes":"Manually added"},
  "50812": {"name":"Durango Taco Shop","instagram":"@durangotacoshop7","num":50812,"notes":"Manually added"}
}
JSON

STATUS=$(curl -s -o resp.json -w "%{http_code}" -X PATCH -H "Content-Type: application/json" \
  -d @adds.json "$DB/dashboard_crec.json")
echo "PATCH status: $STATUS"

curl -s "$DB/dashboard_crec.json" -o crec2.json
echo "== record count before/after =="
echo "$BEFORE -> $(jq 'keys|length' crec2.json)"
echo "== verification =="
for h in casaderaku sorellinalasvegas durangotacoshop7; do
  if grep -qi "$h" crec2.json; then echo "$h: IN the database"; else echo "$h: MISSING"; fi
done

echo "== READ-ONLY: advertiser schema peek =="
curl -s "$DB/dashboard_adv_crec.json" -o adv.json
jq 'keys|length' adv.json
jq -r 'keys|last' adv.json
jq -c --arg k "$(jq -r 'keys|last' adv.json)" '.[$k]' adv.json
jq '[.[]|.num?|numbers]|max' adv.json
grep -cio 'templeinjurylaw' adv.json || true
