#!/usr/bin/env python3
"""Adds the phone-only sticky "Get My Free Review" bar (sites/key-technologies/cta-bar.js) to the marketing pages. Idempotent (marker KTCTA).
Run from the repo root, after the page generators (anywhere before add_light_look.py). Skipped on purpose: book.html, owner/member/rewards pages, privacy/terms, redirect stubs, the Johnny Mac's demo."""
import os, re, sys
ROOT = os.path.join('sites', 'key-technologies')
SKIP_PREFIX = ('key-rewards', 'rewards', 'my-account', 'menu', 'join-restaurant', 'key-pageviews', 'privacy', 'terms', 'points-', 'spin-', 'book.html', '404', 'marketplace-demo', 'johnny-macs-demo', 'studio', 'key-content-studio', 'partners')
TAG = '<!--KTCTA--><script src="/cta-bar.js" defer></script><!--/KTCTA-->'
n = 0
for d, _, fs in os.walk(ROOT):
    if os.sep + 'fonts' in d or os.sep + 'thumbs' in d or os.sep + 'assets' in d or 'johnny-macs-demo' in d: continue
    for f in fs:
        if not f.endswith('.html'): continue
        p = os.path.join(d, f); rel = os.path.relpath(p, ROOT)
        if rel.startswith(SKIP_PREFIX) or os.path.basename(rel).startswith(SKIP_PREFIX): continue
        t = o = open(p, encoding='utf-8').read()
        if '</body>' not in t or 'class="burger"' not in t or 'http-equiv="refresh"' in t: continue
        if 'KTCTA' in t: continue
        t = t.replace('</body>', TAG + '\n</body>', 1)
        open(p, 'w', encoding='utf-8').write(t); n += 1
print('cta bar added to', n, 'page(s)')
