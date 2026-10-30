#!/bin/bash
# read-only: show what owner-setup.sh left behind (emails masked, key shortened)
DB=https://lvr-data-a60c1-default-rtdb.firebaseio.com
echo "===== _debug/ownersetup ====="
curl -s "$DB/_debug/ownersetup.json" | sed -E 's/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/[EMAIL]/g' | sed 's/\\n/\n/g'
echo; echo "ownerAuth/apiKey stored: $(curl -s $DB/ownerAuth/apiKey.json | cut -c1-6)..."
