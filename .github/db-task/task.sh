#!/bin/bash
# Diagnose: Deals page shows the date/time (page shell) but no listings.
# Read-only. Checks:
#  1) is the scheduled refresh workflow actually still running/succeeding
#  2) what /_deals/updated and /_deals/removed say
#  3) what /cars.json actually contains, and how many survive the client
#     rules (removed + >30 days old) that would leave the grid empty
set +e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
LIVE="https://classiccarsforsale-co.web.app"
OUT=.github/db-task/fetched
mkdir -p "$OUT"
NOTES="$OUT/deals-diagnosis.txt"
: > "$NOTES"

echo "== live site reachability ==" >> "$NOTES"
curl -s -o /tmp/live.html -w "  /?ci=  http=%{http_code} bytes=%{size_download}\n" --max-time 30 "$LIVE/?ci=" >> "$NOTES"
curl -s -o /tmp/cars.json -w "  /cars.json  http=%{http_code} bytes=%{size_download}\n" --max-time 30 "$LIVE/cars.json" >> "$NOTES"
curl -s -o /tmp/refreshjs.js -w "  /deals-refresh.js  http=%{http_code} bytes=%{size_download}\n" --max-time 30 "$LIVE/deals-refresh.js" >> "$NOTES"

echo "" >> "$NOTES"
echo "== Firebase _deals state ==" >> "$NOTES"
curl -s --max-time 20 "$DB/_deals/updated.json" >> "$NOTES"; echo " <- updated (ms epoch)" >> "$NOTES"
curl -s --max-time 20 "$DB/_deals/refresh_request.json" >> "$NOTES"; echo " <- last refresh_request (ms epoch)" >> "$NOTES"
curl -s --max-time 20 "$DB/_deals/removed.json" -o /tmp/removed.json
echo "  removed.json: $(wc -c < /tmp/removed.json) bytes, $(python3 -c "import json;d=json.load(open('/tmp/removed.json'));print(len(d) if isinstance(d,dict) else 0)" 2>/dev/null) keys" >> "$NOTES"

python3 >> "$NOTES" 2>&1 <<'PY'
import json, time, datetime, re

print("\n== timestamp sanity ==")
try:
    upd = json.load(open('/tmp/removed.json'))  # placeholder, real value pulled separately below
except Exception:
    pass

def get_ms(url_result_path):
    try:
        v = open(url_result_path).read().strip()
        return int(v)
    except Exception:
        return None

# re-fetch directly since we only echoed them into the text log above
import subprocess
def curlget(path):
    r = subprocess.run(['curl','-s','--max-time','20', 'https://lvr-data-a60c1-default-rtdb.firebaseio.com'+path], capture_output=True, text=True)
    return r.stdout.strip()

updated_raw = curlget('/_deals/updated.json')
req_raw = curlget('/_deals/refresh_request.json')
now = time.time()*1000
def fmt(raw, label):
    try:
        v = float(raw)
        age_h = (now - v) / 3600000
        print("%s: %s  ->  %s UTC  (%.1f hours ago)" % (label, raw, datetime.datetime.utcfromtimestamp(v/1000), age_h))
    except Exception as e:
        print("%s: could not parse (%r) - %s" % (label, raw, e))
fmt(updated_raw, "_deals/updated")
fmt(req_raw, "_deals/refresh_request")

print("\n== cars.json content ==")
try:
    cars = json.load(open('/tmp/cars.json'))
except Exception as e:
    print("UNREADABLE:", e)
    cars = None
if isinstance(cars, list):
    print("total entries in cars.json:", len(cars))
    removed = {}
    try:
        removed = json.load(open('/tmp/removed.json')) or {}
    except Exception:
        pass
    def age_days(c):
        t = c.get('postedTs') or c.get('addedTs') or c.get('added')
        if not t: return None
        try:
            # could be ms epoch or ISO string
            if isinstance(t,(int,float)) or (isinstance(t,str) and t.isdigit()):
                v = float(t)
                if v > 1e12: pass
                elif v > 1e9: v *= 1000
                d = datetime.datetime.utcfromtimestamp(v/1000)
            else:
                d = datetime.datetime.fromisoformat(t.replace('Z','+00:00')).replace(tzinfo=None)
            return (datetime.datetime.utcnow() - d).days
        except Exception:
            return None
    removed_ct = sum(1 for c in cars if isinstance(c,dict) and removed.get(c.get('slug')))
    ages = [age_days(c) for c in cars if isinstance(c,dict)]
    old_ct = sum(1 for a in ages if a is not None and a > 30)
    none_ct = sum(1 for a in ages if a is None)
    survivors = len(cars) - removed_ct - old_ct  # rough (some overlap possible)
    print("marked removed (sold/expired):", removed_ct)
    print("older than 30 days (by client rule):", old_ct)
    print("no parseable age at all:", none_ct)
    print("would survive both rules (rough):", max(0, survivors))
    print("\nfirst 5 raw entries (trimmed):")
    for c in cars[:5]:
        if isinstance(c, dict):
            print("  ", {k: c.get(k) for k in ('slug','type','postedTs','addedTs','added','url') if k in c})
elif isinstance(cars, dict):
    print("cars.json is an OBJECT, not a list. keys:", list(cars.keys())[:10])
else:
    print("cars.json parsed as:", type(cars))
PY

echo "" >> "$NOTES"
echo "== live page: does it even reference cars.json / deals-refresh.js? ==" >> "$NOTES"
grep -c 'cars\.json' /tmp/live.html >> "$NOTES"
grep -c 'deals-refresh\.js' /tmp/live.html >> "$NOTES"
grep -c 'id="grid"' /tmp/live.html >> "$NOTES"
grep -c 'id="lastupd"' /tmp/live.html >> "$NOTES"
grep -oE 'article class="card[^"]*"' /tmp/live.html | wc -l >> "$NOTES"
echo "  ^ counts, in order: cars.json refs, deals-refresh.js refs, #grid present, #lastupd present, <article class=card> count in the STATIC html (0 is normal if built client-side)" >> "$NOTES"

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -A "$OUT"
git commit -m "diagnose: Deals page showing header but no listings" || { echo "nothing to commit"; exit 0; }
for i in 1 2 3 4; do git push origin HEAD:claude/master-file-e6ofy0 && break; sleep $((i*3)); git pull --rebase origin claude/master-file-e6ofy0; done
cat "$NOTES"
