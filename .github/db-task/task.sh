#!/bin/bash
# Check which dating.html is live: version marker + guest-mode marker.
set -e
curl -s https://lvr-data-a60c1.web.app/dating.html -o live.html
echo "size: $(wc -c < live.html)"
echo "SPARK_V line: $(grep -o 'var SPARK_V=[0-9]*' live.html)"
echo "startGuest occurrences: $(grep -c startGuest live.html || true)"
echo "guestBar occurrences: $(grep -c guestBar live.html || true)"
echo "spark-version.json: $(curl -s https://lvr-data-a60c1.web.app/spark-version.json)"
