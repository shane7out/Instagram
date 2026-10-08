#!/bin/bash
# 3-hour check-in (2026-10-08 ~03:36 UTC). Two things this cycle:
# 1) GitHub Pages / keytechnologies.si - re-checking after ~15h gap (not every
#    single cycle, but enough time passed it's worth a look).
# 2) A regression sweep of every Mac deploy confirmed live earlier in the
#    project (dashboard patches, Zach PIN, Key Technologies pill, dating
#    instant-swipe) - none of these have been re-verified since they first
#    went live, and nothing should be assumed to stay fixed forever.
set +e

echo "=== GitHub Pages / DNS ==="
curl -s -o /dev/null -w "shane7out.github.io/Instagram/ -> HTTP %{http_code}\n" https://shane7out.github.io/Instagram/ --max-time 15
curl -s -o /dev/null -w "keytechnologies.si/ -> HTTP %{http_code}\n" https://keytechnologies.si/ --max-time 15

echo
echo "=== Dashboard regression sweep ==="
curl -s https://lvr-data-a60c1.web.app/ -o /tmp/live-dash.html --max-time 20
echo "Key Technologies pill present: $(grep -c 'Key Technologies' /tmp/live-dash.html)"
echo "Zach PIN marker present: $(grep -c 'ZACH_PIN' /tmp/live-dash.html)"
APPVER=$(grep -oE "APP_VERSION[^0-9]*[0-9]+" /tmp/live-dash.html | head -1)
echo "APP_VERSION marker: $APPVER"

echo
echo "=== Dating site regression ==="
curl -s https://lvr-data-a60c1.web.app/dating.html -o /tmp/live-dating.html --max-time 20
echo "live dating.html bytes: $(wc -c < /tmp/live-dating.html)"
echo "DATEQS01 (instant-swipe patch) present: $(grep -c 'DATEQS01' /tmp/live-dating.html)"
echo "Instant demo profile present: $(grep -c 'Instant demo profile' /tmp/live-dating.html)"
