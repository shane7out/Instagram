#!/bin/bash
# Extract the chip click / filter handler JS from the live home page.
set +e
curl -s https://classiccarsforsale-co.web.app/ -o home.html
python3 - <<'PY'
t=open('home.html',encoding='utf-8',errors='replace').read()
import re
# find every occurrence of data-type usage and chip click binding
for pat in [r'data-type', r'aria-pressed', r"querySelectorAll\(['\"][^'\"]*chip", r'\.chips\b', r'function .{0,30}filter', r'addEventListener']:
    print('##### pattern: '+pat)
    for m in list(re.finditer(pat, t))[:4]:
        a=max(0,m.start()-90); b=min(len(t),m.end()+160)
        print(repr(t[a:b]))
    print()
PY
