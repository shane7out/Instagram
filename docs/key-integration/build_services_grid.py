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
out = ['<!--SERVICES-GRID-START-->', '    <ol class="svc-list">']
ordered = [e for c in cats for e in lst if e['cat'] == c]    # related services stay next to each other, but there are no headings or boxes: one plain numbered list
PIN = {'mobile-apps': 3}                         # Shane (2026-11-17): Mobile Apps is service number 3 on the home list
for slug, pos in PIN.items():
    hit = [e for e in ordered if e['slug'] == slug]
    if hit: ordered.remove(hit[0]); ordered.insert(pos - 1, hit[0])
if True:
    for e in ordered:
        href = 'key-platform/' + e['href'].lstrip('./')
        namehref = {'mobile-apps': 'mobile-apps.html'}.get(e['slug'], href)     # the service name goes to its full page, the Demo link to the demo
        out.append('      <li class="reveal"><a class="svc-name" href="%s">%s</a><span class="svc-desc">%s</span><a class="svc-demo" href="%s" aria-label="Try the %s demo">Demo &rarr;</a></li>'
                   % (namehref, esc(e['title']), esc(e['tag'] + MUST_SAY.get(e['slug'], '')), href, esc(e['title'])))
out.append('    </ol>'); out.append('    <!--SERVICES-GRID-END-->')
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
  .svc-list{list-style:none;margin:0;padding:0;counter-reset:svc;columns:2;column-gap:44px;}
  @media (max-width:760px){.svc-list{columns:1;}}
  .svc-list li{counter-increment:svc;break-inside:avoid;display:grid;grid-template-columns:2.2em 1fr auto;column-gap:6px;align-items:baseline;padding:12px 0;border-bottom:1px solid var(--line);}
  .svc-list li::before{content:counter(svc);grid-row:1 / span 2;color:var(--ink-dim);font-weight:700;font-size:15px;}
  .svc-name{grid-column:2;font-weight:800;font-size:17px;line-height:1.3;color:var(--ink);text-decoration:none;display:inline-flex;align-items:center;min-height:30px;}
  .svc-name:hover{color:var(--key-light);text-decoration:underline;}
  .svc-desc{grid-column:2 / span 2;font-size:15px;line-height:1.45;color:var(--ink-dim);margin-top:3px;}
  .svc-demo{grid-column:3;grid-row:1;font-weight:700;font-size:14px;color:var(--key-light);text-decoration:none;display:inline-flex;align-items:center;min-height:36px;padding-left:8px;}
  .svc-demo:hover{text-decoration:underline;}
  /* end services css */
'''
if '/* services: everything visible at once' in s:
    s = re.sub(r'  /\* services: everything visible at once.*?(?:\.svc-mini \.demo-link\{[^}]*\}|/\* end services css \*/)\n', lambda m: CSS, s, count=1, flags=re.S)
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
print('services list built: %d services (one plain numbered list)' % len(lst))
