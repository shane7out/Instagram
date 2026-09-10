#!/bin/bash
# Where did the 487 staging restaurants come from, and how many are genuinely new?
# Cross-check the staging list in seed-data.js against the live main database by
# IG handle and by normalised name.
set +e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
OUT=.github/db-task/fetched
mkdir -p "$OUT"
NOTES="$OUT/staging-overlap.txt"
: > "$NOTES"

curl -s --max-time 120 "$DB/dashboard_crec.json"          -o /tmp/crec.json
curl -s --max-time 120 "$DB/dashboard/customrecords.json" -o /tmp/cust.json
curl -s --max-time 120 "$DB/dashboard/deleted.json"       -o /tmp/del.json
curl -s --max-time 120 "$DB/dashboard/rsremoved.json"     -o /tmp/rsrm.json
echo "crec $(wc -c </tmp/crec.json)  cust $(wc -c </tmp/cust.json)  deleted $(wc -c </tmp/del.json)  rsremoved $(wc -c </tmp/rsrm.json)" >> "$NOTES"

python3 >> "$NOTES" 2>&1 <<'PY'
import json, re, collections

def load(p):
    try: d = json.load(open(p))
    except Exception: return []
    if isinstance(d, dict): return [v for v in d.values() if isinstance(v, dict)]
    if isinstance(d, list): return [v for v in d if isinstance(v, dict)]
    return []

def loadmap(p):
    try: d = json.load(open(p))
    except Exception: return {}
    return d if isinstance(d, dict) else {}

crec = load('/tmp/crec.json'); cust = load('/tmp/cust.json')
deleted = loadmap('/tmp/del.json'); rsrm = loadmap('/tmp/rsrm.json')
main = crec + cust

# --- the staging list out of seed-data.js -------------------------------------
s = open('.github/db-task/fetched/seed-data.js', encoding='utf-8', errors='replace').read()
m = re.search(r'(?:var|let|const)\s+RESTAURANTS_STAGING\s*=\s*\[', s)
i = m.end() - 1; d = 0
for j in range(i, len(s)):
    if s[j] == '[': d += 1
    elif s[j] == ']':
        d -= 1
        if d == 0:
            blob = s[i:j+1]; break

recs = []
for mm in re.finditer(r'\{num:(\d+),([^{}]*)\}', blob):
    num = int(mm.group(1)); body = mm.group(2)
    f = dict(re.findall(r"(\w+):'((?:[^'\\]|\\.)*)'", body))
    f['num'] = num
    recs.append(f)

print("staging records parsed: %d" % len(recs))
print("num range: %d .. %d  (contiguous: %s)" % (
    min(r['num'] for r in recs), max(r['num'] for r in recs),
    len(recs) == max(r['num'] for r in recs) - min(r['num'] for r in recs) + 1))

def norm_ig(v):  return re.sub(r'^@', '', str(v or '')).strip().lower()
def norm_nm(v):  return re.sub(r'[^a-z0-9]', '', str(v or '').lower())

main_ig = {}
main_nm = {}
for r in main:
    ig = norm_ig(r.get('instagram') or r.get('igHandle'))
    nm = norm_nm(r.get('name'))
    if ig: main_ig.setdefault(ig, r)
    if nm: main_nm.setdefault(nm, r)

both = ig_only = nm_only = neither = 0
dupe_rows = []
new_rows = []
for r in recs:
    ig = norm_ig(r.get('ig')); nm = norm_nm(r.get('name'))
    hit_ig = main_ig.get(ig) if ig else None
    hit_nm = main_nm.get(nm) if nm else None
    if hit_ig and hit_nm: both += 1
    elif hit_ig: ig_only += 1
    elif hit_nm: nm_only += 1
    else:
        neither += 1
        new_rows.append(r)
        continue
    dupe_rows.append((r, hit_ig or hit_nm))

print("\n==== how much of the staging queue is already in the main database? ====")
print("  already there (IG and name match) : %d" % both)
print("  already there (IG only)           : %d" % ig_only)
print("  already there (name only)         : %d" % nm_only)
print("  ------------------------------------------")
print("  ALREADY IN MAIN DB                : %d of %d" % (both+ig_only+nm_only, len(recs)))
print("  GENUINELY NEW                     : %d of %d" % (neither, len(recs)))

print("\n==== owner-removed staging entries (dashboard/rsremoved) ====")
print("  entries: %d" % len(rsrm))
still = [r for r in recs if str(r['num']) not in rsrm and r['num'] not in rsrm]
print("  staging records NOT yet removed: %d" % len(still))

print("\n==== cuisine spread of the genuinely-new ones ====")
c = collections.Counter(r.get('cuisine','') for r in new_rows)
for k, n in c.most_common(15):
    print("   %-38s %d" % (k[:38] or '(none)', n))

print("\n==== first 30 genuinely new (not in main db) ====")
for r in new_rows[:30]:
    print("   %-7s %-38s @%-26s %s" % (r['num'], str(r.get('name'))[:38],
          str(r.get('ig'))[:26], str(r.get('cuisine'))[:24]))

print("\n==== data quality inside the staging list ====")
missing = collections.Counter()
for r in recs:
    for k in ('name','ig','phone','email','cuisine','address'):
        if not str(r.get(k) or '').strip(): missing[k] += 1
print("  blank fields:", dict(missing) or "none - every field populated on all 487")
igs = collections.Counter(norm_ig(r.get('ig')) for r in recs)
dup_ig = [k for k, n in igs.items() if n > 1 and k]
print("  duplicate IG handles inside staging:", dup_ig[:20] or "none")
nms = collections.Counter(norm_nm(r.get('name')) for r in recs)
dup_nm = [k for k, n in nms.items() if n > 1 and k]
print("  duplicate names inside staging:", dup_nm[:20] or "none")
nums = collections.Counter(r['num'] for r in recs)
print("  duplicate nums inside staging:", [k for k,n in nums.items() if n>1][:10] or "none")

# do any staging nums collide with main-db nums? that would break promotion
main_nums = set()
for r in main:
    if isinstance(r.get('num'), int): main_nums.add(r['num'])
collide = sorted(set(r['num'] for r in recs) & main_nums)
print("  staging nums colliding with main-db nums:", collide[:20] or "none")
PY

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -A "$OUT"
git commit -m "report: staging queue overlap with the main database" || { echo "nothing to commit"; exit 0; }
for i in 1 2 3 4; do git push origin HEAD:claude/master-file-e6ofy0 && break; sleep $((i*3)); git pull --rebase origin claude/master-file-e6ofy0; done
cat "$NOTES"
