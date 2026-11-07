#!/usr/bin/env python3
"""Adds the anonymous visitor counter (key-platform/pv.js) to every public Key Technologies page, replaces the older inline
counter on the marketing pages, and adds a small "Owner" link to the footer (it opens key-pageviews.html, which needs the
owner sign-in; there is NO password in any page). Idempotent. Run from the repo root AFTER tidy_nav.py.
Left alone on purpose: the LVR member/deal pages (rewards, menu, my-account, join-restaurant, marketplace-demo, spin/points/
rewards terms), the owner pages, and redirect stubs."""
import re, pathlib
SITE = pathlib.Path('sites/key-technologies')
SKIP = {'key-pageviews.html', 'key-content-studio.html', 'rewards-layout-preview.html', 'key-rewards-dashboard.html', 'key-rewards-app.html', 'key-rewards-me.html', 'key-rewards-join.html', 'key-rewards-checkin.html', 'rewards.html', 'menu.html', 'my-account.html', 'join-restaurant.html', 'marketplace-demo.html',
        'spin-terms.html', 'points-terms.html', 'points-privacy.html', 'rewards-terms.html', 'rewards-privacy.html'}
OLD = re.compile(r'<script>\s*// Lightweight page-view counter.*?</script>\n?', re.S)
done = 0
for f in sorted(SITE.rglob('*.html')):
    rel = f.relative_to(SITE).as_posix()
    if rel in SKIP: continue
    s = f.read_text(encoding='utf-8')
    if 'http-equiv="refresh"' in s[:3000] or '</body>' not in s: continue
    o = s
    s = OLD.sub('', s)
    up = '../' * rel.count('/')
    tag = '<script src="%skey-platform/pv.js" defer></script>' % up
    if 'key-platform/pv.js' not in s:
        flag = '<script>window.KT_NOT_FOUND=true;</script>\n' if rel == '404.html' else ''
        s = s.replace('</body>', flag + tag + '\n</body>', 1)
    link = '<li><a href="%skey-pageviews.html">Owner</a></li>' % up
    if 'key-pageviews.html">Owner' not in s:
        m = re.search(r'(<ul class="foot-links">.*?)(</ul>)', s, re.S)
        if m: s = s[:m.end(1)] + '      ' + link + '\n    ' + s[m.start(2):]
    if s != o:
        f.write_text(s, encoding='utf-8'); done += 1
print('analytics added/updated on', done, 'page(s)')
