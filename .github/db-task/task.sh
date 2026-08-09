#!/bin/bash
# READ-ONLY: dump the _debug diag relay (deploy-cc run check).
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
echo "===== _debug/diag relay ====="
curl -s "$DB/_debug/diag.json"
echo
echo "===== end ====="
