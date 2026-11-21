#!/usr/bin/env python3
"""Navigation tidy-up applied to EVERY page after the generators have run (idempotent). Run from the repo root, AFTER add_home_link.py:
    python3 docs/key-integration/tidy_nav.py
  1. Removes the Los Angeles and Manhattan Beach items from the phone menu and the footer link lists (Shane: "it looks funny").
     The city pages themselves stay online (and in the sitemap); only the menu/footer links are gone. Las Vegas stays.
  2. Adds a "Languages" item right after "Guides" in the phone menu and the footer (the language information now lives on /languages.html
     instead of on the homepage).
  3. Removes " · Any language" from the small footer line.
  4. The header button that said "Contact" now says "Book a Call" and goes to the booking page (a clearer action). book.html keeps "Contact".
"""
import os, re, glob
SITE = os.environ.get('KT_SITE', 'sites/key-technologies/')
if not SITE.endswith('/'): SITE += '/'
CITY_LI = re.compile(r'[ \t]*<li><a href="[^"]*(?:manhattan-beach|los-angeles)\.html">[^<]*</a></li>[ \t]*\n?')
GUIDES_LI = re.compile(r'(<li><a href="([^"]*)">Guides</a></li>)(?!\s*<li><a href="[^"]*languages\.html">Languages</a></li>)')
LANG_LI = re.compile(r'[ \t]*<li><a href="[^"]*languages\.html">Languages</a></li>[ \t]*\n?')
# only these blocks get the Languages item: the phone menu and the footer link list (NOT the desktop top menu)
BLOCKS = [re.compile(r'<div class="mobile-menu".*?\n</div>', re.S), re.compile(r'<ul class="foot-links">.*?</ul>', re.S)]
CONTACT_BTN = re.compile(r'<a class="btn btn-ghost" href="([^"]*)#contact">Contact</a>')
changed = 0
for f in sorted(glob.glob(SITE + '**/*.html', recursive=True)):
    rel = os.path.relpath(f, SITE)
    if '/thumbs/' in f: continue
    t = o = open(f, encoding='utf-8').read()
    t = CITY_LI.sub('', t)
    # 5. Shorter desktop top menu (fewer choices, clearer next step): Home (the logo and the home button do that), Solutions, Results, Locations and Contact (the Book a Call button does that) are dropped from the desktop menu only; the phone menu and the footer keep every link.
    def short_menu(m):
        blk = m.group(0)
        if '>Contact<' not in blk: return blk
        return re.sub(r'[ \t]*<li><a href="[^"]*">(?:Home|Solutions|Results|Locations|Contact)</a></li>[ \t]*\n?', '', blk)
    t = re.sub(r'<ul class="nav-links">.*?</ul>', short_menu, t, flags=re.S)
    # the desktop top menu never carries the Languages item
    t = re.sub(r'<ul class="nav-links">.*?</ul>', lambda m: LANG_LI.sub('', m.group(0)), t, flags=re.S)
    def add_lang(m):
        href = m.group(2)
        if href.endswith('guides/index.html'): lang = href[:-len('guides/index.html')] + 'languages.html'
        elif href == 'index.html' and rel.startswith('guides/'): lang = '../languages.html'
        else: return m.group(0)
        return m.group(1) + '\n    <li><a href="%s">Languages</a></li>' % lang
    for blk in BLOCKS:
        t = blk.sub(lambda m: GUIDES_LI.sub(add_lang, m.group(0)), t)
    t = t.replace(' &middot; Any language</p>', '</p>')
    # 6. "About Shane" is the SECOND item of the phone menu, right after Home (Shane: "the first one home, the second one about me, it is hidden too far down")
    ABOUT_LI = re.compile(r'[ \t]*<li><a href="[^"]*#about">About Shane</a></li>[ \t]*\n?')
    HOME_LI = re.compile(r'(<li><a href="([^"]*)index\.html">Home</a></li>)')
    def about_second(m):
        blk = m.group(0)
        mm = ABOUT_LI.search(blk)
        if not mm: return blk
        li = mm.group(0).strip()
        hm = HOME_LI.search(blk)
        if not hm: return blk
        # already second? (Home, then About)
        if blk[hm.end():].lstrip().startswith(li): return blk
        blk = ABOUT_LI.sub('', blk)
        hm = HOME_LI.search(blk)
        return blk[:hm.end()] + '\n    ' + li + blk[hm.end():]
    t = re.sub(r'<div class="mobile-menu".*?\n</div>', about_second, t, flags=re.S)
    if rel != 'book.html':
        def book_btn(m):
            base = m.group(1)
            if base.endswith('index.html'): base = base[:-len('index.html')]
            return '<a class="btn btn-ghost" href="%sbook.html">Book a Call</a>' % base
        t = CONTACT_BTN.sub(book_btn, t)
    if t != o:
        open(f, 'w', encoding='utf-8').write(t); changed += 1
print('nav tidied on', changed, 'page(s)')
