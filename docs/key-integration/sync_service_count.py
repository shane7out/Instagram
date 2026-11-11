#!/usr/bin/env python3
"""Keeps the number of services (and the service cards on the home page) in step with the ONE list of services.
The list is sites/key-technologies/key-platform/demos/list.json, which build_service_demos.py writes from its service table (S and EXISTING).
To add a service: add one row to S in build_service_demos.py, then run the generators (this script is in the chain). Everything below follows by itself:
  - every "NN services" / "See all NN services" number on the site and in llms.txt is rewritten to the real count,
  - the home-page service cards are built from the same list by build_services_grid.py (run it right after build_service_demos.py),
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
              (r'See all \d+ (?:demos|services)', 'See all %d services' % N),
              (r'Open all \d+ (demos|services)', lambda m: 'Open all %d %s' % (N, m.group(1)))]
for page in ['index.html', 'las-vegas.html']:
    try:
        if sub_file(page, COUNT_PATS): changed.append(page)
    except FileNotFoundError: pass
if sub_file('llms.txt', [(r'all \d+ services', 'all %d services' % N)]): changed.append('llms.txt')

# (the home-page service cards themselves are built from the same list by build_services_grid.py)
added = []
print('services in the list: %d | updated: %s | cards: see build_services_grid.py' % (N, ', '.join(changed) or 'nothing'))
