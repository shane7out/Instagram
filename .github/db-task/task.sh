#!/bin/bash
# Read-only: build a filtered SMB prospect list for Key Technologies from the
# LVR database. Keeps records that are (a) not a big resort/casino corporate
# account, and (b) have a phone or email already on file (reachable beyond
# just an Instagram DM). Outputs compact pipe-delimited lines so Claude can
# turn this into a real file.
set +e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json"     -o crec.json
curl -s "$DB/dashboard_adv_crec.json" -o adv.json

echo "crec total: $(jq 'keys|length' crec.json)"
echo "adv total: $(jq 'keys|length' adv.json)"

# Big resort/casino/corporate keywords to exclude (owner, address, OR email
# domain) - these are enterprise accounts with internal teams, or
# celebrity-chef/mega-group tenants inside them, not KEY's SMB target.
EXCLUDE='caesars|wynn|^mgm|bellagio|venetian|palazzo|mandalay|luxor|excalibur|new york-new york|^paris |planet hollywood|^aria|cosmopolitan|park mgm|resorts world|circa|golden nugget|four seasons|ritz-carlton|waldorf|fontainebleau|durango station|red rock resort|green valley ranch|station casino|boyd gaming|hard rock hotel|virgin hotels|treasure island|flamingo|harrah|^the linq|^rio |tropicana|sahara|westgate|^plaza |golden gate hotel|downtown grand|^the d |main street station|bobby flay|gordon ramsay|wolfgang puck|^nobu|guy fieri|giada|hell.?s kitchen|morimoto|mgmresorts\.com|caesars\.com|wynnresorts|wynnlasvegas|venetianlasvegas|cosmopolitanlasvegas|stationcasinos\.com|boydgaming\.com|hardrockhotels|virginhotelslv|fourseasons\.com|ritzcarlton\.com'

echo
echo "==== filtering dashboard_crec (restaurants) ===="
jq -r --arg ex "$EXCLUDE" '
  to_entries[] | .value |
  select(
    ((.owner // "") | ascii_downcase | test($ex) | not) and
    ((.address // "") | ascii_downcase | test($ex) | not) and
    ((.email // "") | ascii_downcase | test($ex) | not) and
    ((.name // "") | ascii_downcase | test($ex) | not) and
    (((.phone // "") != "") or ((.email // "") != ""))
  ) |
  [(.name // ""), (.phone // ""), (.email // ""), (.instagram // ""), (.cuisine // "")] | join("|")
' crec.json > /tmp/crec_filtered.txt
echo "crec matches: $(wc -l < /tmp/crec_filtered.txt)"
cat /tmp/crec_filtered.txt

echo
echo "==== filtering dashboard_adv_crec (advertisers) ===="
jq -r --arg ex "$EXCLUDE" '
  to_entries[] | .value |
  select(
    ((.owner // "") | ascii_downcase | test($ex) | not) and
    ((.address // "") | ascii_downcase | test($ex) | not) and
    ((.email // "") | ascii_downcase | test($ex) | not) and
    ((.name // "") | ascii_downcase | test($ex) | not) and
    (((.phone // "") != "") or ((.email // "") != ""))
  ) |
  [(.name // ""), (.phone // ""), (.email // ""), (.instagram // ""), (.cuisine // "")] | join("|")
' adv.json > /tmp/adv_filtered.txt
echo "adv matches: $(wc -l < /tmp/adv_filtered.txt)"
cat /tmp/adv_filtered.txt
