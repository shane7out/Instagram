#!/usr/bin/env python3
"""Adds a plain "Home" link to the top of every inner page's navigation, so visitors can always get back to the homepage:
  * the KEY Platform chip row (Voice / Email / Sales ...)  -> first chip "Home"
  * the desktop header menu                                -> first item "Home"
  * the phone menu                                         -> first item "Home" (above Demos)
Idempotent: pages that already have it are left alone. The homepage itself is skipped.
Run from the repo root AFTER the other generators:  python3 docs/key-integration/add_home_link.py
"""
import os, re, glob
SITE = os.environ.get('KT_SITE', 'sites/key-technologies/')
if not SITE.endswith('/'): SITE += '/'
changed = 0
for f in sorted(glob.glob(SITE + '**/*.html', recursive=True)):
    rel = os.path.relpath(f, SITE)
    if rel == 'index.html' or '/thumbs/' in f: continue
    depth = rel.count('/')
    home = '../' * depth + 'index.html'
    t = o = open(f, encoding='utf-8').read()
    # 1. chip row
    t = re.sub(r'(<nav class="kp-switch"[^>]*><span class="lbl">[^<]*</span>)(?!<a href="[^"]*index.html">Home</a>)',
               lambda m: m.group(1) + '<a href="%s">Home</a>' % home, t, count=1)
    # 2. desktop menu
    if re.search(r'<ul class="nav-links">\s*<li><a href="[^"]*">Home</a></li>', t) is None:
        t = re.sub(r'(<ul class="nav-links">)(\s*)', lambda m: m.group(1) + m.group(2) + '<li><a href="%s">Home</a></li>' % home + m.group(2), t, count=1)
    # 3. phone menu: first list item of the first <ul> inside the mobile menu
    mm = re.search(r'<div class="mobile-menu"[^>]*>', t)
    if mm:
        seg_end = t.find('</ul>', mm.end())
        seg = t[mm.end():seg_end]
        if not re.search(r'<li><a href="[^"]*">Home</a></li>', seg):
            i = t.find('<ul>', mm.end())
            if i != -1 and i < seg_end:
                t = t[:i + 4] + '\n    <li><a href="%s">Home</a></li>' % home + t[i + 4:]
    if t != o:
        open(f, 'w', encoding='utf-8').write(t); changed += 1
print('Home link added/updated on', changed, 'page(s)')
