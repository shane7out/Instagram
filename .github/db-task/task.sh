#!/bin/bash
# Verify: are all 487 seeded staging restaurants marked removed, and do the
# rsremoved keys line up exactly with the staging nums 20001..20487?
set +e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
OUT=.github/db-task/fetched
NOTES="$OUT/rsremoved-check.txt"
mkdir -p "$OUT"; : > "$NOTES"

curl -s --max-time 90 "$DB/dashboard/rsremoved.json" -o /tmp/rsrm.json
curl -s --max-time 90 "$DB/dashboard_friend/rsremoved.json" -o /tmp/rsrm_friend.json
echo "rsremoved: $(wc -c </tmp/rsrm.json) bytes | friend: $(wc -c </tmp/rsrm_friend.json) bytes" >> "$NOTES"

python3 >> "$NOTES" 2>&1 <<'PY'
import json, re
def loadmap(p):
    try: d=json.load(open(p))
    except Exception: return {}
    return d if isinstance(d,dict) else {}
rm = loadmap('/tmp/rsrm.json')
rmf = loadmap('/tmp/rsrm_friend.json')
keys = set()
for k in rm.keys():
    try: keys.add(int(k))
    except Exception: pass
print("rsremoved entries          :", len(rm))
print("numeric keys               :", len(keys))
if keys:
    print("key range                  : %d .. %d" % (min(keys), max(keys)))
staging = set(range(20001, 20488))
print("staging nums 20001..20487  :", len(staging))
print("staging nums marked removed:", len(staging & keys))
print("staging nums still live    :", len(staging - keys))
extra = keys - staging
print("rsremoved keys OUTSIDE the staging range:", len(extra), sorted(extra)[:20])
print("\nsample of the values stored:", dict(list(rm.items())[:5]))
print("\nfriend rsremoved entries   :", len(rmf))
print("\n==> live staging queue size =", len(staging - keys))
PY

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -A "$OUT"
git commit -m "verify: rsremoved covers the whole seeded staging list" || { echo "nothing to commit"; exit 0; }
for i in 1 2 3 4; do git push origin HEAD:claude/master-file-e6ofy0 && break; sleep $((i*3)); git pull --rebase origin claude/master-file-e6ofy0; done
cat "$NOTES"
