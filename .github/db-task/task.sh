#!/bin/bash
# Phase 2: write the three restaurant records to dashboard_crec, mirroring the
# schema captured in phase 1 (key = num as string; fields name/instagram/num).
# Nums 50799-50801 follow the observed max (50798); none are tombstoned.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

# Guard: refuse to write if any target handle is already present
curl -s "$DB/dashboard_crec.json" -o crec.json
BEFORE=$(jq 'keys|length' crec.json)
for h in fortunelasvegas blacklabelburgerco shookshakery; do
  if grep -qi "$h" crec.json; then
    echo "GUARD: $h already present - aborting with no writes"
    exit 1
  fi
done

# Guard: confirm num space is still free (nothing else wrote since phase 1)
MAX=$(jq '[.[]|.num?|numbers]|max' crec.json)
if [ "$MAX" -ge 50799 ]; then
  echo "GUARD: num space moved (max=$MAX) - aborting, needs fresh look"
  exit 1
fi

cat > adds.json <<'JSON'
{
  "50799": {"name":"Fortune Seafood Restaurant","instagram":"@fortunelasvegas","num":50799,"notes":"Manually added"},
  "50800": {"name":"Black Label Burger Company","instagram":"@blacklabelburgerco","num":50800,"notes":"Manually added"},
  "50801": {"name":"Shook Shakery","instagram":"@shookshakery","num":50801,"notes":"Manually added"}
}
JSON

STATUS=$(curl -s -o resp.json -w "%{http_code}" -X PATCH -H "Content-Type: application/json" \
  -d @adds.json "$DB/dashboard_crec.json")
echo "PATCH status: $STATUS"
cat resp.json

# Verify
curl -s "$DB/dashboard_crec.json" -o crec2.json
echo ""
echo "== record count before/after =="
echo "$BEFORE -> $(jq 'keys|length' crec2.json)"
echo "== verification =="
for h in fortunelasvegas blacklabelburgerco shookshakery; do
  if grep -qi "$h" crec2.json; then echo "$h: IN the database"; else echo "$h: MISSING"; fi
done
