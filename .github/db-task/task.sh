#!/bin/bash
# Read the Mac's uploaded deploy log + live status.
set +e
echo "=== MAC DEPLOY LOG ==="
curl -s "https://lvr-data-a60c1-default-rtdb.firebaseio.com/_debug/pt_log.json" | python3 -c "import sys,json;print(json.load(sys.stdin) or 'EMPTY')"
echo "=== LIVE ==="
echo "PRIVATE TABLE: $(curl -s -o /dev/null -w '%{http_code}' -L https://private-table-lv.web.app)"
curl -s https://classiccarsforsale-co.web.app/ -o d.html
echo "DEALS chip-batman: $(grep -c chip-batman d.html)"
