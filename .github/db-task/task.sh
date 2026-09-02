#!/bin/bash
# Where do the CRM customers actually live, and how many are there?
# The owner dashboard saves the whole record to /dashboard.json, so crmcustomers
# sits at dashboard/crmcustomers - not under dashboard/customrecords.
set +e
DB=https://lvr-data-a60c1-default-rtdb.firebaseio.com
OUT=.github/db-task/fetched
NOTES="$OUT/crm-data.txt"
mkdir -p "$OUT"; : > "$NOTES"

for ROOT in dashboard dashboard_friend company_dashboard lvr_rewards; do
  echo "== $ROOT ==" >> "$NOTES"
  curl -s --max-time 60 "$DB/$ROOT.json?shallow=true" -o /tmp/s.json
  python3 - "$ROOT" >> "$NOTES" 2>&1 <<'PY'
import json,sys
try: d=json.load(open('/tmp/s.json'))
except Exception as e: print("  unreadable:",e); raise SystemExit
print("  keys:", sorted(d.keys()) if isinstance(d,dict) else type(d).__name__)
PY
  curl -s --max-time 90 "$DB/$ROOT/crmcustomers.json" -o /tmp/c.json
  python3 >> "$NOTES" 2>&1 <<'PY'
import json,collections,re
try: c=json.load(open('/tmp/c.json'))
except Exception as e: print("  crmcustomers: unreadable",e); raise SystemExit
if not c: print("  crmcustomers: EMPTY/null"); raise SystemExit
if isinstance(c,dict): c=[v for v in c.values() if isinstance(v,dict)]
print("  crmcustomers:",len(c),"records")
fields=collections.Counter(); filled=collections.Counter()
ids=collections.Counter(); dupes=collections.Counter()
for cu in c:
    if not isinstance(cu,dict): continue
    ids[str(cu.get('id'))]+=1
    nm=(cu.get('name') or '').strip().lower()
    if nm: dupes[nm]+=1
    for k,v in cu.items():
        fields[k]+=1
        if v not in (None,'',[],{},0,False): filled[k]+=1
print("  fields present:",dict(fields.most_common()))
print("  fields filled :",dict(filled.most_common()))
rep=[i for i,n in ids.items() if n>1]
print("  duplicate ids:",rep[:20] or "none")
dn=[n for n,k in dupes.items() if k>1]
print("  duplicate names:",dn[:20] or "none")
PY
done

# every top-level node, so nothing is missed
curl -s --max-time 60 "$DB/.json?shallow=true" -o /tmp/root.json
echo "== root nodes ==" >> "$NOTES"
python3 -c "
import json;d=json.load(open('/tmp/root.json'))
print('  '+', '.join(sorted(d.keys())))" >> "$NOTES" 2>&1

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -A "$OUT"
git commit -m "snapshot: where the CRM customers live" || { echo "nothing to commit"; exit 0; }
for i in 1 2 3 4; do git push origin HEAD:claude/master-file-e6ofy0 && break; sleep $((i*3)); git pull --rebase origin claude/master-file-e6ofy0; done
cat "$NOTES"
