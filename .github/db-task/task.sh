#!/bin/bash
# Re-run the rules simulators (nothing touches the real database): the live rules, then the staged owner-only rules.
bash .github/db-task/rules/run-rules-test.sh
echo "=============== STAGED OWNER-ONLY RULES ==============="
bash .github/db-task/rules/run-owner-rules-test.sh
