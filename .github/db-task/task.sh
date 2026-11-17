#!/bin/bash
# Rules test in the Firebase emulator (nothing touches the real database): the new read-only "report PIN" account (page-view report opens with a PIN).
# Owner-rules suite (includes the new report-PIN checks) and the member-data suite (both assemble key-rules-owner.json with the viewer placeholder).
set +e
bash .github/db-task/rules/run-owner-rules-test.sh
A=$?
bash .github/db-task/rules/run-private-rules-test.sh
B=$?
echo "owner suite exit $A, private suite exit $B"
[ "$A" = "0" ] && [ "$B" = "0" ]
