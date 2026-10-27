#!/bin/bash
# Re-run the rules simulator (nothing touches the real database).
bash .github/db-task/rules/run-rules-test.sh
# re-run: chest + bonus rules
# re-run: quest removed
# re-run: use-by rules
# re-run: monthly return tests
