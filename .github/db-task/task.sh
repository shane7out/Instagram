#!/bin/bash
# Read both Mac deploy logs + verify live status of both sites.
set +e
echo "=== PT LOG ==="
curl -s "https://lvr-data-a60c1-default-rtdb.firebaseio.com/_debug/pt_log.json" | python3 -c "import sys,json;print(json.load(sys.stdin) or 'EMPTY')"
echo "=== DEALS LOG ==="
curl -s "https://lvr-data-a60c1-default-rtdb.firebaseio.com/_debug/deals_log.json" | python3 -c "import sys,json;print(json.load(sys.stdin) or 'EMPTY')"
echo "=== LIVE ==="
echo "PRIVATE TABLE: $(curl -s -o /dev/null -w '%{http_code}' -L https://private-table-lv.web.app)"
curl -s https://classiccarsforsale-co.web.app/ -o d.html
curl -s https://classiccarsforsale-co.web.app/cars.json -o cars.json
echo "DEALS chip-batman: $(grep -c chip-batman d.html)"
echo "DEALS batman entries: $(grep -c clbm cars.json)"
# recheck 5
# recheck 6
# recheck 7
