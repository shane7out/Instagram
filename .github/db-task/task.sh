#!/bin/bash
# Read finish-deals result + verify both tabs live.
set +e
B="https://classiccarsforsale-co.web.app"
echo "=== FINISH LOG ==="
curl -s "https://lvr-data-a60c1-default-rtdb.firebaseio.com/_debug/diag.json" | python3 -c "import sys,json;print(json.load(sys.stdin) or 'EMPTY')"
echo "=== LIVE NOW ==="
echo "/coins: $(curl -sL -o c.html -w '%{http_code}' $B/coins)  cards=$(grep -c 'class=\"card\"' c.html)"
echo "/batman: $(curl -sL -o b.html -w '%{http_code}' $B/batman)  cards=$(grep -c 'class=\"card\"' b.html)"
echo "chips on home: $(curl -s $B/ | grep -oE 'chip-coins|chip-batman' | sort -u | tr '\n' ' ')"
