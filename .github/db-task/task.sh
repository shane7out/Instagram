#!/bin/bash
# Read-only live check after go-live (prints only counts and status codes).
H=https://lvr-data-a60c1.web.app
chk() { f="$1"; shift; code=$(curl -s -o /tmp/p.html -w '%{http_code}' "$H/$f"); out="$f [$code]"; for n in "$@"; do c=$(grep -c -- "$n" /tmp/p.html); out="$out | $n=$c"; done; echo "$out"; }
chk lvr-points-admin.html "Shown to customers" "#0f67c2" "var PIN = '137900'"
chk key-room.html "#0f67c2" pausePanel "c93a3f"
chk lvr-invoice.html "#0f67c2"
chk kt-crm.html "#0f67c2"
chk key-leads.html "#0f67c2"
chk lvr-restaurant-portal.html "#0f67c2"
S=https://keytechnologies.si
for f in my-account.html menu.html; do code=$(curl -s -o /tmp/s.html -w '%{http_code}' "$S/$f"); echo "$f [$code] exactlyWhatCustomersSee=$(grep -c 'exactly what customers see' /tmp/s.html) noteDialog=$(grep -c noteDialog /tmp/s.html) darkBlue=$(grep -c '#0f67c2' /tmp/s.html)"; done
