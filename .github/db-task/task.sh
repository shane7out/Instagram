#!/bin/bash
# Rules test in the Firebase emulator (nothing touches the real database): the read-only "report PIN" account (page-view report opens with a PIN).
set +e
bash .github/db-task/rules/run-owner-rules-test.sh
A=$?
bash .github/db-task/rules/run-private-rules-test.sh
B=$?
echo "owner suite exit $A, private suite exit $B"
[ "$A" = "0" ] && [ "$B" = "0" ]
