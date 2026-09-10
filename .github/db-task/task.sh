#!/bin/bash
# Two questions:
#  1) which restaurants in the database look recently opened AND have an IG handle
#  2) what shape does the existing advertiser staging use, so a restaurant
#     staging can match it rather than inventing a new one
set +e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
OUT=.github/db-task/fetched
mkdir -p "$OUT"
NOTES="$OUT/new-restaurants.txt"
: > "$NOTES"

curl -s --max-time 120 "$DB/dashboard_crec.json"          -o /tmp/crec.json
curl -s --max-time 120 "$DB/dashboard/customrecords.json" -o /tmp/cust.json
curl -s --max-time 120 "$DB/dashboard_adv_stg_crec.json"  -o /tmp/advstg.json
curl -s --max-time 120 "$DB/dashboard_adv_crec.json"      -o /tmp/adv.json
echo "crec $(wc -c </tmp/crec.json)  cust $(wc -c </tmp/cust.json)  advstg $(wc -c </tmp/advstg.json)  adv $(wc -c </tmp/adv.json)" >> "$NOTES"

python3 >> "$NOTES" 2>&1 <<'PY'
import json, re, collections

def load(p):
    try: d=json.load(open(p))
    except Exception as e: return []
    if isinstance(d,dict): return [v for v in d.values() if isinstance(v,dict)]
    if isinstance(d,list): return [v for v in d if isinstance(v,dict)]
    return []

crec=load('/tmp/crec.json'); cust=load('/tmp/cust.json')
advstg=load('/tmp/advstg.json'); adv=load('/tmp/adv.json')
print("\n==== counts ====")
print("dashboard_crec           :",len(crec))
print("dashboard/customrecords  :",len(cust))
print("dashboard_adv_crec       :",len(adv))
print("dashboard_adv_stg_crec   :",len(advstg))

def schema(rows,label,top=30):
    c=collections.Counter()
    for r in rows:
        for k in r.keys(): c[k]+=1
    print("\n---- fields in %s (n=%d) ----"%(label,len(rows)))
    for k,n in c.most_common(top):
        print("   %-22s %5d  (%d%%)"%(k,n,round(100*n/max(1,len(rows)))))

schema(crec,'dashboard_crec')
schema(advstg,'dashboard_adv_stg_crec')

print("\n---- a sample advertiser-staging record ----")
if advstg:
    print(json.dumps(advstg[0],indent=2)[:1200])
else:
    print("   (staging node is empty)")

# ---- which restaurants read as recently opened? ------------------------------
ALL = crec + cust
by_ig = [r for r in ALL if str(r.get('instagram') or r.get('igHandle') or '').strip().startswith('@')]
print("\n==== restaurants with an IG handle: %d of %d ===="%(len(by_ig),len(ALL)))

NEWISH = re.compile(r'\b(now open|newly opened|new(?:ly)? open|grand opening|just opened|opened in|opening soon|coming soon|soft open|new location|brand new|all new)\b', re.I)
YEAR   = re.compile(r'\b(2025|2026)\b')

hits=[]
for r in ALL:
    ig = str(r.get('instagram') or r.get('igHandle') or '').strip()
    if not ig.startswith('@'): continue
    blob = ' '.join(str(r.get(k) or '') for k in ('notes','name','desc','description','status','tags'))
    m = NEWISH.search(blob)
    y = YEAR.search(blob)
    if m or y:
        hits.append((r.get('num'), r.get('name'), ig, (m.group(0) if m else ''), (y.group(0) if y else ''),
                     re.sub(r'\s+',' ',str(r.get('notes') or ''))[:150]))

hits.sort(key=lambda t: (t[0] if isinstance(t[0],int) else 0), reverse=True)
print("\n==== flagged as recently opened / dated 2025-2026 (%d) ===="%len(hits))
for num,name,ig,kw,yr,notes in hits[:60]:
    print("  %-7s %-38s %-28s %-14s %s"%(num,str(name)[:38],ig[:28],(kw or yr),notes[:90]))

# ---- newest additions by num, as a proxy for "lately" ------------------------
numbered=[r for r in ALL if isinstance(r.get('num'),int)
          and str(r.get('instagram') or r.get('igHandle') or '').strip().startswith('@')]
numbered.sort(key=lambda r: r['num'], reverse=True)
print("\n==== 40 highest-numbered records with an IG handle (most recently added) ====")
seen=set()
shown=0
for r in numbered:
    key=(r.get('name'),r.get('num'))
    if key in seen: continue
    seen.add(key)
    print("  %-7s %-40s %-28s %s"%(r['num'],str(r.get('name'))[:40],
          str(r.get('instagram') or r.get('igHandle'))[:28],
          re.sub(r'\s+',' ',str(r.get('notes') or ''))[:70]))
    shown+=1
    if shown>=40: break

# ---- is there any date field at all to work with? ---------------------------
datefields=collections.Counter()
for r in ALL:
    for k,v in r.items():
        if re.search(r'date|added|created|opened|since|_at$|ts$', k, re.I):
            datefields[k]+=1
print("\n==== any date-ish fields present ====")
print("   ", dict(datefields) or "NONE - the records carry no opened/added date")
PY

echo "" >> "$NOTES"
echo "==== staging nodes that already exist ====" >> "$NOTES"
for N in dashboard_adv_stg_crec dashboard_adv_stg_removed dashboard_rest_stg_crec dashboard_rest_stg_removed; do
  C=$(curl -s --max-time 60 "$DB/$N.json?shallow=true" | python3 -c "
import json,sys
try:
  d=json.load(sys.stdin)
  print(len(d) if isinstance(d,dict) else ('null' if d is None else type(d).__name__))
except Exception: print('err')")
  echo "  $N : $C" >> "$NOTES"
done

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -A "$OUT"
git commit -m "report: recently opened restaurants with IG + staging shape" || { echo "nothing to commit"; exit 0; }
for i in 1 2 3 4; do git push origin HEAD:claude/master-file-e6ofy0 && break; sleep $((i*3)); git pull --rebase origin claude/master-file-e6ofy0; done
cat "$NOTES"
