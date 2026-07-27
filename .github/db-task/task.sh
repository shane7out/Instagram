#!/bin/bash
# Batch 3 of restaurant adds to dashboard_crec, nums 50805-50809.
# Same schema and guards as previous batches.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json" -o crec.json
BEFORE=$(jq 'keys|length' crec.json)
for h in balicafelv patspattyslv kassibeachhouse area15official ccspeakeasylv; do
  if grep -qi "$h" crec.json; then
    echo "GUARD: $h already present - aborting with no writes"
    exit 1
  fi
done

MAX=$(jq '[.[]|.num?|numbers]|max' crec.json)
if [ "$MAX" -ge 50805 ]; then
  echo "GUARD: num space moved (max=$MAX) - aborting, needs fresh look"
  exit 1
fi

cat > adds.json <<'JSON'
{
  "50805": {"name":"Bali Cafe Las Vegas","instagram":"@balicafelv","num":50805,"notes":"Manually added"},
  "50806": {"name":"Pats Patty's","instagram":"@patspattyslv","num":50806,"notes":"Manually added"},
  "50807": {"name":"Kassi Beach House","instagram":"@kassibeachhouse","num":50807,"notes":"Manually added"},
  "50808": {"name":"AREA15","instagram":"@area15official","num":50808,"notes":"Manually added"},
  "50809": {"name":"CC Speakeasy","instagram":"@ccspeakeasylv","num":50809,"notes":"Manually added"}
}
JSON

STATUS=$(curl -s -o resp.json -w "%{http_code}" -X PATCH -H "Content-Type: application/json" \
  -d @adds.json "$DB/dashboard_crec.json")
echo "PATCH status: $STATUS"
cat resp.json

curl -s "$DB/dashboard_crec.json" -o crec2.json
echo ""
echo "== record count before/after =="
echo "$BEFORE -> $(jq 'keys|length' crec2.json)"
echo "== verification =="
for h in balicafelv patspattyslv kassibeachhouse area15official ccspeakeasylv; do
  if grep -qi "$h" crec2.json; then echo "$h: IN the database"; else echo "$h: MISSING"; fi
done
