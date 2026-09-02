#!/usr/bin/env python3
"""Rebuild the St Rita's pages: centred throughout, opened with the retreat's own
rose, carrying photographs of the actual place, and with videos that start on hover.
Idempotent - every block it writes is fenced by a marker it strips first."""
import re, os, sys, glob

SRC = "/home/user/Instagram/.github/db-task/fetched/st-ritas"

# --- St Rita's own rose, taken from their site's mark (paths verbatim) ---------
ROSE_PATHS = open(os.path.join(SRC, "img/rose-blue.svg")).read()
ROSE_PATHS = re.sub(r'^.*?<svg[^>]*>', '', ROSE_PATHS, flags=re.S)
ROSE_PATHS = ROSE_PATHS.replace('</svg>', '').replace(' fill="#275CAC"', '')
ROSE_PATHS = re.sub(r'\n+', '\n', ROSE_PATHS).strip()

def rose(cls):
    return ('<svg class="%s" viewBox="0 0 225 335" role="img" aria-label="The rose of St Rita">\n'
            '%s\n</svg>' % (cls, ROSE_PATHS))

RITE = (
    '<!--RITE-->\n'
    '      ' + rose("rose") + '\n'
    '      <div class="rite-line"><span>&#10022;</span></div>\n'
    '      <p class="rite-words">Gather <b>~</b> Reflect <b>~</b> Renew</p>\n'
    '      <!--/RITE-->'
)

CREED = ('<!--CREED--><p class="creed">St Rita&rsquo;s is Catholic-affiliated and '
         'welcomes guests of many backgrounds.</p><!--/CREED-->')

def strip_marked(s, name):
    return re.sub(r'\s*<!--%s-->[\s\S]*?<!--/%s-->' % (name, name), '', s)

# --- photographs: which picture goes where, and what it honestly shows --------
SHOTS = {
    "pines":  ("Ponderosa pines above the rock garden", "Through the pines"),
    "lawn":   ("The mown lawn between the pines, with a wooden bench and a stone-edged path", "The lawn, toward the bluff"),
    "house":  ("The cedar-sided retreat house with its arched chapel window", "The retreat house"),
    "sign":   ("The retreat's road sign at 10800, with daffodils in a stone planter", "10800 Blackwell Road"),
    "patio":  ("Retreatants standing together on the patio under a clear sky", "On the patio"),
    "group":  ("A large retreat group gathered outside the house", "A group at the house"),
    "statue": ("A white marble statue of St Rita holding a wooden cross, set in a stacked-stone grotto beside falling water", "St Rita at the grotto"),
}

def shot(key, caption=None):
    alt, cap = SHOTS[key]
    return ('<!--SHOT-->\n'
            '      <figure class="shot">\n'
            '        <img src="assets/img/%s.jpg" alt="%s" loading="lazy" decoding="async">\n'
            '        <figcaption>%s</figcaption>\n'
            '      </figure>\n'
            '      <!--/SHOT-->' % (key, alt, caption or cap))

PLATES = {   # page -> photograph for each .plate, in document order
    "index.html":      ["house"],
    "about.html":      ["sign", "group"],
    "facilities.html": ["house", "pines"],
    "contact.html":    ["sign"],
}

def replace_plates(s, page):
    keys = PLATES.get(page, [])
    if not keys:
        return s
    out, i = [], 0
    pat = re.compile(r'<div class="plate[^"]*"[^>]*>[\s\S]*?</div>\s*')
    def sub(m):
        nonlocal i
        k = keys[i] if i < len(keys) else keys[-1]
        i += 1
        return shot(k) + "\n      "
    return pat.sub(sub, s)

# --- videos: poster + play on hover ------------------------------------------
VIDEO_JS = """<!--VIDJS-->
<script src="assets/videos.js" defer></script>
<!--/VIDJS-->"""

def rewrite_videos(s):
    """Give every .vid-frame a poster image and the hover affordances."""
    def sub(m):
        vid, body = m.group(1), m.group(2)
        label = re.search(r'aria-label="Play video: ([^"]*)"', body)
        label = label.group(1) if label else "Video"
        return (
            '<div class="vid-frame" data-vid="{vid}">'
            '\n          <img class="vid-poster" src="assets/img/poster/{vid}.jpg" alt="" loading="lazy" decoding="async">'
            '\n          <button class="vid-play" type="button" aria-label="Play video: {label}">'
            '\n            <span class="vid-disc" aria-hidden="true">&#9654;</span>'
            '\n            <span class="vid-cue">Hover to play</span>'
            '\n          </button>'
            '\n          <button class="vid-sound" type="button" aria-label="Turn sound on">Sound on</button>'
            '\n        </div>'.format(vid=vid, label=label)
        )
    s = re.sub(
        r'<div class="vid-frame" data-vid="([^"]+)">([\s\S]*?)</div>',
        sub, s)
    return s

# --- the devotional band (home page only) ------------------------------------
DEVOTION = '''<!--DEVOTION-->
  <section class="section-sand devotion">
    <div class="wrap narrow">
      ''' + rose("rose") + '''
      <p class="eyebrow">Our patron</p>
      <hr class="rule">
      <h2>Saint Rita of Cascia</h2>
      <p class="lede">The house is named for Rita of Cascia, remembered in the Church as the
      patron of impossible causes &mdash; the one you ask when the situation has stopped
      making sense. Tradition holds that near the end of her life, in the dead of winter,
      she asked for a rose from her family&rsquo;s garden, and was brought one. That rose is
      why a rose stands at the top of this page.</p>
      ''' + shot("statue") + '''
      <p class="creed">Guests of every background are welcome here, whether or not
      they come to pray.</p>
    </div>
  </section>
  <!--/DEVOTION-->'''

GALLERY = '''<!--GALLERY-->
  <section>
    <div class="wrap">
      <p class="eyebrow">The place itself</p>
      <hr class="rule">
      <h2>Sixty-three acres, and quiet</h2>
      <div class="gallery">
        <figure><img src="assets/img/lawn.jpg" alt="%s" loading="lazy" decoding="async"><figcaption>The lawn</figcaption></figure>
        <figure><img src="assets/img/pines.jpg" alt="%s" loading="lazy" decoding="async"><figcaption>The pines</figcaption></figure>
        <figure><img src="assets/img/patio.jpg" alt="%s" loading="lazy" decoding="async"><figcaption>The patio</figcaption></figure>
        <figure><img src="assets/img/sign.jpg" alt="%s" loading="lazy" decoding="async"><figcaption>The gate</figcaption></figure>
      </div>
    </div>
  </section>
  <!--/GALLERY-->''' % (SHOTS["lawn"][0], SHOTS["pines"][0], SHOTS["patio"][0], SHOTS["sign"][0])


def process(path):
    page = os.path.basename(path)
    s = open(path, encoding="utf-8").read()
    orig = s

    for marker in ("RITE", "CREED", "SHOT", "DEVOTION", "GALLERY", "VIDJS", "BRANDROSE"):
        s = strip_marked(s, marker)

    # 1. rose above the wordmark, in the header and the footer
    s = re.sub(r'(<a class="brand" href="index\.html">)',
               r'\1<!--BRANDROSE-->' + rose("rose brand-rose") + r'<!--/BRANDROSE-->',
               s)

    # 2. the opening: rose, rule, and the retreat's own three words
    if 'class="hero"' in s:
        s = s.replace('<div class="wrap hero-content">\n      <p class="eyebrow">',
                      '<div class="wrap hero-content">\n      ' + RITE + '\n      <p class="eyebrow">')
        # a real photograph behind the hero instead of the drawn ridge
        s = re.sub(r'\s*<svg class="hero-ridge"[\s\S]*?</svg>',
                   '\n    <img class="hero-photo" src="assets/img/lawn.jpg" alt="" '
                   'fetchpriority="high" decoding="async">', s)
        # the dedication line, after the buttons
        s = s.replace('</div>\n    </div>\n  </section>',
                      '</div>\n      ' + CREED + '\n    </div>\n  </section>', 1)
    else:
        s = s.replace('<div class="wrap">\n      <p class="eyebrow">',
                      '<div class="wrap">\n      ' + RITE + '\n      <p class="eyebrow">', 1)

    # 3. photographs in place of the drawn stand-ins
    s = replace_plates(s, page)

    # 4. home page: the patron, and the place itself
    if page == "index.html":
        s = s.replace('  <section class="quote">', DEVOTION + '\n\n  <section class="quote">', 1)
        s = re.sub(r'(\n  <section class="videos)', '\n' + GALLERY + r'\1', s, count=1)

    # 5. videos play on hover
    if 'vid-frame' in s:
        s = rewrite_videos(s)
        s = re.sub(r'<script>\n\(function\(\)\{document\.addEventListener\(\'click\'[\s\S]*?</script>',
                   VIDEO_JS, s)

    if s != orig:
        open(path, "w", encoding="utf-8").write(s)
    return page, len(orig), len(s)


for p in sorted(glob.glob(os.path.join(SRC, "*.html"))):
    if os.path.basename(p) == "preview.html":
        continue
    print("%-18s %6d -> %6d" % process(p))
