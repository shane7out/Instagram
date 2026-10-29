#!/bin/bash
# read-only: which restaurants has the owner removed / what service modes are set
DB=https://lvr-data-a60c1-default-rtdb.firebaseio.com
echo "HIDDEN:"; curl -s "$DB/lvr_points/settings/hiddenRestaurants.json"; echo
echo "SVC:"; curl -s "$DB/lvr_points/settings/serviceModes.json"; echo
echo "CATALOG slugs:"; curl -s "$DB/lvr_points/catalog.json?shallow=true"; echo
