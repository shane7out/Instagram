#!/bin/bash
set +e
B="https://classiccarsforsale-co.web.app"
echo "=== FINISH LOG ==="
curl -s "https://lvr-data-a60c1-default-rtdb.firebaseio.com/_debug/diag.json" | python3 -c "import sys,json;print(json.load(sys.stdin) or 'EMPTY')"
echo "=== TABS ON HOME ==="
curl -s $B/ -o home.html
echo "tablink coins: $(grep -oE '<a class=\"tablink\" href=\"/coins\"' home.html | head -1)"
echo "tablink batman: $(grep -oE '<a class=\"tablink\" href=\"/batman\"' home.html | head -1)"
echo "old chip-coins still present: $(grep -c 'chip-coins' home.html)"
echo "/coins: $(curl -sL -o /dev/null -w '%{http_code}' $B/coins)  /batman: $(curl -sL -o /dev/null -w '%{http_code}' $B/batman)"
