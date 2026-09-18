#!/bin/bash
# Check whether @_beasley_02 (food content creator, repost showing a Vegas
# restaurant visit) is already in the influencers list, and add if not.
# Read-only discovery first so the add goes to the right node with the right shape.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_infl_crec.json" -o infl.json
curl -s "$DB/infl_approved.json"       -o approved.json
curl -s "$DB/dashboard/infldeleted.json" -o infldel.json 2>/dev/null || echo "{}" > infldel.json
curl -s "$DB/dashboard/inflstaging.json" -o inflstg.json 2>/dev/null || echo "{}" > inflstg.json

echo "== node sizes =="
echo "dashboard_infl_crec: $(jq 'if type==\"array\" then length else (keys|length) end' infl.json 2>/dev/null || echo 'n/a')"
echo "infl_approved:       $(jq 'if type==\"array\" then length else (keys|length) end' approved.json 2>/dev/null || echo 'n/a')"

echo ""
echo "== sample shape (first entry of dashboard_infl_crec) =="
jq -c 'if type=="array" then .[0] else (to_entries|.[0]) end' infl.json 2>/dev/null || echo "unreadable"

echo ""
echo "== searching all influencer nodes for beasley =="
if grep -qi 'beasley' infl.json approved.json infldel.json inflstg.json 2>/dev/null; then
  echo "FOUND — already in the database:"
  grep -io '.\{0,100\}beasley.\{0,100\}' infl.json approved.json infldel.json inflstg.json 2>/dev/null
else
  echo "NOT FOUND in any influencer node"
fi
