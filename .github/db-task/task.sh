#!/bin/bash
# Check the standalone Batman page live + read the build log.
set +e
echo "batman.html status: $(curl -s -o bat.html -w '%{http_code}' https://classiccarsforsale-co.web.app/batman.html)"
echo "size: $(wc -c < bat.html)"
echo "cards on page: $(grep -oc 'class=\"card\"' bat.html)"
echo "title present: $(grep -c 'Batman 1966 Trading Cards' bat.html)"
echo "chip is link on home: $(curl -s https://classiccarsforsale-co.web.app/ | grep -c 'chip-batman\" href=\"/batman.html\"')"
echo "=== BUILD LOG ==="
curl -s "https://lvr-data-a60c1-default-rtdb.firebaseio.com/_debug/diag.json" | python3 -c "import sys,json;print(json.load(sys.stdin) or 'EMPTY')"
