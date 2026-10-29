#!/bin/bash
# Read-only live check after go-live (prints only counts and status codes).
H=https://lvr-data-a60c1.web.app
chk() { f="$1"; shift; code=$(curl -s -o /tmp/p.html -w '%{http_code}' "$H/$f"); out="$f [$code]"; for n in "$@"; do c=$(grep -c -- "$n" /tmp/p.html); out="$out | $n=$c"; done; echo "$out"; }
chk lvr-points-admin.html "var PIN = '137900'" "data-v=\"showcase\"" renderShowcaseTab "Monthly community-fund return" "community fund"
chk lvr-rewards.html "community fund" consentRules
chk kt-crm.html "var PIN = '137900'"
chk key-leads.html "var PIN = '137900'"
chk lvr-coupons-admin.html "var PIN = '137900'"
chk key-advertisers.html "var PIN = '137900'"
chk key-room.html "Restaurants tab"
S=https://keytechnologies.si
for f in my-account.html menu.html rewards.html; do code=$(curl -s -o /tmp/s.html -w '%{http_code}' "$S/$f"); echo "$f [$code] ownerLink=$(grep -c ownerLink /tmp/s.html) communityFund=$(grep -c 'community fund' /tmp/s.html) claimHours=$(grep -c claimHours /tmp/s.html) RewardPoints=$(grep -c 'Reward Point' /tmp/s.html)"; done
