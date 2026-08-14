#!/bin/bash
# READ-ONLY: confirm the bigger white arrow (26px) is live + refresher state.
set -e
curl -s "https://classiccarsforsale-co.web.app/?cb=$(date +%s)" -o live.html
echo "arrow size 26px live: $(grep -c 'font-size:26px' live.html || true)"
echo "baked button: $(grep -c '<button id=\"refreshbtn\"' live.html || true)"
echo "removed count: $(curl -s https://lvr-data-a60c1-default-rtdb.firebaseio.com/_deals/removed.json | python3 -c 'import json,sys; d=json.load(sys.stdin); print(len(d) if d else 0)')"
echo "updated: $(curl -s https://lvr-data-a60c1-default-rtdb.firebaseio.com/_deals/updated.json)"
