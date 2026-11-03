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
    # 4. always-visible Home button in the top bar (shown whenever the menu button is), plus plain Home buttons on the two Rewards app headers
    HOUSE_SVG = ('<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 11.5 12 4l9 7.5"/><path d="M5.5 10v10h13V10"/></svg>')
    HOUSE = ('<a class="home-btn" href="%s" aria-label="Home"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" '
             'stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 11.5 12 4l9 7.5"/><path d="M5.5 10v10h13V10"/></svg><span>Home</span></a>' % home)
    HOMELINK = ('<a class="btn btn-ghost home-link" href="%s" aria-label="Home">' % home) + HOUSE_SVG + '<span class="hl-text">Home</span></a>'
    if 'class="home-btn"' not in t and '<button class="burger"' in t:
        t = t.replace('<button class="burger"', HOUSE + '\n      <button class="burger"', 1)
    if rel == 'my-account.html' and 'home-link' not in t:
        t = t.replace('<div class="nav-cta">', '<div class="nav-cta">\n      ' + HOMELINK, 1)
    if rel == 'menu.html' and 'home-link' not in t.split('</header>')[0]:
        t = t.replace('<a class="btn btn-ghost" href="rewards.html" id="navJoin">', HOMELINK + '\n    <a class="btn btn-ghost" href="rewards.html" id="navJoin">', 1)
    if t != o:
        open(f, 'w', encoding='utf-8').write(t); changed += 1
print('Home link added/updated on', changed, 'page(s)')
