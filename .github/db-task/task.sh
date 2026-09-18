#!/bin/bash
# Add @_beasley_02 to influencers (dashboard_infl_crec).
# Food content creator - repost/story shows them at a restaurant with a full
# spread (onion rings, fries, burger), tagged with a location pin and their own
# original audio. Confirmed not already present in any influencer node.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_infl_crec.json" -o infl.json
BEFORE=$(jq 'keys|length' infl.json)
echo "infl_crec before: $BEFORE"

if grep -qi 'beasley' infl.json; then
  echo "SKIP: already in db —"
  grep -io '.\{0,100\}beasley.\{0,100\}' infl.json
  exit 0
fi

NUM=$(jq '[.[]|.num?|numbers]|max' infl.json); NUM=$((NUM+1))
echo "assigning num $NUM"

curl -s -X PATCH -H "Content-Type: application/json" -d "{
  \"$NUM\": {
    \"name\": \"Beasley\",
    \"ig\": \"_beasley_02\",
    \"num\": $NUM,
    \"cat\": \"Food & Dining\",
    \"notes\": \"Manually added from IG repost screenshot - food content creator, posts restaurant visits with original audio. Seen dining on a full spread (onion rings, fries, burger) with a location tag.\"
  }}" "$DB/dashboard_infl_crec.json" > /dev/null

AFTER=$(curl -s "$DB/dashboard_infl_crec.json" | jq 'keys|length')
echo "infl_crec after: $AFTER  (was $BEFORE)"
curl -s "$DB/dashboard_infl_crec/$NUM.json" | jq .
