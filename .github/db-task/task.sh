#!/bin/bash
# How big is the existing restaurant staging queue, and what shape are its records?
# It lives in seed-data.js (a static file), not in Firebase like the advertiser staging.
set +e
OUT=.github/db-task/fetched
mkdir -p "$OUT"
NOTES="$OUT/rs-staging.txt"
: > "$NOTES"

curl -sL --max-time 120 "https://lvr-data-a60c1.web.app/seed-data.js" -o "$OUT/seed-data.js"
echo "seed-data.js: $(wc -c < "$OUT/seed-data.js") bytes" >> "$NOTES"

python3 >> "$NOTES" 2>&1 <<'PY'
import re, json, collections
s = open('.github/db-task/fetched/seed-data.js', encoding='utf-8', errors='replace').read()
print("top-level arrays declared:")
for m in re.finditer(r'(?:var|let|const)\s+([A-Z_][A-Z0-9_]*)\s*=\s*\[', s):
    print("   ", m.group(1))

m = re.search(r'(?:var|let|const)\s+RESTAURANTS_STAGING\s*=\s*\[', s)
if not m:
    print("\nRESTAURANTS_STAGING not found in seed-data.js")
    raise SystemExit
i = m.end() - 1
d = 0
for j in range(i, len(s)):
    if s[j] == '[': d += 1
    elif s[j] == ']':
        d -= 1
        if d == 0:
            blob = s[i:j+1]
            break
print("\nRESTAURANTS_STAGING blob: %d bytes" % len(blob))
try:
    rows = json.loads(blob)
except Exception as e:
    # tolerate JS-style keys
    fixed = re.sub(r'([{,]\s*)([A-Za-z_]\w*)\s*:', r'\1"\2":', blob)
    fixed = re.sub(r',\s*([}\]])', r'\1', fixed)
    try:
        rows = json.loads(fixed)
    except Exception as e2:
        print("  could not parse:", e2)
        print("  first 400 chars:", blob[:400])
        raise SystemExit

print("staged restaurants: %d" % len(rows))
f = collections.Counter()
withig = 0
for r in rows:
    if not isinstance(r, dict): continue
    for k in r: f[k] += 1
    if str(r.get('ig') or '').strip(): withig += 1
print("fields:", dict(f.most_common()))
print("with an IG handle: %d of %d" % (withig, len(rows)))
print("\nfirst 3 records:")
for r in rows[:3]:
    print("  ", json.dumps(r))
print("\nnum range: %s .. %s" % (min((r.get('num') or 0) for r in rows), max((r.get('num') or 0) for r in rows)))
print("\nfirst 25 names:")
for r in rows[:25]:
    print("   %-8s %-42s %s" % (r.get('num'), str(r.get('name'))[:42], r.get('ig') or ''))
PY

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -A "$OUT"
git commit -m "snapshot: restaurant staging queue from seed-data.js" || { echo "nothing to commit"; exit 0; }
for i in 1 2 3 4; do git push origin HEAD:claude/master-file-e6ofy0 && break; sleep $((i*3)); git pull --rebase origin claude/master-file-e6ofy0; done
cat "$NOTES"
