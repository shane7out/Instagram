#!/usr/bin/env python3
"""Puts a small "Design by KeyTechnologies.si" line at the bottom of every Key Rewards page that is a normal scrolling page
(Shane, 2026-11-18: "a design by keytechnologies.si on every single page, we're going to start really marketing this").
Idempotent (marker <!--KTCREDIT-->). Run AFTER build_wallet_demos.py (that generator rewrites the two wallet demo pages).
The one-screen app pages (key-rewards-app, key-rewards-me, key-rewards-dashboard, my-account, menu) are NOT touched here: they are the live member
screens with fixed layouts; the credit for those goes on their own about/sign-in screen (ask Shane first)."""
import pathlib, re
SITE = pathlib.Path('sites/key-technologies')
PAGES = ['restaurant-rewards-treasury.html', 'restaurant-confirm.html', 'restaurant-rewards-uses.html', 'key-rewards-marketplace.html', 'rewards.html', 'join-restaurant.html', 'key-rewards-join.html', 'key-rewards-checkin.html',
         'rewards-terms.html', 'rewards-privacy.html', 'points-terms.html', 'points-privacy.html', 'spin-terms.html',
         'johnny-macs-demo/index.html', 'johnny-macs-demo/app.html', 'johnny-macs-demo/cards.html', 'johnny-macs-demo/wallet.html', 'thin-blue-702-demo/index.html']
BLOCK = ('<p class="ktcredit" style="text-align:center;margin:22px 16px 28px;font:700 12px/1.3 Lato,system-ui,sans-serif;letter-spacing:.08em;opacity:.78">'
         '<!--KTCREDIT-->Design by <a href="https://keytechnologies.si/" style="color:inherit;text-decoration:underline">KeyTechnologies.si</a></p>\n')
n = 0
for rel in PAGES:
    f = SITE / rel
    if not f.exists(): continue
    s = f.read_text(encoding='utf-8')
    if 'KTCREDIT' in s or '</body>' not in s: continue
    i = s.rindex('</body>')
    f.write_text(s[:i] + BLOCK + s[i:], encoding='utf-8'); n += 1
print('design credit added to', n, 'page(s)')
