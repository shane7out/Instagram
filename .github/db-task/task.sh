#!/bin/bash
# Read-only: build an upscale/bigger-business prospect list for Key
# Technologies. Restaurants filtered for upscale dining signals (fine
# dining, steakhouse, chef-driven, etc.) or multi-location group ownership,
# plus the smaller "experiences" node (nightclubs, hotels, attractions,
# shows - naturally skews upscale). Excludes the same big-brand noise
# (national liquor/beer, car dealer groups) found last time, and this time
# also explicitly keeps out medical/legal/dental - not what's wanted.
set +e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json"     -o crec.json
curl -s "$DB/dashboard_exp_crec.json" -o exp.json

echo "crec total: $(jq 'keys|length' crec.json)"
echo "exp total: $(jq 'keys|length' exp.json)"

UPSCALE='fine dining|steakhouse|chef|tasting menu|omakase|michelin|award-winning|upscale|premium|rooftop|wine bar|wine list|sommelier|chef.?s table|white tablecloth|haute|gourmet|exclusive'
GROUP='group|hospitality|collective|restaurants$|concepts'
# Same resort/casino/celebrity-chef exclusions as the earlier SMB pass, PLUS
# the liquor/dealer/legal/medical categories ruled out this round.
NOISE='liquor|vodka|whisk(e)?y|tequila|bourbon|rum$|gin$|beer$|brewing|brewery|cider|seltzer|wine(ry)?$|spirits|dealer|dealership|motors$|automotive|law firm|law group|attorney|legal|injury|dental|dentist|chiropract|medspa|med spa|plastic surgery|dermatolog|caesars|wynn|^mgm|mgmresorts|bellagio|venetian|palazzo|mandalay|luxor|excalibur|new york-new york|planet hollywood|^aria|cosmopolitan|park mgm|resorts world|circa|golden nugget|four seasons|ritz-carlton|waldorf|fontainebleau|durango station|red rock resort|green valley ranch|station casino|boyd gaming|hard rock hotel|virgin hotels|treasure island|flamingo|harrah|^the linq|^rio |tropicana|sahara|westgate|^plaza |golden gate hotel|downtown grand|^the d |main street station|bobby flay|gordon ramsay|wolfgang puck|^nobu|guy fieri|giada|hell.?s kitchen|morimoto'

echo
echo "==== dashboard_crec: upscale-signal or group-owned, with contact info ===="
jq -r --arg up "$UPSCALE" --arg grp "$GROUP" --arg noise "$NOISE" '
  to_entries[] | .value |
  select(
    (((.cuisine // "") | ascii_downcase | test($up)) or
     ((.notes // "")   | ascii_downcase | test($up)) or
     ((.owner // "")   | ascii_downcase | test($grp))) and
    ((.owner // "")   | ascii_downcase | test($noise) | not) and
    ((.name // "")    | ascii_downcase | test($noise) | not) and
    ((.email // "")   | ascii_downcase | test($noise) | not) and
    (((.phone // "") != "") or ((.email // "") != "") or ((.instagram // "") != ""))
  ) |
  [(.name // ""), (.phone // ""), (.email // ""), (.instagram // ""), (.cuisine // ""), (.owner // "")] | join("|")
' crec.json > /tmp/crec_upscale.txt
echo "crec matches: $(wc -l < /tmp/crec_upscale.txt)"
cat /tmp/crec_upscale.txt

echo
echo "==== dashboard_exp_crec: experiences (nightclubs, hotels, attractions, shows) ===="
jq -r --arg noise "$NOISE" '
  to_entries[] | .value |
  select(
    ((.owner // "") | ascii_downcase | test($noise) | not) and
    ((.name // "")  | ascii_downcase | test($noise) | not) and
    ((.email // "") | ascii_downcase | test($noise) | not)
  ) |
  [(.name // ""), (.phone // ""), (.email // ""), (.instagram // ""), (.notes // "" | .[0:60]), (.owner // "")] | join("|")
' exp.json > /tmp/exp_all.txt
echo "exp matches: $(wc -l < /tmp/exp_all.txt)"
cat /tmp/exp_all.txt
