#!/bin/bash
# Read-only: why does classiccarsforsale-co.web.app show 0 cars available now?
set +e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

echo "==== _deals/updated (last sweep stamp) ===="
curl -s "$DB/_deals/updated.json"
echo

echo "==== live cars.json age check ===="
curl -s "https://classiccarsforsale-co.web.app/cars.json" -o /tmp/cars.json
echo "cars.json bytes: $(wc -c < /tmp/cars.json)"
echo "total entries: $(jq 'length' /tmp/cars.json 2>/dev/null)"
echo "distinct 'added' dates:"
jq -r '[.[].added] | unique | .[]' /tmp/cars.json 2>/dev/null
echo
echo "sample entry:"
jq '.[0]' /tmp/cars.json 2>/dev/null

echo
echo "==== how many are older than 30 days (today = $(date -u +%F)) ===="
TODAY_EPOCH=$(date -u +%s)
jq -r --argjson today "$TODAY_EPOCH" '
  [.[] | select(.added != null) | .added] as $dates |
  $dates | length
' /tmp/cars.json 2>/dev/null
echo "oldest / newest added date present:"
jq -r '[.[].added] | sort | (.[0], .[-1])' /tmp/cars.json 2>/dev/null

echo
echo "==== live page: does it show a count vs actual rendered cards? ===="
curl -s "https://classiccarsforsale-co.web.app/" -o /tmp/deals-live.html
echo "live page bytes: $(wc -c < /tmp/deals-live.html)"
echo "'cars available' text: $(grep -oE '[0-9]+ cars? available' /tmp/deals-live.html | head -1)"
echo "'Showing X of Y' text: $(grep -oE 'Showing [0-9]+ of [0-9]+' /tmp/deals-live.html | head -1)"
echo "<article class=\"card\"> count in HTML: $(grep -oc '<article class=\"card\"' /tmp/deals-live.html)"
