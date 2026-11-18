#!/bin/bash
# Rules test in the Firebase emulator (nothing touches the real database): the Restaurant Rewards ledger (rr_ledger) rules.
# Owner-rules suite (includes the new ledger checks) and the member-data suite (both assemble key-rules-owner.json with the placeholders).
set +e
bash .github/db-task/rules/run-owner-rules-test.sh
A=$?
bash .github/db-task/rules/run-private-rules-test.sh
B=$?
echo "owner suite exit $A, private suite exit $B"
[ "$A" = "0" ] && [ "$B" = "0" ]
