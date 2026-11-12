#!/bin/bash
# Member-data-protection rules test in the Firebase emulator (nothing touches the real database).
# Adds the step-5 checks: the owner can move a legacy member's token/phone out of the public record; strangers cannot.
bash .github/db-task/rules/run-private-rules-test.sh
# rerun after fixing a parenthesis in the generated rule: 1794458292
