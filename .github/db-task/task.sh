#!/bin/bash
# Back up both record nodes into the repo before any deletion, and report the
# exact container type so the delete is written correctly (an array and an
# object need different PATCH shapes). Read-only against Firebase.
set +e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
BK=.github/db-task/backups
OUT=.github/db-task/fetched
mkdir -p "$BK" "$OUT"
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
NOTES="$OUT/backup-and-shape.txt"
: > "$NOTES"

for N in dashboard_crec dashboard/customrecords dashboard/deleted dashboard/badig dashboard/igovr; do
  F=$(echo "$N" | tr '/' '_')
  curl -s --max-time 150 "$DB/$N.json" -o "$BK/${F}.${STAMP}.json"
  echo "$N -> $BK/${F}.${STAMP}.json  ($(wc -c < "$BK/${F}.${STAMP}.json") bytes)" >> "$NOTES"
done

python3 "$STAMP" >> "$NOTES" 2>&1 <<'PY'
import json, sys, collections
stamp = sys.argv[1]
BK = '.github/db-task/backups/'
def peek(name, path):
    try: d = json.load(open(path))
    except Exception as e:
        print("%-24s UNREADABLE %s" % (name, e)); return None
    t = type(d).__name__
    n = len(d) if hasattr(d, '__len__') else 0
    print("%-24s %-6s len=%d" % (name, t, n))
    if isinstance(d, list):
        holes = sum(1 for x in d if x is None)
        print("    LIST - index positions matter. null holes: %d" % holes)
        idx = [i for i, x in enumerate(d) if isinstance(x, dict)][:3]
        for i in idx: print("      [%d] num=%s name=%s" % (i, d[i].get('num'), d[i].get('name')))
    elif isinstance(d, dict):
        ks = list(d.keys())[:5]
        print("    DICT - keys are addressable. sample keys: %s" % ks)
        for k in ks[:3]:
            v = d[k]
            if isinstance(v, dict): print("      %s -> num=%s name=%s" % (k, v.get('num'), v.get('name')))
    return d

print("\n==== container shapes ====")
crec = peek('dashboard_crec',   BK+'dashboard_crec.%s.json' % stamp)
cust = peek('customrecords',    BK+'dashboard_customrecords.%s.json' % stamp)
peek('deleted',                 BK+'dashboard_deleted.%s.json' % stamp)
peek('badig',                   BK+'dashboard_badig.%s.json' % stamp)
peek('igovr',                   BK+'dashboard_igovr.%s.json' % stamp)

# which key holds each of the numbers we want gone?
TARGETS = [50801, 50808, 50809]
print("\n==== where the tier-A duplicates live ====")
for name, d in (('dashboard_crec', crec), ('customrecords', cust)):
    if d is None: continue
    items = d.items() if isinstance(d, dict) else enumerate(d)
    hits = {}
    for k, v in items:
        if isinstance(v, dict) and v.get('num') in TARGETS:
            hits.setdefault(v['num'], []).append(k)
    print("  %-16s %s" % (name, hits or 'none'))

print("\n==== the two tier-C groups, in full ====")
for name, d in (('customrecords', cust),):
    if d is None: continue
    items = d.items() if isinstance(d, dict) else enumerate(d)
    for k, v in items:
        if isinstance(v, dict) and v.get('num') in (1358, 50913, 50465, 50867):
            print("  key=%s %s" % (k, json.dumps(v)[:300]))
PY

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -A "$BK" "$OUT"
git commit -m "backup: record nodes before duplicate removal ($STAMP)" || { echo "nothing to commit"; exit 0; }
for i in 1 2 3 4; do git push origin HEAD:claude/master-file-e6ofy0 && break; sleep $((i*3)); git pull --rebase origin claude/master-file-e6ofy0; done
cat "$NOTES"
