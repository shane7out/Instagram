#!/bin/bash
# 1) Move AREA15 from restaurants (crec 50808) to LV Experiences (exp 60007).
#    Removal uses PATCH-null per the house rules (deletes are blocked); falls
#    back to a dashboard_deleted tombstone if the key survives.
# 2) Fetch the live dashboard HTML and commit it to the repo so the tab
#    feature can be designed against the real source.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

echo "== move AREA15 =="
AREA=$(curl -s "$DB/dashboard_crec/50808.json")
echo "crec 50808: $AREA"
if [ "$AREA" = "null" ]; then
  echo "already moved or absent in crec"
else
  # add to experiences under its new num
  curl -s -X PATCH -H "Content-Type: application/json" \
    -d '{"60007":{"name":"AREA15","instagram":"@area15official","num":60007,"notes":"Immersive art & entertainment district (moved from restaurants)"}}' \
    "$DB/dashboard_exp_crec.json" > /dev/null
  echo "added to dashboard_exp_crec as 60007"
  # remove from restaurants via PATCH-null
  curl -s -X PATCH -H "Content-Type: application/json" \
    -d '{"50808":null}' "$DB/dashboard_crec.json" > /dev/null
  CHECK=$(curl -s "$DB/dashboard_crec/50808.json")
  if [ "$CHECK" = "null" ]; then
    echo "removed from dashboard_crec (PATCH-null worked)"
  else
    echo "PATCH-null blocked; writing tombstone instead"
    TOMB=$(curl -s "$DB/dashboard_deleted.json" | jq -c 'to_entries|last|.value')
    echo "mirroring tombstone value format: $TOMB"
    curl -s -X PATCH -H "Content-Type: application/json" \
      -d "{\"50808\":$TOMB}" "$DB/dashboard_deleted.json" > /dev/null
    echo "tombstoned 50808 in dashboard_deleted"
  fi
fi
echo "exp record count: $(curl -s "$DB/dashboard_exp_crec.json" | jq 'keys|length')"
echo "crec record count: $(curl -s "$DB/dashboard_crec.json" | jq 'keys|length')"

echo "== fetch live dashboard source =="
curl -s https://lvr-data-a60c1.web.app/ -o /tmp/live-dashboard.html
ls -la /tmp/live-dashboard.html
grep -o 'APP_VERSION=[0-9]*' /tmp/live-dashboard.html | head -1

mkdir -p .github/db-task/fetched
cp /tmp/live-dashboard.html .github/db-task/fetched/live-dashboard.html
git config user.name "db-task-runner"
git config user.email "actions@github.com"
git add .github/db-task/fetched/live-dashboard.html
git commit -m "db-task: snapshot live dashboard HTML for tab design" || echo "no changes to commit"
git push
echo "snapshot committed"
