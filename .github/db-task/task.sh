#!/bin/bash
# Read the fresh gen diagnostic + live batman status.
set +e
echo "=== DIAG ==="
curl -s "https://lvr-data-a60c1-default-rtdb.firebaseio.com/_debug/diag.json" | python3 -c "import sys,json;print(json.load(sys.stdin) or 'EMPTY')"
echo "=== LIVE ==="
curl -s https://classiccarsforsale-co.web.app/cars.json -o cars.json
echo "live clbm: $(grep -c clbm cars.json)"
# recheck 8
# recheck 9
# recheck 10
# recheck 11
# recheck 12
# recheck 13
# recheck 14
# recheck 15
