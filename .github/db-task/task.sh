#!/bin/bash
# Read-only LVR system audit: database integrity + a security check + live
# site health. Every jq expression below was tested against synthetic
# fixtures locally before shipping. The only write this script does is a
# single scratch key it creates then immediately deletes, to test whether
# the database accepts unauthenticated writes (see check #1).
set +e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
cd /tmp || exit 1

echo "==== fetching nodes ===="
declare -A F=(
  [crec]=dashboard_crec
  [exp]=dashboard_exp_crec
  [adv]=dashboard_adv_crec
  [infl]=dashboard_infl_crec
  [cust]=dashboard/customrecords
  [badig]=dashboard/badig
  [igsuggest]=dashboard/igsuggest
  [deleted]=dashboard/deleted
  [igovr]=dashboard/igovr
  [reststg]=dashboard_rest_stg_crec
  [rsremoved]=dashboard/rsremoved
)
for k in "${!F[@]}"; do
  curl -s "$DB/${F[$k]}.json" -o "/tmp/$k.json"
  echo "${F[$k]}: $(wc -c < /tmp/$k.json) bytes"
done

echo
echo "==== 1) SECURITY: does the database accept unauthenticated writes? ===="
WCODE=$(curl -s -o /dev/null -w '%{http_code}' -X PUT -H "Content-Type: application/json" -d "\"audit probe $(date -u +%s)\"" "$DB/_audit_probe.json")
echo "unauthenticated PUT to a scratch key -> HTTP $WCODE (200 = anyone with this DB URL can read/write/delete ALL data directly, no PIN needed)"
curl -s -X DELETE "$DB/_audit_probe.json" > /dev/null
echo "scratch key cleaned up"

echo
echo "==== 2) duplicate 'num' within dashboard_crec ===="
jq -r '[.[] | .num] | group_by(.) | map(select(length>1))' /tmp/crec.json

echo
echo "==== 3) duplicate instagram handles within dashboard_crec (case-insensitive) ===="
jq -r '[.[] | select(.instagram != null and .instagram != "") | {num,name,handle:(.instagram|ascii_downcase)}] | group_by(.handle) | map(select(length>1))' /tmp/crec.json

echo
echo "==== 4) records missing name or num in dashboard_crec ===="
jq -r '[.[] | select(.name == null or .name == "" or .num == null)]' /tmp/crec.json

echo
echo "==== 5) malformed instagram handles (not @handle format) in dashboard_crec ===="
jq -r '[.[] | select(.instagram != null and .instagram != "" and (.instagram | test("^@[A-Za-z0-9._]+$") | not))] | map({num,name,instagram})' /tmp/crec.json

echo
echo "==== 6) dashboard/badig entries pointing at a num not present ANYWHERE (crec/cust/exp/adv/infl) ===="
echo "     (a hit here still 'missing' after also allowing for a soft-delete is the real signal)"
jq -r 'keys' /tmp/badig.json > /tmp/badig_keys.json
jq -r '[.[] | .num?] | map(select(. != null))' /tmp/crec.json > /tmp/crec_nums.json
jq -r '[.[] | .num?] | map(select(. != null))' /tmp/cust.json > /tmp/cust_nums.json
jq -r '[.[] | .num?] | map(select(. != null))' /tmp/exp.json > /tmp/exp_nums.json
jq -r '[.[] | .num?] | map(select(. != null))' /tmp/adv.json > /tmp/adv_nums.json
jq -r '[.[] | .num?] | map(select(. != null))' /tmp/infl.json > /tmp/infl_nums.json
jq -r 'keys' /tmp/deleted.json > /tmp/deleted_keys.json
jq -n --slurpfile b /tmp/badig_keys.json --slurpfile c /tmp/crec_nums.json --slurpfile u /tmp/cust_nums.json \
      --slurpfile e /tmp/exp_nums.json --slurpfile a /tmp/adv_nums.json --slurpfile i /tmp/infl_nums.json \
      --slurpfile d /tmp/deleted_keys.json '
  ($b[0] | map(tonumber)) as $bk |
  (($c[0] + $u[0] + $e[0] + $a[0] + $i[0]) | unique) as $all |
  ($d[0] | map(tonumber)) as $del |
  [$bk[] | select(. as $x | ($all | index($x)) | not)] as $orphans |
  { truly_missing_everywhere: [$orphans[] | select(. as $x | ($del | index($x)) | not)],
    missing_but_soft_deleted_explains_it: [$orphans[] | select(. as $x | ($del | index($x)))] }
'

echo
echo "==== 7) dashboard/igsuggest entries for a num that is not currently flagged Bad IG ===="
jq -r 'keys' /tmp/igsuggest.json > /tmp/igsug_keys.json
jq -n --slurpfile s /tmp/igsug_keys.json --slurpfile b /tmp/badig_keys.json '
  ($s[0]) as $sk | ($b[0]) as $bk |
  [$sk[] | select(. as $x | ($bk | index($x)) | not)]
'

echo
echo "==== 8) dashboard_crec vs customrecords: same num, different name (mirror drift) ===="
jq -r '[.[] | {num,name}]' /tmp/crec.json > /tmp/crec_ns.json
jq -r '[.[] | select(.num != null) | {num,name}]' /tmp/cust.json > /tmp/cust_ns.json
jq -n --slurpfile a /tmp/crec_ns.json --slurpfile b /tmp/cust_ns.json '
  ($a[0] | map({(.num|tostring): .name}) | add) as $A |
  ($b[0] | map({(.num|tostring): .name}) | add) as $B |
  [ ($A // {}) | keys[] | select($B[.] != null and $B[.] != $A[.]) | {num:., crec:$A[.], cust:$B[.]} ]
'

echo
echo "==== 9) records this session added, sanity re-check (no accidental dupes) ===="
grep -oiE '.{0,60}(yubysijie|torostacoslv|donricebar).{0,60}' /tmp/crec.json

echo
echo "==== 10) live site HTTP status checks ===="
for url in "https://lvr-data-a60c1.web.app/" "https://lvr-data-a60c1.web.app/dating.html" "https://lvr-data-a60c1.web.app/badges.html" "https://classiccarsforsale-co.web.app/" "https://lvr-cc.web.app/"; do
  code=$(curl -s -o /dev/null -w '%{http_code}' "$url")
  echo "$url -> $code"
done

echo
echo "==== done ===="
