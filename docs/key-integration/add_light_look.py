#!/usr/bin/env python3
"""Makes the LIGHT look the default on every public Key Technologies page (Shane, 2026-11-09: "I like the lighter look").
Each page gets <html data-look="light">, a stylesheet link to key-platform/kt-light.css, a white theme-color, and a 4-line script so that
?look=dark (remembered in that browser) puts the dark look back and ?look=light removes that choice. The light styles live ONLY in kt-light.css under
html[data-look="light"], so deleting the attribute shows the original dark page. Replaces the earlier preview snippet (KTLOOK) if present. Idempotent.
Run from the repo root as the LAST generator step (after add_analytics.py), because the page generators rewrite pages from scratch.
Left alone: the same owner / LVR member / deal pages add_analytics.py skips, and redirect stubs."""
import re, pathlib
SITE = pathlib.Path('sites/key-technologies')
SKIP = {'key-pageviews.html', 'key-content-studio.html', 'rewards-layout-preview.html', 'key-rewards-dashboard.html', 'key-rewards-app.html', 'key-rewards-me.html',
        'key-rewards-join.html', 'key-rewards-checkin.html', 'spin-terms.html', 'points-terms.html', 'points-privacy.html', 'rewards-terms.html', 'rewards-privacy.html'}
OLD = re.compile(r'<script>/\* KTLOOK \*/.*?</script>\n?', re.S)
SW = ('<script>/* KTLOOK2 */(function(){try{var q=new URLSearchParams(location.search).get("look");if(q==="dark")localStorage.setItem("kt_look","dark");else if(q==="light")localStorage.removeItem("kt_look");'
      'if(localStorage.getItem("kt_look")==="dark")document.documentElement.removeAttribute("data-look");}catch(e){}})();</script>\n')
LINK = '<link rel="stylesheet" href="/key-platform/kt-light.css">\n'
done = 0
for f in sorted(SITE.rglob('*.html')):
    rel = f.relative_to(SITE).as_posix()
    if rel in SKIP: continue
    s = f.read_text(encoding='utf-8'); o = s
    if 'http-equiv="refresh"' in s[:3000] or '</head>' not in s: continue
    s = OLD.sub('', s)
    if 'data-look="light"' not in s.split('>', 1)[0] and not re.search(r'<html[^>]*data-look', s[:600]):
        s = re.sub(r'<html', '<html data-look="light"', s, count=1)
    if 'kt-light.css' not in s:
        s = s.replace('</head>', LINK + '</head>', 1)
    if 'KTLOOK2' not in s:
        # the switch goes right after <head ...> so it runs before anything paints
        s = re.sub(r'(<head[^>]*>)', lambda m: m.group(1) + '\n' + SW.rstrip('\n'), s, count=1)
    s = re.sub(r'(<meta name="theme-color" content=")#0f171e(")', r'\1#ffffff\2', s)
    if s != o:
        f.write_text(s, encoding='utf-8'); done += 1
print('light look is now the default on', done, 'page(s)')
