#!/bin/bash
# READ-ONLY: check Ada's, Pasabocas, Trap Wingz in crec + customrecords.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json" -o crec.json
curl -s "$DB/dashboard/customrecords.json" -o cust.json
check() {
  local label="$1" pat="$2"
  echo "$label: crec=$(grep -icE "$pat" crec.json || true) customrecords=$(grep -icE "$pat" cust.json || true)"
}
# "ada's" with apostrophe variants, bounded to avoid readAsText-style noise
check "Adas Wine Bar" "\"ada.?s\"|ada'?s (wine|food|downtown)|adaslasvegas|adasvegas"
check "Pasabocas" "pasabocas"
check "Trap Wingz" "trap ?wing"
