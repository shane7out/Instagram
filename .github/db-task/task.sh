#!/bin/bash
# cleanup of a harmless probe key left by a live check, then the rules simulators (nothing else touches the real database)
DB=https://lvr-data-a60c1-default-rtdb.firebaseio.com
echo "cleanup zz_probe -> $(curl -s -o /dev/null -w '%{http_code}' -X DELETE $DB/lvr_points/settings/zz_probe.json)"
bash .github/db-task/rules/run-rules-test.sh
echo "=============== STAGED OWNER-ONLY RULES ==============="
bash .github/db-task/rules/run-owner-rules-test.sh
