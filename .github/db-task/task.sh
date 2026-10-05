#!/bin/bash
# Read-only diagnostic: the upscale-prospect filter matched 0 of 821
# dashboard_crec records in the real data (worked fine against synthetic
# test fixtures). Before re-tuning the filter, dump real field names/values
# to see what's actually in cuisine/notes/owner for a sample of records,
# and some basic stats on which fields are populated at all.
set +e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_crec.json" -o crec.json
echo "crec total: $(jq 'keys|length' crec.json)"

echo
echo "==== sample of 10 records, all fields ===="
jq -r 'to_entries[0:10][] | .value' crec.json

echo
echo "==== field population counts (how many of 821 have each field non-empty) ===="
for f in name cuisine notes owner phone email instagram address category type; do
  n=$(jq --arg f "$f" '[to_entries[] | .value | select((.[$f] // "") != "")] | length' crec.json)
  echo "$f: $n"
done

echo
echo "==== distinct cuisine values (first 40) ===="
jq -r '[to_entries[].value.cuisine // empty] | unique | .[0:40][]' crec.json

echo
echo "==== distinct category/type values if present (first 40) ===="
jq -r '[to_entries[].value.category // empty] | unique | .[0:40][]' crec.json
jq -r '[to_entries[].value.type // empty] | unique | .[0:40][]' crec.json
