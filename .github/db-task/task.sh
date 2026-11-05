#!/bin/bash
# READ-ONLY: is the owner sign-in set up? Prints only which keys exist under ownerAuth (never their values) and whether
# the staged-owner-rules deploy happened (is the database still open to strangers?). Only GET requests.
DB=https://lvr-data-a60c1-default-rtdb.firebaseio.com
echo "ownerAuth keys present (names only):"
curl -s "$DB/ownerAuth.json?shallow=true" | sed -E 's/"([^"]+)":true/\1/g' | tr -d '{}' | tr ',' '\n' | sed 's/^/  - /'
echo "ownerAuth/apiKey stored: $(curl -s "$DB/ownerAuth/apiKey.json" | grep -q '"AIza' && echo yes || echo no)"
echo "owner uid stored: $(curl -s "$DB/ownerAuth/uid.json" | grep -qE '"[A-Za-z0-9]{20,}"' && echo yes || echo no)"
echo "--- is the data still open to strangers? (HTTP status of an anonymous read; 401 = locked, 200 = open) ---"
for p in key_leads kt_crm key_pageviews/hits; do printf "  %s: " "$p"; curl -s -o /dev/null -w "%{http_code}\n" "$DB/$p.json?shallow=true"; done
echo "CHECK DONE (nothing was changed)"
