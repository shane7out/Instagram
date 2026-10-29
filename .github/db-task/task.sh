#!/bin/bash
# Read-only live check (prints only counts and status codes).
R=https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/lvr-points-admin.html
curl -s "$R" -o /tmp/raw.html -w "raw github [%{http_code}] " ; echo "ShownToCustomers=$(grep -c 'Shown to customers' /tmp/raw.html)"
curl -s "https://lvr-data-a60c1.web.app/lvr-points-admin.html" -D /tmp/h.txt -o /tmp/p.html
echo "live ShownToCustomers=$(grep -c 'Shown to customers' /tmp/p.html) bytes=$(wc -c < /tmp/p.html) rawBytes=$(wc -c < /tmp/raw.html)"
grep -i "cache-control\|^date\|last-modified\|^age" /tmp/h.txt
