#!/bin/bash
# 3-hour check-in (2026-10-09 ~18:36 UTC). Checking whether Shane has run
# the Deals scraper-source export script on his Mac yet (read-only check,
# not a full pipeline build - just seeing if the handoff piece is ready).
set +e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
echo "=== _debug/deals_scraper_source presence ==="
curl -s "$DB/_debug/deals_scraper_source.json" --max-time 20 | head -c 300
echo
echo
echo "=== Deals site live listing count right now ==="
curl -s "https://classiccarsforsale-co.web.app/?ci=$(date +%s)" --max-time 20 -o /tmp/live-deals-check.html
grep -oE '<article class="card' /tmp/live-deals-check.html | wc -l
