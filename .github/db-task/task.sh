#!/bin/bash
# Read-only live check after go-live (prints only counts and status codes).
H=https://lvr-data-a60c1.web.app
chk() { f="$1"; shift; code=$(curl -s -o /tmp/p.html -w '%{http_code}' "$H/$f"); out="$f [$code]"; for n in "$@"; do c=$(grep -c -- "$n" /tmp/p.html); out="$out | $n=$c"; done; echo "$out"; }
chk key-room.html pausePanel bd-points loadSwitches lvr-invoice.html "Customer's Screen" "Las Vegas Restaurant List" "Customer Sign-up"
chk lvr-invoice.html "var PIN = '137900'" "Print / Save as PDF" iCsv
chk lvr-points-admin.html "var PIN = '137900'" renderShowcaseTab
echo "pause flags now:"; curl -s https://lvr-data-a60c1-default-rtdb.firebaseio.com/lvr_points/settings/paused.json; echo
