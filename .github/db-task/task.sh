#!/bin/bash
# Duplicates, done properly.
# dashboard_crec is a complete mirror of customrecords - all 815 of its records
# appear there under the same num. That is one record stored in two places, not
# a duplicate. So: collapse by num first, THEN look for the same restaurant
# sitting under two different numbers. Read-only.
set +e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
OUT=.github/db-task/fetched
mkdir -p "$OUT"
NOTES="$OUT/dupes-real.txt"
: > "$NOTES"

curl -s --max-time 120 "$DB/dashboard_crec.json"          -o /tmp/crec.json
curl -s --max-time 120 "$DB/dashboard/customrecords.json" -o /tmp/cust.json
curl -s --max-time 120 "$DB/dashboard/deleted.json"       -o /tmp/del.json
curl -s --max-time 120 "$DB/dashboard/badig.json"         -o /tmp/badig.json

python3 >> "$NOTES" 2>&1 <<'PY'
import json, re, collections

def load(p):
    try: return json.load(open(p))
    except Exception: return None
def rows(d):
    if isinstance(d,dict): return [v for v in d.values() if isinstance(v,dict)]
    if isinstance(d,list): return [v for v in d if isinstance(v,dict)]
    return []

crec=rows(load('/tmp/crec.json')); cust=rows(load('/tmp/cust.json'))
deleted=load('/tmp/del.json') or {}; badig=load('/tmp/badig.json') or {}

def toint(x):
    try: return int(x)
    except Exception: return None
delset={n for n in (toint(k) for k,v in deleted.items() if v) if n is not None}
badset={n for n in (toint(k) for k,v in badig.items() if v) if n is not None}

def nig(v): return re.sub(r'^@','',str(v or '').strip().lower())
def nnm(v): return re.sub(r'[^a-z0-9]','',str(v or '').lower())

# --- collapse by num: crec and customrecords hold the same record ------------
byn={}
for src,label in ((cust,'cust'),(crec,'crec')):
    for r in src:
        n=r.get('num')
        if not isinstance(n,int) or n in delset: continue
        if n not in byn:
            r=dict(r); r['_in']={label}; byn[n]=r
        else:
            byn[n]['_in'].add(label)
            for k,v in r.items():
                if k!='num' and not byn[n].get(k) and v: byn[n][k]=v

recs=list(byn.values())
print("unique live records (by num): %d" % len(recs))
print("  in both nodes : %d" % sum(1 for r in recs if len(r['_in'])==2))
print("  customrecords only: %d" % sum(1 for r in recs if r['_in']=={'cust'}))
print("  dashboard_crec only: %d" % sum(1 for r in recs if r['_in']=={'crec'}))

# --- now the real duplicates: one restaurant, two numbers -------------------
by_ig=collections.defaultdict(list); by_nm=collections.defaultdict(list)
for r in recs:
    ig=nig(r.get('instagram') or r.get('igHandle')); nm=nnm(r.get('name'))
    if ig: by_ig[ig].append(r)
    if nm: by_nm[nm].append(r)

ig_groups=[(k,v) for k,v in by_ig.items() if len(v)>1]
nm_groups=[(k,v) for k,v in by_nm.items() if len(v)>1]

covered=set()
tierA=[]   # same IG and same name  -> certain
tierB=[]   # same IG, different name
for k,g in ig_groups:
    covered.add(tuple(sorted(r['num'] for r in g)))
    (tierA if len({nnm(r.get('name')) for r in g})==1 else tierB).append((k,g))
tierC=[]   # same name, different IG
for k,g in nm_groups:
    if tuple(sorted(r['num'] for r in g)) in covered: continue
    tierC.append((k,g))

def rm(groups): return sum(len(g)-1 for _,g in groups)
print("\n==== REAL DUPLICATES (one restaurant, two record numbers) ====")
print("A. same IG + same name      : %3d groups -> %3d rows to delete" % (len(tierA), rm(tierA)))
print("B. same IG, different name  : %3d groups -> %3d rows" % (len(tierB), rm(tierB)))
print("C. same name, different IG  : %3d groups -> %3d rows" % (len(tierC), rm(tierC)))
print("                              TOTAL removable: %d" % (rm(tierA)+rm(tierB)+rm(tierC)))

def keeper(g):
    # keep the richest record; break ties on the lower num
    def score(r):
        return (sum(1 for k in ('phone','email','address','cuisine','owner','notes') if str(r.get(k) or '').strip()),
                -r['num'])
    return sorted(g, key=score, reverse=True)[0]

def dump(title, groups, limit=None):
    print("\n---- %s (%d groups) ----" % (title, len(groups)))
    for k,g in sorted(groups, key=lambda t: min(r['num'] for r in t[1]))[:limit or len(groups)]:
        kp=keeper(g)
        print("  %s" % k[:40])
        for r in sorted(g, key=lambda r: r['num']):
            mark = 'KEEP  ' if r['num']==kp['num'] else 'delete'
            flags=[]
            if r['num'] in badset: flags.append('badIG')
            if len(r['_in'])==2: flags.append('both')
            else: flags.append(list(r['_in'])[0])
            fields=sum(1 for kk in ('phone','email','address','cuisine','owner','notes') if str(r.get(kk) or '').strip())
            print("      %s %-7s %-38s @%-24s %dfld %s" % (mark, r['num'], str(r.get('name'))[:38],
                  nig(r.get('instagram') or r.get('igHandle'))[:24], fields, ','.join(flags)))

dump("A. same IG + same name", tierA)
dump("B. same IG, different name", tierB)
dump("C. same name, different IG", tierC)

# the delete list, ready to act on
delA=[r['num'] for _,g in tierA for r in g if r['num']!=keeper(g)['num']]
delB=[r['num'] for _,g in tierB for r in g if r['num']!=keeper(g)['num']]
delC=[r['num'] for _,g in tierC for r in g if r['num']!=keeper(g)['num']]
print("\n==== proposed delete lists ====")
print("A:", sorted(delA))
print("B:", sorted(delB))
print("C:", sorted(delC))
json.dump({'A':sorted(delA),'B':sorted(delB),'C':sorted(delC)},
          open('.github/db-task/fetched/dupe-delete-list.json','w'), indent=1)
PY

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -A "$OUT"
git commit -m "report: real duplicates, collapsed by record number" || { echo "nothing to commit"; exit 0; }
for i in 1 2 3 4; do git push origin HEAD:claude/master-file-e6ofy0 && break; sleep $((i*3)); git pull --rebase origin claude/master-file-e6ofy0; done
cat "$NOTES"
