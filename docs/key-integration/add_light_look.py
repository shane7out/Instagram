#!/usr/bin/env python3
"""DARK LOOK ONLY (Shane, 2026-11-17: "I'm just going to use it dark, the colors before, so remove that button").
This step used to make the light look the default and add the Light/Dark button. It now REMOVES all of that from every public page, so the original dark page
is what everyone sees and there is no toggle: the <html data-look="light"> attribute, the kt-light.css link, the look-toggle.js script, the KTLOOK / KTLOOK2
switch scripts, and the white theme-color (back to the dark #0f171e). Idempotent. Kept as the LAST generator step so pages the generators rewrite are cleaned too.
Run from the repo root. Left alone: the same owner / LVR member / deal pages add_analytics.py skips, and redirect stubs."""
import re, pathlib
SITE = pathlib.Path('sites/key-technologies')
SKIP = {'key-pageviews.html', 'key-content-studio.html', 'rewards-layout-preview.html', 'key-rewards-dashboard.html', 'key-rewards-app.html', 'key-rewards-me.html',
        'key-rewards-join.html', 'key-rewards-checkin.html', 'spin-terms.html', 'points-terms.html', 'points-privacy.html', 'rewards-terms.html', 'rewards-privacy.html'}
SCRIPTS = [re.compile(r'\n?<script>/\* KTLOOK2? \*/.*?</script>', re.S)]
LINK = re.compile(r'\n?<link rel="stylesheet" href="/key-platform/kt-light\.css">')
TOGGLE = re.compile(r'\n?<script src="/key-platform/look-toggle\.js" defer></script>')
done = 0
for f in sorted(SITE.rglob('*.html')):
    rel = f.relative_to(SITE).as_posix()
    if rel in SKIP: continue
    s = f.read_text(encoding='utf-8'); o = s
    if 'http-equiv="refresh"' in s[:3000] or '</head>' not in s: continue
    for r in SCRIPTS: s = r.sub('', s)
    s = LINK.sub('', s); s = TOGGLE.sub('', s)
    s = re.sub(r'(<html[^>]*?) data-look="light"', r'\1', s, count=1)
    s = re.sub(r'(<meta name="theme-color" content=")#ffffff(")', r'\1#0f171e\2', s)
    if s != o:
        f.write_text(s, encoding='utf-8'); done += 1
print('light look and the Light/Dark button removed from', done, 'page(s)')
