#!/usr/bin/env python3
"""Adds a Content-Security-Policy and a referrer policy (as <meta> tags, because GitHub Pages cannot send headers) to every page of sites/key-technologies.
Idempotent (marker KTSEC1). Run from the repo root, AFTER the page generators and BEFORE add_light_look.py (which must stay last).
What the policy does: pages may load scripts, styles, fonts and images only from this site (plus Google Tag Manager for the visitor counter and Google Fonts),
may only talk to this site, the lead database, Formspree and Google Analytics, may not embed plug-ins, may not change the base address, and forms may only post to this site or Formspree.
Inline scripts and styles are still allowed because the pages are built with them; the policy still blocks loading anything from an unknown host and sending data to one."""
import os, re, sys
ROOT = os.path.join('sites', 'key-technologies')
CSP = ("default-src 'self'; "
       "script-src 'self' 'unsafe-inline' https://www.googletagmanager.com; "
       "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; "
       "font-src 'self' data: https://fonts.gstatic.com; "
       "img-src 'self' data: blob: https:; "
       "media-src 'self' data: blob:; "
       "connect-src 'self' https://lvr-data-a60c1-default-rtdb.firebaseio.com https://formspree.io https://formsubmit.co https://www.googletagmanager.com https://www.google-analytics.com https://*.google-analytics.com https://*.analytics.google.com "
       "https://api.allorigins.win https://www.googleapis.com https://identitytoolkit.googleapis.com https://securetoken.googleapis.com; "
       "frame-src 'self' https://www.google.com; "
       "worker-src 'self' blob:; "
       "object-src 'none'; base-uri 'self'; form-action 'self' https://formspree.io")
TAG = ('<!--KTSEC1--><meta http-equiv="Content-Security-Policy" content="%s"><meta name="referrer" content="strict-origin-when-cross-origin"><!--/KTSEC1-->' % CSP)
n = 0
for d, _, fs in os.walk(ROOT):
    if os.sep + 'fonts' in d:
        continue
    for f in fs:
        if not f.endswith('.html'):
            continue
        p = os.path.join(d, f)
        t = open(p, encoding='utf-8').read()
        if 'http-equiv="refresh"' in t[:1200]:
            continue  # tiny redirect stubs
        new = re.sub(r'<!--KTSEC1-->.*?<!--/KTSEC1-->', '', t, flags=re.S)
        m = re.search(r'<meta charset="?utf-8"?\s*/?>', new, re.I)
        if not m:
            print('skip (no charset meta):', p); continue
        new = new[:m.end()] + TAG + new[m.end():]
        if new != t:
            open(p, 'w', encoding='utf-8').write(new); n += 1
print('security meta applied/updated on', n, 'pages')
