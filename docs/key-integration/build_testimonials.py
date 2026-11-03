#!/usr/bin/env python3
"""Testimonials as their own category: a dedicated page (/testimonials.html) plus a three-quote block on the homepage with a "See all" link.
Run from the repo root:  python3 docs/key-integration/build_testimonials.py

SAFETY RULES (built in):
  * Only entries in sites/key-technologies/testimonials.json with "permission": true are ever shown. An entry without written
    permission is skipped, and the script says so.
  * With no permitted entries the page does not exist, the homepage block is empty, and the sitemap/footer/llms.txt entries are removed.
  * Nothing here invents a quote, a name, a company or a rating. No star-rating markup is added.

Entry format (testimonials.json is a list):
  {"id": "short-slug", "quote": "Exactly what they said.", "name": "First Last", "role": "Owner", "company": "Business name",
   "date": "2026-11-04", "service": "AI phone receptionist", "featured": true, "permission": true}
Keep proof of the written permission yourself (an email or message). Only quote real clients, and say so if they were paid, got a discount
or have any other connection to you (the FTC treats that as a disclosure item).
"""
import os, re, json, html, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_city_pages as city

SITE = os.environ.get('KT_SITE', 'sites/key-technologies/')
if not SITE.endswith('/'): SITE += '/'
BASE = 'https://keytechnologies.si/'
DATE = '2026-11-04'
def esc(t): return html.escape(t, quote=True)

def load():
    p = SITE + 'testimonials.json'
    items = json.load(open(p, encoding='utf-8')) if os.path.exists(p) else []
    ok = []
    for i, e in enumerate(items):
        if not (e.get('quote') and e.get('name')):
            print('skipped entry %d: needs "quote" and "name"' % i); continue
        if e.get('permission') is not True:
            print('skipped entry %d (%s): no written permission recorded' % (i, e.get('name'))); continue
        e.setdefault('id', 't%d' % (i + 1)); ok.append(e)
    ok.sort(key=lambda e: e.get('date', ''), reverse=True)
    return ok

def card(e, anchor=False):
    who = '<b>%s</b>' % esc(e['name'])
    line = ', '.join(x for x in [e.get('role'), e.get('company')] if x)
    if line: who += '<span>%s</span>' % esc(line)
    if e.get('service'): who += '<span>Service: %s</span>' % esc(e['service'])
    aid = ' id="t-%s"' % esc(re.sub(r'[^a-z0-9-]', '-', e['id'].lower())) if anchor else ''
    return '<figure class="t-card reveal"%s><div class="mark">&ldquo;</div><blockquote>%s</blockquote><figcaption class="t-who">%s</figcaption></figure>' % (aid, esc(e['quote']), who)

def replace_block(t, name, content):
    a, b = '<!--%s-->' % name, '<!--/%s-->' % name
    i, j = t.index(a), t.index(b)
    return t[:i + len(a)] + content + t[j:]

def update_sitemap_llms(exists, n):
    sm = open(SITE + 'sitemap.xml', encoding='utf-8').read()
    loc = BASE + 'testimonials.html'
    entry = '  <url>\n    <loc>%s</loc>\n    <lastmod>%s</lastmod>\n    <changefreq>weekly</changefreq>\n    <priority>0.7</priority>\n  </url>\n' % (loc, DATE)
    sm = re.sub(r'  <url>\s*<loc>%s</loc>.*?</url>\n' % re.escape(loc), '', sm, flags=re.S)
    if exists: sm = sm.replace('</urlset>', entry + '</urlset>')
    open(SITE + 'sitemap.xml', 'w', encoding='utf-8').write(sm)
    p = SITE + 'llms.txt'
    t = open(p, encoding='utf-8').read()
    t = re.sub(r'- \[Client testimonials\]\([^)]*\):[^\n]*\n', '', t)
    if exists:
        t = t.replace('## Demos (fictional data)', '- [Client testimonials](%s): what real clients say, shared with their permission\n\n## Demos (fictional data)' % loc, 1)
    open(p, 'w', encoding='utf-8').write(t)

def build():
    items = load()
    idx = open(SITE + 'index.html', encoding='utf-8').read()
    page = SITE + 'testimonials.html'
    if not items:
        if os.path.exists(page): os.remove(page)
        idx = replace_block(idx, 'testimonials-home', '')
        idx = replace_block(idx, 'testimonials-foot', '')
        open(SITE + 'index.html', 'w', encoding='utf-8').write(idx)
        update_sitemap_llms(False, 0)
        print('no permitted testimonials: page, homepage block and footer link are off')
        return
    featured = [e for e in items if e.get('featured')] + [e for e in items if not e.get('featured')]
    top = featured[:3]
    home = ('\n  <section class="wrap" id="testimonials">\n    <div class="section-head reveal"><span class="eyebrow">Testimonials</span><h2>What clients say</h2>'
            '<p>Words from real clients, shared with their permission.</p></div>\n    <div class="t-grid">%s</div>\n'
            '    <p class="t-more"><a class="btn btn-ghost" href="testimonials.html">See all %d testimonial%s</a></p>\n  </section>\n') % (''.join(card(e) for e in top), len(items), '' if len(items) == 1 else 's')
    idx = replace_block(idx, 'testimonials-home', home)
    idx = replace_block(idx, 'testimonials-foot', '<li><a href="testimonials.html">Testimonials</a></li>')
    open(SITE + 'index.html', 'w', encoding='utf-8').write(idx)
    c = dict(name='', file='testimonials.html', title='Client Testimonials: What Key Technologies Clients Say | Key Technologies.si',
             desc='Read what real clients say about working with Key Technologies: AI phone and email assistants, booking, reviews, custom software and security. Shared with their permission.')
    body = ('<section class="wrap city-hero">\n  <nav class="crumbs" aria-label="Breadcrumb"><a href="index.html">Home</a> &rsaquo; <span>Testimonials</span></nav>\n'
            '  <h1>What clients <span class="accent">say</span></h1>\n'
            '  <p class="lead">Words from real Key Technologies clients, shared with their permission.</p>\n</section>\n'
            '<section class="wrap" id="all-testimonials">\n  <div class="t-grid all">%s</div>\n</section>\n'
            '<section class="city-cta" id="cityCta"><div class="wrap"><h2>Want results like these?</h2>'
            '<p>Start with a free conversation about how your business runs. No obligation, and no sales pitch about tools you don&rsquo;t need.</p>'
            '<div class="row"><a class="btn btn-primary" href="book.html">Book a free call</a><a class="btn btn-ghost" href="index.html#audit">Run the Free Website Audit</a></div></div></section>') % ''.join(card(e, True) for e in items)
    ld = [{"@type": "CollectionPage", "name": "Client Testimonials", "description": c['desc'], "url": BASE + 'testimonials.html', "isPartOf": {"@type": "WebSite", "name": "Key Technologies.si", "url": BASE}},
          {"@type": "BreadcrumbList", "itemListElement": [{"@type": "ListItem", "position": 1, "name": "Home", "item": BASE}, {"@type": "ListItem", "position": 2, "name": "Testimonials", "item": BASE + 'testimonials.html'}]}]
    open(page, 'w', encoding='utf-8').write(city.shell(c, body, ld))
    update_sitemap_llms(True, len(items))
    print('testimonials page built with', len(items), 'permitted testimonial(s); homepage shows', len(top))

if __name__ == '__main__':
    build()
