#!/bin/bash
# READ-ONLY: check rui deploy result + live v3 state (run 2).
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
echo "===== _debug/diag relay ====="
curl -s "$DB/_debug/diag.json"
echo
echo "===== live checks ====="
curl -s "https://classiccarsforsale-co.web.app/?v=$(date +%s)" -o live.html
echo "live v3 blocks: $(grep -c 'DEALS-REFRESH-v3' live.html)"
echo "lastupd line: $(grep -o '<div class="lastupd" id="lastupd">[^<]*' live.html | head -1)"
echo "_deals/updated: $(curl -s "$DB/_deals/updated.json")"
echo "_deals/removed count: $(curl -s "$DB/_deals/removed.json" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(len(d) if d else 0)')"
