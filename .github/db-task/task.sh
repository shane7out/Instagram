#!/bin/bash
# Read-only live check (prints only counts and status codes).
H=https://lvr-data-a60c1.web.app
code=$(curl -s -o /tmp/p.html -w '%{http_code}' "$H/lvr-points-admin.html")
echo "lvr-points-admin.html [$code] ShownToCustomers=$(grep -c 'Shown to customers' /tmp/p.html) RemovedList=$(grep -c 'customers cannot see these' /tmp/p.html) darkBlue=$(grep -c '#0f67c2' /tmp/p.html)"
