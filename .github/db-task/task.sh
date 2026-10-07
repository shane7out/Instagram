#!/bin/bash
# Read-only: 3-hour check-in (re-run 2026-10-07 ~12:35 UTC) - checking specifically
# whether Shane has turned on GitHub Pages / pointed DNS at keytechnologies.si
# since the last check. All 5 Mac deploy tasks were confirmed done directly
# via his terminal output already (not via this script) - this just covers
# the two items that still needed a browser, not a Mac command.
set +e
echo "=== GitHub Pages (claude/key-website) ==="
curl -s -o /dev/null -w "shane7out.github.io/Instagram/ -> HTTP %{http_code}\n" https://shane7out.github.io/Instagram/ --max-time 15
curl -s -o /dev/null -w "keytechnologies.si/ -> HTTP %{http_code}\n" https://keytechnologies.si/ --max-time 15

echo
echo "=== Dashboard: does the Key Technologies pill resolve now? ==="
curl -s https://lvr-data-a60c1.web.app/ -o /tmp/live-dash.html --max-time 20
echo "Key Technologies pill text present: $(grep -c 'Key Technologies' /tmp/live-dash.html)"
