#!/bin/bash
# Read-only: 3-hour check-in sanity check - has Shane made any progress on
# his own (GitHub Pages toggle, a Mac deploy script) since the last update,
# without telling Claude? Checks live sites directly rather than assuming
# nothing changed.
set +e

echo "=== GitHub Pages (claude/key-website) ==="
curl -s -o /dev/null -w "shane7out.github.io/Instagram/ -> HTTP %{http_code}\n" https://shane7out.github.io/Instagram/ --max-time 15
curl -s -o /dev/null -w "keytechnologies.si/ -> HTTP %{http_code}\n" https://keytechnologies.si/ --max-time 15

echo
echo "=== Live LVR dashboard: APP_VERSION + deploy markers ==="
curl -s https://lvr-data-a60c1.web.app/ -o /tmp/live-dash.html --max-time 20
echo "bytes: $(wc -c < /tmp/live-dash.html)"
grep -ao 'APP_VERSION=[0-9]*' /tmp/live-dash.html | head -1
echo "KEYPILL01 marker present: $(grep -c 'KEYPILL01' /tmp/live-dash.html)"
echo "ZACHPIN marker present: $(grep -c 'ZACHPIN' /tmp/live-dash.html)"
echo "Key Technologies pill text present: $(grep -c 'Key Technologies' /tmp/live-dash.html)"

echo
echo "=== Deals site: has the stale scraper fix actually run? ==="
curl -s https://classiccarsforsale-co.web.app/cars.json -o /tmp/cars.json --max-time 20
node -e "
try {
  const d = JSON.parse(require('fs').readFileSync('/tmp/cars.json','utf8'));
  const dates = [...new Set(d.map(c=>c.added))].sort();
  console.log('total cars:', d.length);
  console.log('distinct added-dates (last 5):', dates.slice(-5));
} catch(e) { console.log('could not parse cars.json:', e.message); }
"

echo
echo "=== Dating site: instant-swipe fix live? ==="
curl -s https://lvr-data-a60c1.web.app/dating.html -o /tmp/dating.html --max-time 20
echo "bytes: $(wc -c < /tmp/dating.html)"
grep -c "instant" /tmp/dating.html 2>/dev/null
