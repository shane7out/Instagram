#!/bin/bash
# read-only: show the progress notes the Mac scripts leave in the database (emails masked)
DB=https://lvr-data-a60c1-default-rtdb.firebaseio.com
for n in rulesdeploy diag; do
  echo "===== _debug/$n ====="
  curl -s "$DB/_debug/$n.json" | sed -E 's/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/[EMAIL]/g' | sed 's/\\n/\n/g' | tail -60
done
echo "===== round1 (count only) ====="; curl -s "$DB/lvr_points/round1.json?shallow=true" | tr ',' '\n' | wc -l
echo "===== live pages ====="
for f in lvr-points-admin.html key-room.html; do echo "$f $(curl -s -o /dev/null -w '%{http_code}' https://lvr-data-a60c1.web.app/$f)"; done
