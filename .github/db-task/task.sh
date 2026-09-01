#!/bin/bash
# Check which of the owner's sites are live, for building the directory page.
set -e
check(){ printf '%-34s %s\n' "$1" "$(curl -sL -o /dev/null -w '%{http_code}' --max-time 20 "$2")"; }
echo "=== owner sites ==="
check "LVR Dashboard"        "https://lvr-data-a60c1.web.app"
check "Deals (cars/land)"    "https://classiccarsforsale-co.web.app"
check "  - US Coins"         "https://classiccarsforsale-co.web.app/coins"
check "  - Eagle Point Land" "https://classiccarsforsale-co.web.app/land-eaglepoint"
check "Storage Containers"   "https://the-atl.web.app"
check "Private Chef"         "https://private-table-lv.web.app"
check "Foreclosures"         "https://findmyforeclosure.web.app"
check "CC (credit cards)"    "https://lvr-cc.web.app"
check "Badges"               "https://lvr-data-a60c1.web.app/badges.html"
check "Dating"               "https://lvr-data-a60c1.web.app/dating.html"
check "LV Restaurant Specials" "https://lasvegasrestaurantspecials.com"
echo "=== outside tools linked from the dashboard ==="
check "Credit (cleverkit)"   "https://pro.cleverkit.ai"
check "Business Funding"     "https://fullyfunded.co"
echo "=== not yet hosted ==="
check "St Rita's (Pages off)" "https://shane7out.github.io/Instagram/st-ritas/"
