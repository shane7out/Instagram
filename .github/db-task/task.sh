#!/bin/bash
# Rules test in the Firebase emulator (nothing touches the real database): supply raised to 10,000,000 (meta.issued and the entry amount cap 1000000000). (rerun after fixing the over-supply test amount)
set +e
bash .github/db-task/rules/run-owner-rules-test.sh
A=$?
bash .github/db-task/rules/run-private-rules-test.sh
B=$?
echo "owner suite exit $A, private suite exit $B"
[ "$A" = "0" ] && [ "$B" = "0" ]
