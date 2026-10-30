#!/bin/bash
# one-time: earn rate = 1 point per $1 spent (owner decision). Read first, then set only where it is 0.5 or unset.
DB=https://lvr-data-a60c1-default-rtdb.firebaseio.com
echo "BEFORE:"; curl -s "$DB/lvr_points/directory.json"; echo
for slug in $(curl -s "$DB/lvr_points/directory.json?shallow=true" | tr -d '{}"' | tr ',' '\n' | sed 's/:true//'); do
  cur=$(curl -s "$DB/lvr_points/directory/$slug/earnRate.json")
  echo "$slug earnRate=$cur"
  if [ "$cur" = "0.5" ] || [ "$cur" = "null" ]; then curl -s -X PUT -H 'Content-Type: application/json' -d '1' "$DB/lvr_points/directory/$slug/earnRate.json"; echo " -> set to 1"; fi
done
echo "AFTER:"; curl -s "$DB/lvr_points/directory.json"; echo
