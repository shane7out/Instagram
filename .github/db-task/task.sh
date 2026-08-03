#!/bin/bash
# Inspect how chips are wired on the live Deals home page.
set +e
curl -s https://classiccarsforsale-co.web.app/ -o home.html
echo "size: $(wc -c < home.html)"
echo "=== chip-coins markup ==="
grep -oE '<a class="chip chip-coins"[^>]*>[^<]*</a>' home.html
echo "=== chip row (button samples) ==="
grep -oE '<button class="chip[^>]*>[^<]*</button>' home.html | head -4
echo "=== chip click handlers in JS ==="
python3 - <<'PY'
import re
t=open('home.html',encoding='utf-8',errors='replace').read()
for m in re.finditer(r'.{60}\.chip.{120}', t):
    print(repr(m.group(0)))
print('--- data-type handler ---')
for m in re.finditer(r'.{40}(addEventListener\([\'"]click|onclick|data-type|querySelectorAll\([\'"]\.chip).{140}', t):
    print(repr(m.group(0)[:200]))
PY
