#!/bin/bash
# Read-only: final pull for the upscale-restaurant + bigger/established-
# business prospect list for Key Technologies, per Shane's request to go
# "higher end... bigger companies... not doctors, lawyers, dentists,
# chiropractors... don't want low-end restaurants." Built from the real
# field schemas confirmed over the last several rounds (dashboard_crec
# is a sparse IG import with name+instagram as the only reliable fields;
# dashboard_adv_crec has a real "cat"/"category" field that is far more
# reliable than guessing from name text - excludes every Lawyer/Doctor/
# Dental/MedSpa/Spa/Dealership/Liquor/Food-Truck category directly).
# Still keeps the casino/resort/celebrity-chef NOISE exclusion as a
# second layer on name/email, since category alone wouldn't catch e.g.
# a restaurant physically inside a casino.
set +e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json"     -o crec.json
curl -s "$DB/dashboard_adv_crec.json" -o adv.json
curl -s "$DB/dashboard_exp_crec.json" -o exp.json

NOISE='liquor|vodka|whisk(e)?y|tequila|bourbon|rum$|gin$|beer$|brewing|brewery|cider|seltzer|wine(ry)?$|spirits|dealer|dealership|motors$|automotive|law firm|law group|attorney|legal|injury|dental|dentist|chiropract|medspa|med spa|plastic surgery|dermatolog|caesars|wynn|^mgm|mgmresorts|bellagio|venetian|palazzo|mandalay|luxor|excalibur|new york-new york|planet hollywood|^aria|cosmopolitan|park mgm|resorts world|circa|golden nugget|four seasons|ritz-carlton|waldorf|fontainebleau|durango station|red rock resort|green valley ranch|station casino|boyd gaming|hard rock hotel|virgin hotels|treasure island|flamingo|harrah|^the linq|^rio |tropicana|sahara|westgate|^plaza |golden gate hotel|downtown grand|^the d |main street station|bobby flay|gordon ramsay|wolfgang puck|^nobu|guy fieri|giada|hell.?s kitchen|morimoto'

echo "==== 1) RESTAURANTS (dashboard_crec): upscale name/notes keyword, instagram contact ===="
UPSCALE='steak ?house|chop ?house|prime\b|omakase|sushi bar|oyster|caviar|champagne|supper club|speakeasy|rooftop|wine (bar|cellar|room)|chef.?s (table|kitchen)|tasting menu|fine dining|michelin|award.?winning|upscale|premium|exclusive|haute|gourmet'
GROUP='group|hospitality|collective|concepts|restaurants$|partners'
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
  ["RESTAURANT", (.name // ""), (.instagram // ""), (.notes // "" | .[0:70])] | join("|")
' crec.json > /tmp/final_crec.txt
echo "matches: $(wc -l < /tmp/final_crec.txt)"
cat /tmp/final_crec.txt

echo
echo "==== 2) OTHER BUSINESSES (dashboard_adv_crec): excludes lawyer/doctor/dental/medspa/spa/dealer/liquor/food-truck categories ===="
EXCLUDE_CAT='lawyer|doctor|dental|medspa|dealer|liquor|^wine$|food truck|^spa$'
jq -r --arg ec "$EXCLUDE_CAT" --arg noise "$NOISE" '
  to_entries[] | .value |
  select(
    (((.cat // .category // "") | ascii_downcase | test($ec)) | not) and
    ((.name // "")  | ascii_downcase | test($noise) | not) and
    ((.email // "") | ascii_downcase | test($noise) | not) and
    (((.phone // "") != "") or ((.email // "") != "") or ((.ig // .instagram // "") != ""))
  ) |
  [(.cat // .category // "(none)"), (.name // ""), (.phone // ""), (.email // ""), (.ig // .instagram // "")] | join("|")
' adv.json > /tmp/final_adv.txt
echo "matches: $(wc -l < /tmp/final_adv.txt)"
sort /tmp/final_adv.txt

echo
echo "==== 3) EXPERIENCES (dashboard_exp_crec): nightclubs/hotels/attractions/shows, noise excluded ===="
jq -r --arg noise "$NOISE" '
  to_entries[] | .value |
  select(
    ((.owner // "") | ascii_downcase | test($noise) | not) and
    ((.name // "")  | ascii_downcase | test($noise) | not) and
    ((.email // "") | ascii_downcase | test($noise) | not)
  ) |
  ["EXPERIENCE", (.name // ""), (.phone // ""), (.email // ""), (.instagram // ""), (.notes // "" | .[0:60])] | join("|")
' exp.json > /tmp/final_exp.txt
echo "matches: $(wc -l < /tmp/final_exp.txt)"
cat /tmp/final_exp.txt
