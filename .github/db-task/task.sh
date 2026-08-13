#!/bin/bash
# Snapshot the ATL data file + Deals cars.json so Claude can mirror the ALS refresh pattern.
set -e
mkdir -p .github/db-task/fetched
curl -sL -o .github/db-task/fetched/atl-als-data.json "https://the-atl.web.app/als-data.json"
echo "als-data.json: $(wc -c < .github/db-task/fetched/atl-als-data.json) bytes"
head -c 900 .github/db-task/fetched/atl-als-data.json; echo
curl -sL -o /tmp/cars.json "https://classiccarsforsale-co.web.app/cars.json"
echo "cars.json: $(wc -c < /tmp/cars.json) bytes"
# keep only a sample of cars.json in the repo (schema is what matters, not 100 cars)
python3 - <<'PY'
import json
d=json.load(open('/tmp/cars.json'))
if isinstance(d,list):
    sample={"__type":"list","n":len(d),"sample":d[:3]}
else:
    ks=list(d.keys())
    sample={"__type":"object","keys":ks[:30]}
    for k in ks[:4]:
        v=d[k]
        sample[k]=v[:2] if isinstance(v,list) else v
json.dump(sample,open('.github/db-task/fetched/cars-sample.json','w'),indent=1,default=str)
print("sample written")
PY
echo "--- cars sample head ---"
head -c 1200 .github/db-task/fetched/cars-sample.json; echo
git config user.name "Claude"
git config user.email "noreply@anthropic.com"
git add .github/db-task/fetched/
git commit -m "fetched: ALS data + cars.json schema samples" || echo "no change"
git push
