#!/bin/bash
# READ-ONLY: dump the _debug/diag.json relay log (result of the Mac finish-deals.sh run).
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
echo "===== _debug/diag.json ====="
curl -s "$DB/_debug/diag.json.json" 2>/dev/null || true
curl -s "$DB/_debug/diag.json"
echo
echo "===== end ====="
