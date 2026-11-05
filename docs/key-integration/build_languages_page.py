#!/usr/bin/env python3
"""Builds /languages.html: where the language information now lives (the homepage no longer shows the language wall).
Linked from the phone menu and the footer (tidy_nav.py adds those links). Same copy as the section that used to be on the homepage:
nothing new is claimed. Run from the repo root:  python3 docs/key-integration/build_languages_page.py   (idempotent)
"""
import os, sys, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_city_pages as city

SITE, BASE, DATE = city.SITE, city.BASE, city.DATE
CHIPS = '<div class="lang-chips" aria-label="A few of the languages we can work in"><span class="lang-chip reveal" lang="en">Hello<small>English</small></span><span class="lang-chip reveal" lang="es">Hola<small>Español</small></span><span class="lang-chip reveal" lang="fr">Bonjour<small>Français</small></span><span class="lang-chip reveal" lang="zh">你好<small>中文</small></span><span class="lang-chip reveal" lang="ja">こんにちは<small>日本語</small></span><span class="lang-chip reveal" lang="ko">안녕하세요<small>한국어</small></span><span class="lang-chip reveal" lang="ru">Привет<small>Русский</small></span><span class="lang-chip reveal" lang="ar">مرحبا<small>العربية</small></span><span class="lang-chip reveal" lang="hi">नमस्ते<small>हिन्दी</small></span><span class="lang-chip reveal" lang="pt">Olá<small>Português</small></span><span class="lang-chip reveal" lang="it">Ciao<small>Italiano</small></span><span class="lang-chip reveal" lang="vi">Xin chào<small>Tiếng Việt</small></span><span class="lang-chip reveal" lang="tl">Kamusta<small>Filipino</small></span><span class="lang-chip reveal" lang="tr">Merhaba<small>Türkçe</small></span><span class="lang-chip reveal" lang="de">Guten Tag<small>Deutsch</small></span><span class="lang-chip reveal" lang="el">Γειά σου<small>Ελληνικά</small></span><span class="lang-chip reveal" style="justify-content:center">+ many more<small>just ask</small></span></div>'

def build():
    c = dict(name='', file='languages.html', title='Work With Us in Your Language | Key Technologies.si',
             desc='Key Technologies can communicate with you in virtually any language, in writing and by voice, using AI/SI. Tell us your language when you book.')
    body = ('<section class="wrap city-hero">\n  <nav class="crumbs" aria-label="Breadcrumb"><a href="index.html">Home</a> &rsaquo; <span>Languages</span></nav>\n'
            '  <h1>Work with us in <span class="accent">your language</span></h1>\n'
            '  <p class="lead">Using AI/SI, Key Technologies can communicate with you in virtually any language, in writing and by voice. '
            'Your language is never a reason you can&rsquo;t get the help your business needs.</p>\n</section>\n'
            '<section class="wrap" id="languages">\n  ' + CHIPS + '\n'
            '  <div class="lang-points">\n'
            '    <div class="reveal"><b>In writing</b><span>Emails, messages, documents and your website, in the language your customers and team read.</span></div>\n'
            '    <div class="reveal"><b>By voice</b><span>Calls and meetings, and AI phone and text assistants that can answer your customers in theirs.</span></div>\n'
            '    <div class="reveal"><b>All the way through</b><span>From the first free call to ongoing support, you can work with us in the language you are most comfortable in.</span></div>\n'
            '  </div>\n'
            '  <p class="lang-note">AI/SI translation is fast and strong for everyday business. For legal, medical or other documents where every word matters, we recommend also using a certified human translator.</p>\n'
            '</section>\n'
            '<section class="city-cta" id="cityCta"><div class="wrap"><h2>Tell us your language when you book</h2>'
            '<p>The booking form has a language box. Pick yours and we will take it from there. The first call is free, with no obligation.</p>'
            '<div class="row"><a class="btn btn-primary" href="book.html">Book a free call</a><a class="btn btn-ghost" href="index.html">Back to the homepage</a></div></div></section>')
    ld = [{"@type": "WebPage", "name": "Work With Us in Your Language", "description": c['desc'], "url": BASE + 'languages.html', "isPartOf": {"@type": "WebSite", "name": "Key Technologies.si", "url": BASE}},
          {"@type": "BreadcrumbList", "itemListElement": [{"@type": "ListItem", "position": 1, "name": "Home", "item": BASE}, {"@type": "ListItem", "position": 2, "name": "Languages", "item": BASE + 'languages.html'}]}]
    open(SITE + 'languages.html', 'w', encoding='utf-8').write(city.shell(c, body, ld))
    loc = BASE + 'languages.html'
    sm = open(SITE + 'sitemap.xml', encoding='utf-8').read()
    if loc not in sm:
        sm = sm.replace('</urlset>', '  <url>\n    <loc>%s</loc>\n    <lastmod>%s</lastmod>\n    <changefreq>monthly</changefreq>\n    <priority>0.6</priority>\n  </url>\n</urlset>' % (loc, DATE))
        open(SITE + 'sitemap.xml', 'w', encoding='utf-8').write(sm)
    p = SITE + 'llms.txt'
    t = open(p, encoding='utf-8').read()
    line = '- [Languages](%s): working with Key Technologies in your language, in writing and by voice' % loc
    if line not in t:
        t = t.replace('## Locations\n', '## Locations\n' + line + '\n', 1) if '## Locations\n' in t else t.replace('## Guides', line + '\n\n## Guides', 1)
        open(p, 'w', encoding='utf-8').write(t)
    print('languages page built')

if __name__ == '__main__':
    build()
