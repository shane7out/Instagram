#!/bin/bash
# Follow-up check: the sanity-pass script flagged "What The Grill" as
# MISSING, but that was an exact-name-match bug in the script (the real
# record is named "What The Grill - Silverado Ranch", added earlier this
# session as num 60024) - confirming the record is actually still there,
# not actually lost.
set +e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
echo "=== dashboard_crec/60024 ==="
curl -s "$DB/dashboard_crec/60024.json" --max-time 15
echo
echo "=== dashboard/status/60024 ==="
curl -s "$DB/dashboard/status/60024.json" --max-time 15
echo

echo
echo "=== VIVA! duplicate check ==="
curl -s "$DB/dashboard_crec.json" -o /tmp/crec2.json --max-time 20
node -e '
const fs = require("fs");
const crec = JSON.parse(fs.readFileSync("/tmp/crec2.json","utf8")) || {};
for (const [k,r] of Object.entries(crec)) {
  if (r && (r.name||"").toUpperCase() === "VIVA!") console.log(k, JSON.stringify(r));
}
'
