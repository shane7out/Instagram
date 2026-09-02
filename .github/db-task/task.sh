#!/bin/bash
# Snapshot the live dashboard so the CRM audit is against what is actually deployed,
# not the older local copy (local is v443, live was v446).
set +e
OUT=.github/db-task/fetched
mkdir -p "$OUT"
NOTES="$OUT/crm-snapshot.txt"
: > "$NOTES"

curl -sL --max-time 90 -o "$OUT/live-dashboard.html" https://lvr-data-a60c1.web.app/
echo "dashboard: $(wc -c < "$OUT/live-dashboard.html") bytes  $(grep -ao 'APP_VERSION=[0-9]*' "$OUT/live-dashboard.html" | head -1)" >> "$NOTES"
curl -sI --max-time 30 https://lvr-data-a60c1.web.app/ | grep -i 'content-security-policy\|cache-control' >> "$NOTES"

for f in gate.js version.json; do
  curl -sL --max-time 60 -o "$OUT/dash-$f" "https://lvr-data-a60c1.web.app/$f"
  echo "$f: $(wc -c < "$OUT/dash-$f") bytes" >> "$NOTES"
done

# what the CRM actually stores, and how much of it there is
DB=https://lvr-data-a60c1-default-rtdb.firebaseio.com
for NODE in dashboard/customrecords dashboard_crec dashboard_exp_crec dashboard_adv_crec; do
  N=$(curl -s --max-time 60 "$DB/$NODE.json?shallow=true" | python3 -c "
import json,sys
try:
  d=json.load(sys.stdin); print(len(d) if isinstance(d,dict) else 'n/a')
except Exception as e: print('err')")
  echo "$NODE keys: $N" >> "$NOTES"
done

# the CRM customer list lives inside a record - find where
curl -s --max-time 90 "$DB/dashboard/customrecords.json" -o /tmp/cust.json
echo "customrecords: $(wc -c < /tmp/cust.json) bytes" >> "$NOTES"
python3 - >> "$NOTES" 2>&1 <<'PY'
import json
d=json.load(open('/tmp/cust.json'))
if isinstance(d,dict): items=list(d.items())
else: items=list(enumerate(d or []))
print("records:",len(items))
for k,v in items:
    if isinstance(v,dict) and 'crmcustomers' in v:
        c=v.get('crmcustomers') or []
        print("  crmcustomers in record",k,"->",len(c),"customers")
        keys=set()
        for cu in c[:400]:
            if isinstance(cu,dict): keys|=set(cu.keys())
        print("  fields:",sorted(keys))
        # how full is each field
        import collections
        cnt=collections.Counter()
        for cu in c:
            if isinstance(cu,dict):
                for kk,vv in cu.items():
                    if vv not in (None,"",[],{}): cnt[kk]+=1
        print("  filled:",dict(cnt.most_common()))
PY

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -A "$OUT"
git commit -m "snapshot: live dashboard + CRM data shape" || { echo "nothing to commit"; exit 0; }
for i in 1 2 3 4; do git push origin HEAD:claude/master-file-e6ofy0 && break; sleep $((i*3)); git pull --rebase origin claude/master-file-e6ofy0; done
cat "$NOTES"
