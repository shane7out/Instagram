#!/bin/bash
# Re-run the rules simulator (nothing touches the real database).
bash .github/db-task/rules/run-rules-test.sh
# re-run: chest + bonus rules
# re-run: quest removed
# re-run: use-by rules
# re-run: monthly return tests
# re-run: dry-run expectation fixed
# re-run: repeating chest tests
# restored
# re-run: default commission rule
# re-run: commission write rule fixed
# restored
# restored
# re-run: 10-day bonus with 48-hour claim window
# restored
# restored
# re-run: zero slot rules
# re-run: zero slot rules reverted
# restored
# re-run: offer minimum 15 points
# re-run: old catalog test updated to 20 points
# re-run: transactions ledger rules
