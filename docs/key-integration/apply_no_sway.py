#!/usr/bin/env python3
"""Shane (2026-11-26): "It only slides left and right when I grab it and move it around. It shouldn't move left to right."
Locks the page to up-and-down dragging on every page: html gets overscroll-behavior-x:none (no sideways rubber band) and body gets
touch-action:pan-y pinch-zoom (a sideways drag no longer moves the page; up-down scrolling and pinch zoom still work, and a strip that is
meant to scroll sideways keeps doing so, because touch-action stops at the nearest scrolling box). Only the tour uses a sideways swipe by design; it is left out until Shane decides. (Pages with a signature pad, slider or sideways strip are fine: those controls keep working inside the lock.) Formerly: pages that used sideways drags themselves
(the tour, the signature pad, the Treasury gestures, restaurant confirm) are left out. Idempotent; run after the build_* scripts."""
import subprocess, pathlib
SITE = pathlib.Path('sites/key-technologies')
SKIP = {'key-tour.html'}
STYLE = '<style id="nosway">html{overscroll-behavior-x:none}body{touch-action:pan-y pinch-zoom}</style>'
files = subprocess.check_output(['git', 'ls-files', '*.html'], cwd=SITE, text=True).split()
n = 0
for rel in files:
    if rel.startswith(('vendor/', 'brand/')) or rel in SKIP: continue
    f = SITE / rel; s = f.read_text(encoding='utf-8')
    if 'id="nosway"' in s or '</head>' not in s: continue
    f.write_text(s.replace('</head>', STYLE + '</head>', 1), encoding='utf-8'); n += 1
print('added to', n, 'pages; left out:', ', '.join(sorted(SKIP)))
