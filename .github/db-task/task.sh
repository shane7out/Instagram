#!/bin/bash
# READ-ONLY: check whether five Yelp-saved restaurants exist anywhere in the
# database (crec adds + customrecords array). No writes.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json" -o crec.json
curl -s "$DB/dashboard/customrecords.json" -o cust.json
echo "crec records: $(jq 'keys|length' crec.json)"
echo "customrecords entries: $(jq 'if .==null then 0 else length end' cust.json)"
echo "== name search (crec / customrecords) =="
check() {
  local label="$1" pat="$2"
  local a b
  a=$(grep -icE "$pat" crec.json || true)
  b=$(grep -icE "$pat" cust.json || true)
  echo "$label: crec=$a customrecords=$b"
}
check "Jins Korean BBQ" "jin.{0,3}s? ?korean"
check "Wok To Walk" "wok ?to ?walk"
check "Earthly Plant Based" "earthly"
check "Carnitas Don Claudio" "don ?claudio"
check "Tacos El Compita" "el ?compita"
