#!/usr/bin/env python3
"""Keeps the number of services (and the service cards on the home page) in step with the ONE list of services.
The list is sites/key-technologies/key-platform/demos/list.json, which build_service_demos.py writes from its service table (S and EXISTING).
To add a service: add one row to S in build_service_demos.py, then run the generators (this script is in the chain). Everything below follows by itself:
  - every "NN services" / "See all NN services" number on the site and in llms.txt is rewritten to the real count,
  - a service that has no card on the home page yet gets a basic card (title, one-line description, demo link) so it is never missing,
  - the site-check (.github/site-check/static.py) fails the build if a number ever drifts again.
Run from the repo root: python3 docs/key-integration/sync_service_count.py"""
import json, re, html, sys
SITE = 'sites/key-technologies/'
lst = json.load(open(SITE + 'key-platform/demos/list.json', encoding='utf-8'))
N = len(lst)

def sub_file(path, pats):
    s = open(SITE + path, encoding='utf-8').read(); t = s
    for rx, rep in pats: t = re.sub(rx, rep, t)
    if t != s: open(SITE + path, 'w', encoding='utf-8').write(t); return True
    return False

changed = []
COUNT_PATS = [(r'<b>\d+ services</b>', '<b>%d services</b>' % N),
              (r'See all \d+ (?:demos|services)', 'See all %d services' % N)]
for page in ['index.html', 'las-vegas.html']:
    try:
        if sub_file(page, COUNT_PATS): changed.append(page)
    except FileNotFoundError: pass
if sub_file('llms.txt', [(r'all \d+ services', 'all %d services' % N)]): changed.append('llms.txt')

# a service with no card on the home page gets one
idx = open(SITE + 'index.html', encoding='utf-8').read()
added = []
a = idx.index('<section class="wrap" id="services">')
g = idx.index('<div class="service-grid">', a)
m = re.compile(r'(</article>\s*)(</div>)').search(idx, g)
cards = ''
for e in lst:
    link = 'key-platform/' + e['href'].lstrip('./')
    if link in idx or e['href'].lstrip('./') in idx: continue
    cards += ('      <article class="service-card reveal">\n        <span class="num">NEW</span>\n        <h3>%s</h3>\n        <p>%s</p>\n'
              '        <a class="demo-link" href="%s"><span class="demo-chip">Demo</span> Try the demo &rarr;</a>\n      </article>\n') % (
              html.escape(e['title'], quote=False), html.escape(e['tag'], quote=False), link)
    added.append(e['title'])
if cards:
    idx = idx[:m.start(2)] + cards + '    ' + idx[m.start(2):]
    open(SITE + 'index.html', 'w', encoding='utf-8').write(idx); changed.append('index.html (new cards)')
print('services in the list: %d | updated: %s | new home cards: %s' % (N, ', '.join(changed) or 'nothing', added or 'none'))
