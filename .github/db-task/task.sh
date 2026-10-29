#!/bin/bash
# one-time: bonus every 7 days, random 1 to 10 points (48 hour claim window unchanged)
DB=https://lvr-data-a60c1-default-rtdb.firebaseio.com
echo "BEFORE:"; curl -s "$DB/lvr_points/settings/chest.json"; echo
curl -s -X PATCH -H 'Content-Type: application/json' -d '{"waitDays":7,"prizeMin":1,"prizeMax":10,"claimHours":48,"repeat":true}' "$DB/lvr_points/settings/chest.json"; echo
echo "AFTER:"; curl -s "$DB/lvr_points/settings/chest.json"; echo
