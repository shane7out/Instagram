#!/bin/bash
# Rewrite coins + land pages to use SAME-SITE image paths (/pimg/...) — the site's CSP
# img-src 'self' blocks every off-site image host, including our GitHub copies.
# Also writes pimg-manifest.txt so the Mac can pull every photo into the site folder.
set -e
python3 - <<'PY'
import os, re
RAW='https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/fetched/img/'
for f in ['.github/db-task/fetched/coins.html', '.github/db-task/fetched/land-eaglepoint.html']:
    s=open(f).read()
    n=s.count(RAW)
    s=s.replace(RAW,'/pimg/')
    open(f,'w').write(s)
    print(f"{f}: {n} image refs -> /pimg/")
names=[]
for sub in ['coins','land']:
    d='.github/db-task/fetched/img/'+sub
    for fn in sorted(os.listdir(d)):
        names.append(sub+'/'+fn)
open('.github/db-task/fetched/pimg-manifest.txt','w').write('\n'.join(names)+'\n')
print('manifest:', len(names), 'photos')
PY
git config user.name "Claude"
git config user.email "noreply@anthropic.com"
git add .github/db-task/fetched/
git commit -m "fetched: same-site /pimg/ image paths (CSP img-src 'self') + manifest" || echo "no change"
git push
