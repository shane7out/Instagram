#!/usr/bin/env python3
"""Builds the home-page services section: ALL services visible at once (no "Read more" drop-downs), grouped by topic, from the ONE list of services
(sites/key-technologies/key-platform/demos/list.json, written by build_service_demos.py). Adding a service to that list adds its card here.
The block between <!--SERVICES-GRID-START--> and <!--SERVICES-GRID-END--> in index.html is rewritten on every run.
Run from the repo root after build_service_demos.py: python3 docs/key-integration/build_services_grid.py"""
import json, re, html
SITE = 'sites/key-technologies/'
lst = json.load(open(SITE + 'key-platform/demos/list.json', encoding='utf-8'))
ORDER = ['Customers & Communication', 'Operations & Sales', 'Marketing & Content', 'AI Systems & Strategy', 'Websites & Security', 'Dashboards & Rewards', 'Training & Rewards']
# wording that must stay visible next to a service (rewards rules); keyed by slug
MUST_SAY = {'key-rewards-events': ' Rewards never expire, have no cash value and cannot be sold or exchanged for cash.'}
cats = ORDER + sorted({e['cat'] for e in lst} - set(ORDER))
esc = lambda t: html.escape(t, quote=False)
out = ['<!--SERVICES-GRID-START-->', '    <div class="svc-groups">']
for c in cats:
    items = [e for e in lst if e['cat'] == c]
    if not items: continue
    out.append('      <div class="svc-group reveal">')
    out.append('        <h3>%s <span class="svc-n">%d</span></h3>' % (esc(c), len(items)))
    out.append('        <div class="svc-cards">')
    for e in items:
        href = 'key-platform/' + e['href'].lstrip('./')
        out.append('          <article class="svc-mini"><h4><a href="%s">%s</a></h4><p>%s</p><a class="demo-link" href="%s"><span class="demo-chip">Demo</span> Try the demo &rarr;</a></article>'
                   % (href, esc(e['title']), esc(e['tag'] + MUST_SAY.get(e['slug'], '')), href))
    out.append('        </div>'); out.append('      </div>')
out.append('    </div>'); out.append('    <!--SERVICES-GRID-END-->')
block = '\n'.join(out)
path = SITE + 'index.html'
s = open(path, encoding='utf-8').read()
if '<!--SERVICES-GRID-START-->' in s:
    s = re.sub(r'<!--SERVICES-GRID-START-->.*?<!--SERVICES-GRID-END-->', lambda m: block.strip(), s, count=1, flags=re.S)
else:
    a = s.index('<section class="wrap" id="services">'); g = s.index('<div class="service-grid">', a)
    m = re.compile(r'</article>\s*</div>').search(s, g)           # the end of the old card grid
    s = s[:g] + block.strip() + s[m.end():]
CSS = '''  /* services: everything visible at once, grouped (build_services_grid.py) */
  .svc-groups{display:grid;gap:26px;}
  .svc-group h3{font-size:18px;margin:0 0 10px;display:flex;align-items:center;gap:8px;}
  .svc-group .svc-n{font-size:12px;font-weight:700;color:var(--ink-dim);border:1px solid var(--line);border-radius:999px;padding:1px 8px;}
  .svc-cards{display:grid;grid-template-columns:repeat(3,1fr);gap:12px;align-items:stretch;}
  @media (max-width:900px){.svc-cards{grid-template-columns:1fr 1fr;}}
  @media (max-width:600px){.svc-cards{grid-template-columns:1fr;gap:10px;}}
  .svc-mini{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:14px 16px;display:flex;flex-direction:column;gap:6px;}
  .svc-mini h4{font-size:17px;line-height:1.3;margin:0;}
  .svc-mini h4 a{color:var(--ink);text-decoration:none;}
  .svc-mini h4 a:hover{color:var(--key-light);}
  .svc-mini p{font-size:14.5px;line-height:1.45;margin:0;color:var(--ink-dim);flex:1;}
  .svc-mini .demo-link{margin-top:2px;min-height:40px;display:inline-flex;align-items:center;}
'''
if '/* services: everything visible at once' in s:
    s = re.sub(r'  /\* services: everything visible at once.*?\.svc-mini \.demo-link\{[^}]*\}\n', lambda m: CSS, s, count=1, flags=re.S)
else:
    s = s.replace('  .service-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:16px;align-items:start;}', CSS + '  .service-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:16px;align-items:start;}', 1)
# search-engine data: the OfferCatalog in index.html must list exactly the services on the page (keeps the descriptions already written, adds missing
# services from the one list with their card text, drops ones that are no longer in the list)
import json as _json
def _sync_offer_catalog(text):
    for m in re.finditer(r'(<script type="application/ld\+json">)(.*?)(</script>)', text, re.S):
        if 'OfferCatalog' not in m.group(2): continue
        data = _json.loads(m.group(2)); found = []
        def walk(o):
            if isinstance(o, dict):
                if o.get('@type') == 'OfferCatalog': found.append(o)
                for v in o.values(): walk(v)
            elif isinstance(o, list):
                for v in o: walk(v)
        walk(data)
        if not found: return text
        cat = found[0]; have = {}
        for off in cat.get('itemListElement', []):
            nm = (off.get('itemOffered') or {}).get('name')
            if nm: have[nm] = off
        new = []
        for e in lst:
            off = have.get(e['title'])
            if off is None:
                off = {'@type': 'Offer', 'itemOffered': {'@type': 'Service', 'name': e['title'], 'description': e['tag'] + MUST_SAY.get(e['slug'], '')}}
            new.append(off)
        cat['itemListElement'] = new
        body = _json.dumps(data, indent=2, ensure_ascii=False)
        return text[:m.start(2)] + '\n' + body + '\n' + text[m.end(2):]
    return text
s = _sync_offer_catalog(s)
open(path, 'w', encoding='utf-8').write(s)
print('services grid built: %d services in %d groups' % (len(lst), sum(1 for c in cats if any(e['cat'] == c for e in lst))))
