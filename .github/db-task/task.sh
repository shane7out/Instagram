#!/bin/bash
# 1) rules simulator (nothing touches the real database)
bash .github/db-task/rules/run-rules-test.sh; RC=$?
# 2) one-time: founding members limit (owner decision: first 25 people, then 1 invite each). Only set if not already set.
DB=https://lvr-data-a60c1-default-rtdb.firebaseio.com
echo "launch BEFORE:"; curl -s "$DB/lvr_points/settings/launch.json"; echo
echo "member keys (shallow, no personal data):"; curl -s "$DB/lvr_rewards.json?shallow=true" | tr ',' '\n' | wc -l
if [ "$(curl -s "$DB/lvr_points/settings/launch.json")" = "null" ]; then
  curl -s -X PUT -H 'Content-Type: application/json' -d '{"enabled":true,"limit":25,"invites":1}' "$DB/lvr_points/settings/launch.json"; echo " -> set"
fi
echo "launch AFTER:"; curl -s "$DB/lvr_points/settings/launch.json"; echo
exit $RC
