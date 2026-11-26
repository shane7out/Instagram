#!/usr/bin/env python3
"""Shane (2026-11-26): "in all the forms, they have to look the same nice color. I don't want that brown showing up or that gold.
The only thing that should be gold is the key and the card."  Recolors every amber / gold / brown that is part of form, notice,
banner, button, pill, badge or toast styling to the Key blue family. Left alone on purpose: the gold CARD art (.gcard, .gc, .mc, card
themes), the key logo glow, confetti, the LVR member screens (my-account, menu). Idempotent (plain replacements)."""
import pathlib, re
SITE = pathlib.Path('sites/key-technologies'); MAC = pathlib.Path('.github/db-task/mac')
GENERAL = [('#ffb84d', '#9fd6f2'), ('rgba(255,184,77,', 'rgba(79,200,240,'), ('#ffd99a', '#bfe6ff'), ('rgba(240,169,26,', 'rgba(0,168,225,'),
           ('#f0a91a', '#4fc8f0'), ('#f0c24a', '#4fc8f0'), ('#2a2518', '#0e2347'), ('#f59a6b', '#a8b4ff'),
           ('#7a2a00', '#0b3a73'), ('#f3d884', '#9fd6f2'), ('rgba(243,216,132,', 'rgba(159,214,242,'), ('#33290f', '#0e2347'),
           ('#7a6420', '#2f5f9e'), ('#f3e2a6', '#d6ecff'), ('#f6d467,#e6b83a 55%,#d7a21e', '#4fc8f0,#00a8e1 55%,#0090c8'),
           ('color:#2b1d05', 'color:#04202e'), ('#fbbf24', '#9fd6f2'), ('rgba(251,191,36,', 'rgba(159,214,242,'), ('#fb923c', '#7fb6ff'),
           ('#e8c766', '#9fd6f2'), ('rgba(232,199,102,', 'rgba(159,214,242,'), ('#f6e7b4', '#d6ecff'), ('#ff9d2e', '#4fc8f0'), ('linear-gradient(140deg,#f6d467,#d7a21e)', 'linear-gradient(140deg,#4fc8f0,#0090c8)'),
           ('#e6b83a', '#00a8e1'), ('#ffd27a', '#9fd6f2'), ('#ffcf8a', '#9fd6f2'), ('#fff4dc', '#e3f1fd'), ('#f0c878', '#9cc8ee'), ('#6e4300', '#07508a')]
LIGHT = [('#a85f00', '#07508a'), ('#8a5200', '#07508a'), ('#b97a00', '#0a6fb8'), ('rgba(184,106,0,', 'rgba(10,111,184,'), ('#fff1d6', '#e3f1fd'),
         ('rgb(184,106,0)', 'rgb(10,111,184)'), ('#fff4dc', '#e3f1fd'), ('#f0c878', '#9cc8ee'), ('#6e4300', '#07508a'), ('#ff9d2e', '#0a8de6')]
CARD = re.compile(r'gcard|\.gc\b|\.gc[ .{:,\[]|\.mc\b|card-themes|k-bronze|confetti|burst|drop-shadow|key-gold|rrbadge|\.cf\b|shine|facet')
def run(path, pairs, skip_card=True):
    s = path.read_text(encoding='utf-8'); out = []
    for line in s.split('\n'):
        if skip_card and CARD.search(line): out.append(line); continue
        for a, b in pairs: line = line.replace(a, b)
        out.append(line)
    n = '\n'.join(out)
    if n != s: path.write_text(n, encoding='utf-8')
    print(('changed   ' if n != s else 'unchanged ') + str(path))
for rel in ['key-rewards-join.html', 'key-rewards-checkin.html', 'key-rewards-me.html', 'key-rewards-dashboard.html', 'key-rewards-app.html',
            'key-content-studio.html', 'key-pageviews.html', 'outreach.html', 'key-rewards-marketplace.html', 'restaurant-rewards-treasury.html',
            'restaurant-rewards-uses.html', 'key-dine.html', 'index.html', 'key-platform/site-base.css', 'key-platform/kr-cash.css', 'key-platform/rr-auth.js']:
    run(SITE / rel, GENERAL)
run(SITE / 'key-platform/kr-light.css', LIGHT)
run(MAC / 'kt-outreach.html', GENERAL)
for p in ['.github/db-task/owner-auth/owner-auth.snippet.html', '.github/db-task/mac/owner-light.snippet.html', 'docs/key-integration/apply_owner_light.py', '.github/db-task/mac/deploy-owner-light.sh']:
    if pathlib.Path(p).exists(): run(pathlib.Path(p), [('#ffcf8a', '#9fd6f2')])
for p in sorted(MAC.glob('key-*.html')) + sorted(MAC.glob('kt-*.html')):
    if p.name != 'kt-outreach.html': run(p, GENERAL)
for p in sorted(MAC.glob('lvr-*.html')): run(p, [('#ffcf8a', '#9fd6f2')])
