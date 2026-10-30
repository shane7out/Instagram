#!/bin/bash
# 1) rules simulator (nothing touches the real database)
bash .github/db-task/rules/run-rules-test.sh; RC=$?
# 2) one-time live setup (owner decisions 2026-10-30): Round One leaderboard backfill, approval on, monthly return on
DB=https://lvr-data-a60c1-default-rtdb.firebaseio.com
node .github/db-task/backfill-round1.js
echo "launch BEFORE:"; curl -s "$DB/lvr_points/settings/launch.json"; echo
curl -s -X PATCH -H 'Content-Type: application/json' -d '{"approval":true}' "$DB/lvr_points/settings/launch.json"; echo
echo "decay BEFORE:"; curl -s "$DB/lvr_points/settings/decay.json"; echo
curl -s -X PUT -H 'Content-Type: application/json' -d '{"enabled":true,"percent":20,"graceDays":30}' "$DB/lvr_points/settings/decay.json"; echo
echo "launch AFTER:"; curl -s "$DB/lvr_points/settings/launch.json"; echo
echo "decay AFTER:"; curl -s "$DB/lvr_points/settings/decay.json"; echo
exit $RC
