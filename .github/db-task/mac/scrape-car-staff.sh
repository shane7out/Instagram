#!/bin/bash
# Run on the Mac (one command). First a TRIAL on 8 dealerships, then the full list:
#   curl -sL "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/scrape-car-staff.sh?$(date +%s)" -o /tmp/scrape-car-staff.sh && bash /tmp/scrape-car-staff.sh
#   (full list:  bash /tmp/scrape-car-staff.sh all)
# Opens each dealership's OWN public "meet our team / staff" page, politely (2.5 seconds between visits, obeys robots.txt, stops if a site says no),
# and writes the sales people it shows (name, title, and an email only if the page prints one) into a CSV in your Downloads folder.
# Nothing is uploaded anywhere. Then in the Prospect CRM > Car Sales: Import CSV.
set +e
MODE="${1:-trial}"
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac"
CB="?cb=$(date +%s)"
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
if ! command -v node >/dev/null 2>&1; then echo "Node is not installed on this Mac - tell Claude and I will give you another way."; exit 1; fi
NV=$(node -p "process.versions.node.split('.')[0]")
if [ "${NV:-0}" -lt 18 ]; then echo "Your Node is too old (version $NV, needs 18 or newer) - tell Claude."; exit 1; fi
WORK=/tmp/car-staff; rm -rf "$WORK"; mkdir -p "$WORK"; cd "$WORK"
curl -sL -o scrape-dealer-staff.js "$RAWB/scrape-dealer-staff.js$CB"
curl -sL -o dealers.csv "$RAWB/car-dealers.csv$CB"
if [ ! -s scrape-dealer-staff.js ] || [ ! -s dealers.csv ]; then echo "Could not download the program or the dealership list - nothing done."; exit 1; fi
STAMP=$(date +%Y%m%d-%H%M)
OUT="$HOME/Downloads/car-salespeople-$STAMP.csv"
if [ "$MODE" = "all" ]; then node scrape-dealer-staff.js dealers.csv "$OUT"; else node scrape-dealer-staff.js dealers.csv "$OUT" 8; fi
echo
echo "Your file: $OUT"
echo "What happened at each dealership: ${OUT%.csv}-report.txt"
echo "Next: open the Prospect CRM, tap the Car Sales tab, tap Import CSV and choose that file."
[ "$MODE" != "all" ] && echo "This was only the 8-dealership trial. To do the whole list:  bash /tmp/scrape-car-staff.sh all"
