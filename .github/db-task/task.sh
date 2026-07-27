#!/bin/bash
# Batch 5: two restaurant adds (nums 50813-50814). Same schema and guards.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json" -o crec.json
BEFORE=$(jq 'keys|length' crec.json)
for h in doh_korean_bbq_1 polloseldorado.vegas; do
  if grep -qi "$h" crec.json; then
    echo "GUARD: $h already present - aborting with no writes"
    exit 1
  fi
done

MAX=$(jq '[.[]|.num?|numbers]|max' crec.json)
if [ "$MAX" -ge 50813 ]; then
  echo "GUARD: num space moved (max=$MAX) - aborting, needs fresh look"
  exit 1
fi

cat > adds.json <<'JSON'
{
  "50813": {"name":"Doh Korean BBQ","instagram":"@doh_korean_bbq_1","num":50813,"notes":"Manually added"},
  "50814": {"name":"Pollos El Dorado","instagram":"@polloseldorado.vegas","num":50814,"notes":"Manually added"}
}
JSON

STATUS=$(curl -s -o resp.json -w "%{http_code}" -X PATCH -H "Content-Type: application/json" \
  -d @adds.json "$DB/dashboard_crec.json")
echo "PATCH status: $STATUS"

curl -s "$DB/dashboard_crec.json" -o crec2.json
echo "== record count before/after =="
echo "$BEFORE -> $(jq 'keys|length' crec2.json)"
echo "== verification =="
for h in doh_korean_bbq_1 polloseldorado.vegas; do
  if grep -qi "$h" crec2.json; then echo "$h: IN the database"; else echo "$h: MISSING"; fi
done
