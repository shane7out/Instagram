#!/usr/bin/env python3
"""Adds the light-look preview switch to every public Key Technologies page (Shane, 2026-11-09: "show me a lighter version").
A tiny inline script in <head>: ?look=light turns the light look on (remembered in this browser), ?look=dark turns it off. When it is on, it loads
key-platform/kt-light.css and shows a small "Back to dark" pill. Nothing changes for anyone who does not use the switch. Idempotent. Run from the repo root,
after add_analytics.py. Left alone: the same pages add_analytics.py skips (owner pages, LVR member/deal pages) and redirect stubs."""
import re, pathlib
SITE = pathlib.Path('sites/key-technologies')
SKIP = {'key-pageviews.html', 'key-content-studio.html', 'rewards-layout-preview.html', 'key-rewards-dashboard.html', 'key-rewards-app.html', 'key-rewards-me.html',
        'key-rewards-join.html', 'key-rewards-checkin.html', 'spin-terms.html', 'points-terms.html', 'points-privacy.html', 'rewards-terms.html', 'rewards-privacy.html'}
SNIP = ('<script>/* KTLOOK */(function(){try{var q=new URLSearchParams(location.search).get("look");if(q==="light")localStorage.setItem("kt_look","light");else if(q==="dark")localStorage.removeItem("kt_look");'
        'if(localStorage.getItem("kt_look")==="light"){var d=document.documentElement;d.setAttribute("data-look","light");var l=document.createElement("link");l.rel="stylesheet";l.href="/key-platform/kt-light.css";document.head.appendChild(l);'
        'document.addEventListener("DOMContentLoaded",function(){var b=document.createElement("button");b.id="kt-look-pill";b.type="button";b.textContent="Light look preview \\u00b7 back to dark";b.onclick=function(){try{localStorage.removeItem("kt_look")}catch(e){}location.href=location.pathname};document.body.appendChild(b);});}}catch(e){}})();</script>\n')
done = 0
for f in sorted(SITE.rglob('*.html')):
    rel = f.relative_to(SITE).as_posix()
    if rel in SKIP: continue
    s = f.read_text(encoding='utf-8')
    if 'http-equiv="refresh"' in s[:3000] or '</head>' not in s: continue
    if 'KTLOOK' in s: continue
    s = s.replace('</head>', SNIP + '</head>', 1)
    f.write_text(s, encoding='utf-8'); done += 1
print('light-look switch added to', done, 'page(s)')
