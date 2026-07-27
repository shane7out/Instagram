#!/bin/bash
# Add three more restaurant records to dashboard_crec (same schema as the
# 50799-50801 batch). Guards abort with no writes on duplicates or if the
# num space has moved.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json" -o crec.json
BEFORE=$(jq 'keys|length' crec.json)
for h in rutbaindianvegas pioneersaloonnevada eattacotarian; do
  if grep -qi "$h" crec.json; then
    echo "GUARD: $h already present - aborting with no writes"
    exit 1
  fi
done

MAX=$(jq '[.[]|.num?|numbers]|max' crec.json)
if [ "$MAX" -ge 50802 ]; then
  echo "GUARD: num space moved (max=$MAX) - aborting, needs fresh look"
  exit 1
fi

cat > adds.json <<'JSON'
{
  "50802": {"name":"Rutba Indian Kitchen","instagram":"@rutbaindianvegas","num":50802,"notes":"Manually added"},
  "50803": {"name":"Pioneer Saloon","instagram":"@pioneersaloonnevada","num":50803,"notes":"Manually added"},
  "50804": {"name":"Tacotarian","instagram":"@eattacotarian","num":50804,"notes":"Manually added"}
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
for h in rutbaindianvegas pioneersaloonnevada eattacotarian; do
  if grep -qi "$h" crec2.json; then echo "$h: IN the database"; else echo "$h: MISSING"; fi
done
