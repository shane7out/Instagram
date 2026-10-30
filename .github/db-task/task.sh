#!/bin/bash
# read-only: check what is actually live on the hosting site and in the database
B=https://lvr-data-a60c1.web.app
for f in lvr-points-admin.html key-room.html lvr-rewards.html; do
  curl -s "$B/$f?cb=$(date +%s)" -o /tmp/$f
  echo "== $f  bytes=$(wc -c < /tmp/$f)  OWNER-AUTH=$(grep -c OWNER-AUTH-START /tmp/$f)  Approvals-tab=$(grep -c 'data-v="approvals"' /tmp/$f)  pool-drop=$(grep -c sDropRun /tmp/$f)  emergency=$(grep -c eEnd /tmp/$f)  vip-pending=$(grep -c "rec.status = 'pending'" /tmp/$f)"
done
DB=https://lvr-data-a60c1-default-rtdb.firebaseio.com
echo "settings/launch: $(curl -s $DB/lvr_points/settings/launch.json)"
echo "settings/decay:  $(curl -s $DB/lvr_points/settings/decay.json)"
echo "anon write to settings (expect 401): $(curl -s -o /dev/null -w '%{http_code}' -X PUT -d 1 $DB/lvr_points/settings/zz_probe.json)"
echo "round1 entries: $(curl -s "$DB/lvr_points/round1.json?shallow=true" | tr ',' '\n' | wc -l)"
echo "ownerAuth/apiKey present: $(curl -s $DB/ownerAuth/apiKey.json | head -c 6)"
