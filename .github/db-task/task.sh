#!/bin/bash
# Rules test in the Firebase emulator (nothing touches the real database): rr_ledger clock rules (every time must be the database's own clock) + restaurant decision time (ct).
set +e
bash .github/db-task/rules/run-owner-rules-test.sh
A=$?
bash .github/db-task/rules/run-private-rules-test.sh
B=$?
echo "owner suite exit $A, private suite exit $B"
[ "$A" = "0" ] && [ "$B" = "0" ]
