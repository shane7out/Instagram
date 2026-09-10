#!/bin/bash
# Analysis only - nothing is written or deleted.
#  1) find duplicates across the master database, graded by how certain they are
#  2) inventory the Bad IG list so the handle-hunt can be scoped
#  3) probe whether the runner can reach the web well enough to find handles
set +e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
OUT=.github/db-task/fetched
mkdir -p "$OUT"
NOTES="$OUT/dupes-and-badig.txt"
: > "$NOTES"
UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36'

for N in dashboard_crec dashboard/customrecords dashboard/badig dashboard/deleted dashboard/igovr dashboard/nameoverride; do
  F=$(echo "$N" | tr '/' '_')
  curl -s --max-time 120 "$DB/$N.json" -o "/tmp/$F.json"
  echo "$N -> $(wc -c < "/tmp/$F.json") bytes" >> "$NOTES"
done

python3 >> "$NOTES" 2>&1 <<'PY'
import json, re, collections

def load(p):
    try: d=json.load(open(p))
    except Exception: return None
    return d

def rows(d):
    if isinstance(d,dict): return [v for v in d.values() if isinstance(v,dict)]
    if isinstance(d,list): return [v for v in d if isinstance(v,dict)]
    return []

crec = rows(load('/tmp/dashboard_crec.json'))
cust = rows(load('/tmp/dashboard_customrecords.json'))
badig = load('/tmp/dashboard_badig.json') or {}
deleted = load('/tmp/dashboard_deleted.json') or {}
igovr = load('/tmp/dashboard_igovr.json') or {}

print("\n==== sizes ====")
print("dashboard_crec        :", len(crec))
print("customrecords         :", len(cust))
print("badig entries         :", len(badig) if isinstance(badig,dict) else 'n/a')
print("deleted entries       :", len(deleted) if isinstance(deleted,dict) else 'n/a')
print("igovr (IG overrides)  :", len(igovr) if isinstance(igovr,dict) else 'n/a')

def dnum(n):
    try: return int(n)
    except Exception: return None
delset = set()
if isinstance(deleted,dict):
    for k,v in deleted.items():
        if v:
            n=dnum(k)
            if n is not None: delset.add(n)

# ---- build the live record set (excluding deleted) --------------------------
live=[]
for src,label in ((crec,'crec'),(cust,'cust')):
    for r in src:
        n=r.get('num')
        if not isinstance(n,int): continue
        if n in delset: continue
        r=dict(r); r['_src']=label
        live.append(r)
print("live records (deleted excluded):", len(live))

def nig(v): return re.sub(r'^@','',str(v or '').strip().lower())
def nnm(v): return re.sub(r'[^a-z0-9]','',str(v or '').lower())

# ---- duplicate grading ------------------------------------------------------
by_ig, by_nm = collections.defaultdict(list), collections.defaultdict(list)
for r in live:
    ig = nig(r.get('instagram') or r.get('igHandle'))
    nm = nnm(r.get('name'))
    if ig: by_ig[ig].append(r)
    if nm: by_nm[nm].append(r)

ig_dupes  = {k:v for k,v in by_ig.items() if len(v)>1}
nm_dupes  = {k:v for k,v in by_nm.items() if len(v)>1}

# certain: same IG handle AND same normalised name
certain, ig_only, nm_only = [], [], []
seen_groups=set()
for ig,g in ig_dupes.items():
    names={nnm(r.get('name')) for r in g}
    key=tuple(sorted(r['num'] for r in g))
    seen_groups.add(key)
    (certain if len(names)==1 else ig_only).append((ig,g))
for nm,g in nm_dupes.items():
    key=tuple(sorted(r['num'] for r in g))
    if key in seen_groups: continue
    igs={nig(r.get('instagram') or r.get('igHandle')) for r in g}
    if len(igs)>1: nm_only.append((nm,g))

def extra(g):  # how many rows beyond the one we keep
    return len(g)-1

print("\n==== DUPLICATES ====")
print("A. same IG handle AND same name  : %d groups, %d rows would be removed"
      % (len(certain), sum(extra(g) for _,g in certain)))
print("B. same IG handle, different name: %d groups, %d rows"
      % (len(ig_only), sum(extra(g) for _,g in ig_only)))
print("C. same name, different IG       : %d groups, %d rows"
      % (len(nm_only), sum(extra(g) for _,g in nm_only)))

def show(title, groups, limit=25, keyname='key'):
    print("\n---- %s (showing %d of %d) ----" % (title, min(limit,len(groups)), len(groups)))
    for k,g in sorted(groups, key=lambda t: -len(t[1]))[:limit]:
        g2=sorted(g, key=lambda r: r['num'])
        print("  %s  x%d" % (k[:34], len(g2)))
        for r in g2:
            print("      %-7s %-40s @%-26s %s" % (r['num'], str(r.get('name'))[:40],
                  nig(r.get('instagram') or r.get('igHandle'))[:26], r['_src']))

show("A. same IG + same name  (safe to collapse)", certain, 20)
show("B. same IG, different name  (check these)", ig_only, 20)
show("C. same name, different IG  (check these)", nm_only, 20)

# how many rows sit in BOTH crec and customrecords with the same num?
bynum=collections.defaultdict(list)
for r in live: bynum[r['num']].append(r)
same_num=[(n,g) for n,g in bynum.items() if len(g)>1]
print("\n==== same record number appearing twice ====")
print("  %d numbers appear more than once" % len(same_num))
srcs=collections.Counter()
for n,g in same_num: srcs[tuple(sorted(r['_src'] for r in g))]+=1
print("  by source pair:", dict(srcs))

# ---- BAD IG -----------------------------------------------------------------
print("\n==== BAD IG ====")
bad_nums=set()
if isinstance(badig,dict):
    for k,v in badig.items():
        if v:
            n=dnum(k)
            if n is not None: bad_nums.add(n)
print("flagged bad-IG record numbers:", len(bad_nums))
bad_live=[r for r in live if r['num'] in bad_nums]
# dedupe by num for reporting
seen=set(); bl=[]
for r in bad_live:
    if r['num'] in seen: continue
    seen.add(r['num']); bl.append(r)
print("of those, still live (not deleted):", len(bl))
haswebsite=sum(1 for r in bl if re.search(r'https?://|www\.', str(r.get('notes') or '')+str(r.get('address') or '')))
print("with something website-ish in notes/address:", haswebsite)
withovr=sum(1 for r in bl if str(r['num']) in (igovr if isinstance(igovr,dict) else {}))
print("already carrying an IG override:", withovr)
print("\nfirst 40 bad-IG records:")
for r in bl[:40]:
    print("  %-7s %-42s @%-26s %s" % (r['num'], str(r.get('name'))[:42],
          nig(r.get('instagram') or r.get('igHandle'))[:26],
          re.sub(r'\s+',' ',str(r.get('notes') or ''))[:44]))
PY

# ---- can the runner actually look things up? --------------------------------
echo "" >> "$NOTES"
echo "==== web reachability from the runner ====" >> "$NOTES"
probe () {
  C=$(curl -sL -A "$UA" --max-time 30 -o /tmp/p.html -w '%{http_code}' "$1")
  echo "  $2 -> http=$C bytes=$(wc -c </tmp/p.html 2>/dev/null||echo 0)" >> "$NOTES"
}
probe "https://duckduckgo.com/html/?q=herbs+and+rye+las+vegas+instagram" "duckduckgo html"
probe "https://lite.duckduckgo.com/lite/?q=herbs+and+rye+las+vegas+instagram" "duckduckgo lite"
probe "https://www.bing.com/search?q=herbs+and+rye+las+vegas+instagram" "bing"
probe "https://search.marcia.cc/search?q=test" "(control, expected fail)"
probe "https://www.instagram.com/herbsandrye/" "instagram profile"
probe "https://herbsandrye.com/" "a restaurant website"

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -A "$OUT"
git commit -m "report: duplicates, bad-IG inventory, runner web reachability" || { echo "nothing to commit"; exit 0; }
for i in 1 2 3 4; do git push origin HEAD:claude/master-file-e6ofy0 && break; sleep $((i*3)); git pull --rebase origin claude/master-file-e6ofy0; done
cat "$NOTES"
