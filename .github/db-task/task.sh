#!/bin/bash
# Read-only. Round 2: now that we know dashboard_crec is mostly a sparse
# bulk IG-import (cuisine/email basically unused, owner is usually just
# the batch tag "Local Operators", only name+instagram are reliably
# populated), rebuild the restaurant filter around name/notes keyword
# signal instead of cuisine, and require instagram (not phone/email) as
# the contact channel. Also diagnoses dashboard_adv_crec's real schema
# before building the "bigger business, not doctors/lawyers/dentists"
# filter on it - don't want to repeat the same wrong-field-assumption
# mistake twice.
set +e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json"     -o crec.json
curl -s "$DB/dashboard_adv_crec.json" -o adv.json

echo "crec total: $(jq 'keys|length' crec.json)"
echo "adv total:  $(jq 'keys|length' adv.json)"

echo
echo "==== crec: distinct notes values (first 60) ===="
jq -r '[to_entries[].value.notes // empty] | unique | .[0:60][]' crec.json

echo
echo "==== crec: distinct owner values, excluding the bulk-import tag (first 60) ===="
jq -r '[to_entries[].value.owner // empty | select(. != "" and . != "Local Operators")] | unique | .[0:60][]' crec.json

echo
echo "==== crec candidate filter: name/notes upscale keyword OR real (non-bulk) group-style owner, instagram present, noise excluded ===="
UPSCALE='steak ?house|chop ?house|prime\b|omakase|sushi bar|oyster|caviar|champagne|supper club|speakeasy|rooftop|wine (bar|cellar|room)|chef.?s (table|kitchen)|tasting menu|fine dining|michelin|award.?winning|upscale|premium|exclusive|haute|gourmet'
GROUP='group|hospitality|collective|concepts|restaurants$|partners'
NOISE='liquor|vodka|whisk(e)?y|tequila|bourbon|rum$|gin$|beer$|brewing|brewery|cider|seltzer|wine(ry)?$|spirits|dealer|dealership|motors$|automotive|law firm|law group|attorney|legal|injury|dental|dentist|chiropract|medspa|med spa|plastic surgery|dermatolog|caesars|wynn|^mgm|mgmresorts|bellagio|venetian|palazzo|mandalay|luxor|excalibur|new york-new york|planet hollywood|^aria|cosmopolitan|park mgm|resorts world|circa|golden nugget|four seasons|ritz-carlton|waldorf|fontainebleau|durango station|red rock resort|green valley ranch|station casino|boyd gaming|hard rock hotel|virgin hotels|treasure island|flamingo|harrah|^the linq|^rio |tropicana|sahara|westgate|^plaza |golden gate hotel|downtown grand|^the d |main street station|bobby flay|gordon ramsay|wolfgang puck|^nobu|guy fieri|giada|hell.?s kitchen|morimoto'
jq -r --arg up "$UPSCALE" --arg grp "$GROUP" --arg noise "$NOISE" '
  to_entries[] | .value |
  select(
    (((.name // "")  | ascii_downcase | test($up)) or
     ((.notes // "") | ascii_downcase | test($up)) or
     ((.owner // "") != "" and (.owner // "") != "Local Operators" and ((.owner // "") | ascii_downcase | test($grp)))) and
    ((.owner // "") | ascii_downcase | test($noise) | not) and
    ((.name // "")  | ascii_downcase | test($noise) | not) and
    ((.email // "") | ascii_downcase | test($noise) | not) and
    ((.instagram // "") != "")
  ) |
  [(.name // ""), (.instagram // ""), (.notes // ""), (.owner // "")] | join("|")
' crec.json > /tmp/crec_v2.txt
echo "crec v2 matches: $(wc -l < /tmp/crec_v2.txt)"
cat /tmp/crec_v2.txt

echo
echo "==== adv_crec: field population counts ===="
for f in name category notes owner phone email instagram address; do
  n=$(jq --arg f "$f" '[to_entries[] | .value | select((.[$f] // "") != "")] | length' adv.json)
  echo "$f: $n"
done

echo
echo "==== adv_crec: sample of 10 records, all fields ===="
jq -r 'to_entries[0:10][] | .value' adv.json

echo
echo "==== adv_crec: distinct category values (first 60) ===="
jq -r '[to_entries[].value.category // empty] | unique | .[0:60][]' adv.json
