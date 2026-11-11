#!/bin/bash
# Run on the Mac (one command). Car dealership sales people or real estate agents, a TRIAL first, then the full list:
#   curl -sL "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/scrape-staff.sh?$(date +%s)" -o /tmp/scrape-staff.sh && bash /tmp/scrape-staff.sh cars
#   (agents:   bash /tmp/scrape-staff.sh realtors        full list:   bash /tmp/scrape-staff.sh cars all   or   bash /tmp/scrape-staff.sh realtors all)
# Opens each business's OWN public "meet our team / agents" page, politely (2.5 seconds between visits, obeys robots.txt, stops if a site says no),
# and writes the people it shows (name, title, and an email only if the page prints one next to them) into a CSV in your Downloads folder.
# Nothing is uploaded anywhere. Then in the Prospect CRM, open the Car Sales (or Real Estate) tab and tap Import CSV.
set +e
KIND="${1:-cars}"; MODE="${2:-trial}"
case "$KIND" in cars) LIST=car-dealers.csv; export SCRAPE_MODE=cars;; realtors) LIST=realtor-brokerages.csv; export SCRAPE_MODE=realtors;; *) echo "Say cars or realtors."; exit 1;; esac
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac"
CB="?cb=$(date +%s)"
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
if ! command -v node >/dev/null 2>&1; then echo "Node is not installed on this Mac - tell Claude and I will give you another way."; exit 1; fi
NV=$(node -p "process.versions.node.split('.')[0]")
if [ "${NV:-0}" -lt 18 ]; then echo "Your Node is too old (version $NV, needs 18 or newer) - tell Claude."; exit 1; fi
WORK=/tmp/staff-scrape; rm -rf "$WORK"; mkdir -p "$WORK"; cd "$WORK"
curl -sL -o scrape-dealer-staff.js "$RAWB/scrape-dealer-staff.js$CB"
curl -sL -o list.csv "$RAWB/$LIST$CB"
if [ ! -s scrape-dealer-staff.js ] || [ ! -s list.csv ]; then echo "Could not download the program or the list - nothing done."; exit 1; fi
STAMP=$(date +%Y%m%d-%H%M)
OUT="$HOME/Downloads/$KIND-people-$STAMP.csv"
if [ "$MODE" = "all" ]; then node scrape-dealer-staff.js list.csv "$OUT"; else node scrape-dealer-staff.js list.csv "$OUT" 8; fi
echo
echo "Your file: $OUT"
echo "What happened at each business: ${OUT%.csv}-report.txt"
echo "Next: open the Prospect CRM, tap the $([ "$KIND" = cars ] && echo 'Car Sales' || echo 'Real Estate') tab, tap Import CSV and choose that file."
[ "$MODE" != "all" ] && echo "This was only the 8-business trial. To do the whole list:  bash /tmp/scrape-staff.sh $KIND all"
