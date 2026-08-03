#!/bin/bash
# Check whether coins/batman tabs are live yet + read any deploy log.
set +e
B="https://classiccarsforsale-co.web.app"
echo "coins.html: $(curl -s -o /dev/null -w '%{http_code}' $B/coins.html)"
echo "batman.html: $(curl -s -o /dev/null -w '%{http_code}' $B/batman.html)"
echo "chips on home: $(curl -s $B/ | grep -oE 'chip-(batman|coins)' | tr '\n' ' ')"
echo "=== DEPLOY LOG ==="
curl -s "https://lvr-data-a60c1-default-rtdb.firebaseio.com/_debug/diag.json" | python3 -c "import sys,json;print(json.load(sys.stdin) or 'EMPTY')"
