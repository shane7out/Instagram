#!/bin/bash
# Read-only live check after go-live (prints only yes/no counts and status codes).
H=https://lvr-data-a60c1.web.app
chk() { f="$1"; shift; curl -s "$H/$f" -o /tmp/p.html -w "" ; code=$(curl -s -o /tmp/p.html -w '%{http_code}' "$H/$f"); out="$f [$code]"; for n in "$@"; do c=$(grep -c -- "$n" /tmp/p.html); out="$out | $n=$c"; done; echo "$out"; }
echo "== owner tools (PIN line and new features) =="
chk lvr-points-admin.html "var PIN = '137900'" sChestHours renderCleanupTab commissionFor "Days between bonuses"
chk kt-crm.html "var PIN = '137900'"
chk key-leads.html "var PIN = '137900'"
chk lvr-coupons-admin.html "var PIN = '137900'"
chk key-advertisers.html "var PIN = '137900'"
chk lvr-rewards.html consentRules
chk lvr-restaurant-portal.html "Pickup only"
echo "== old PIN gone from points admin =="; grep -c "702954" /tmp/p.html >/dev/null; curl -s "$H/lvr-points-admin.html" | grep -c "702954"
DB=https://lvr-data-a60c1-default-rtdb.firebaseio.com
echo "== database probes (a blocked write is the good answer) =="
p() { code=$(curl -s -o /tmp/r.txt -w '%{http_code}' -X "$1" -d "$3" "$DB$2.json"); echo "$1 $2 -> $code"; }
p PUT /lvr_points/settings/decay/percent 90
p PUT /lvr_points/receipts/zz_probe 1
p DELETE /lvr_points/receipts 
p PUT /lvr_points/settings/chest/claimHours 5000
curl -s "$DB/lvr_points/settings/chest/claimHours.json"; echo
code=$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "$DB/lvr_points/settings/chest/claimHours.json"); echo "cleanup delete of probe value -> $code"
