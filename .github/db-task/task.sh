#!/bin/bash
# Read-only. Round 3: dashboard_adv_crec turns out to mix two schemas -
# one batch uses cat/ig (the Lawyer - Personal Injury records sampled
# last round), another uses category/instagram. Neither has a usable
# "owner" field (0/542 populated) so group-ownership text-matching,
# which worked for crec, doesn't apply here at all. Before building the
# "bigger business, not legal/medical/dental" filter, get the FULL
# distinct category list across both field names plus some real samples
# from categories other than the law-firm batch, so the exclusion list
# is built against what's actually there instead of guessed again.
set +e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
curl -s "$DB/dashboard_adv_crec.json" -o adv.json
echo "adv total: $(jq 'keys|length' adv.json)"

echo
echo "==== distinct (.cat // .category) values, with counts ===="
jq -r '[to_entries[].value | (.cat // .category // "(none)")] | group_by(.) | map({k: .[0], n: length}) | sort_by(-.n) | .[] | "\(.n)\t\(.k)"' adv.json

echo
echo "==== 3 sample records per non-law, non-dealership, non-realtor category ===="
jq -r '
  [to_entries[].value] as $all |
  ($all | map(.cat // .category // "(none)") | unique) as $cats |
  $cats[] as $c |
  select($c | test("lawyer|dealership|realtor"; "i") | not) |
  ($all | map(select((.cat // .category // "(none)") == $c)) | .[0:3][]) |
  "[\($c)] " + (. | tostring)
' adv.json
