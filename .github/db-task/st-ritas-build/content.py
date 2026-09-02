#!/usr/bin/env python3
"""Second pass on the St Rita's pages:
   - Videos moved high on the home page, and a Videos item in the menu
   - the church on site, the trails, the table, and the $175 package
   - a Reddit link
   - colour, from the retreat's own marks and its own ground
Facts here come from the retreat's live site (stritaretreat.com): sixty-three
wooded acres, a historic friary once home to Augustinian priests holding the
dining hall, kitchen and chapel, a guest house of fifteen private rooms sleeping
up to thirty, outdoor Stations of the Cross, a granite-lined grotto, and a
Chartres-style labyrinth. Idempotent - marked blocks are stripped and rewritten."""
import re, os, glob

SRC = "/home/user/Instagram/.github/db-task/fetched/st-ritas"
PAGES = ["index.html", "about.html", "facilities.html", "availability.html", "contact.html"]

def strip_marked(s, name):
    return re.sub(r'\s*<!--%s-->[\s\S]*?<!--/%s-->' % (name, name), '', s)

# ---------------------------------------------------------------- menu -------
def add_nav_videos(s, page):
    s = strip_marked(s, "NAVVID")
    href = "#videos" if page == "index.html" else "index.html#videos"
    item = ('<!--NAVVID--><li><a href="%s">Videos</a></li><!--/NAVVID-->' % href)
    return s.replace('<li><a href="contact.html">Contact</a></li>',
                     '<li><a href="contact.html">Contact</a></li>\n        ' + item, 1)

# ------------------------------------------------------- move the videos -----
def hoist_videos(s):
    """Put the video wall directly under the hero - it is the first thing to see."""
    m = re.search(r'\n  <section class="videos[\s\S]*?\n  </section>\n', s)
    if not m:
        return s
    block = m.group(0)
    s = s.replace(block, "\n")
    block = block.replace('<section class="videos section-sand"',
                          '<section class="videos" id="videos"', 1)
    return re.sub(r'(\n  </section>\n)', r'\1' + block, s, count=1)

# ------------------------------------------------------------- new blocks ----
CHURCH = '''<!--CHURCH-->
  <section class="band band-blue" id="chapel">
    <div class="wrap narrow">
      <p class="eyebrow">On the property</p>
      <hr class="rule">
      <h2>There is a church here</h2>
      <p class="lede">This is a Catholic house, and it is built like one. The original
      friary &mdash; once home to Augustinian priests &mdash; still holds the chapel, and
      the meeting room carries a raised altar suitable for Mass. Outside, the Stations of
      the Cross run along the hillside, a granite-lined grotto sits below them, and a
      Chartres-style labyrinth is open to anyone who wants to walk it.</p>
      <ul class="marks">
        <li><span>&#10013;</span>Chapel in the friary</li>
        <li><span>&#9903;</span>Altar for Mass</li>
        <li><span>&#9784;</span>Stations of the Cross</li>
        <li><span>&#9968;</span>Granite grotto</li>
        <li><span>&#9737;</span>Chartres labyrinth</li>
      </ul>
      <p class="creed">Guests of every background are welcome, whether or not they come to pray.</p>
    </div>
  </section>
  <!--/CHURCH-->'''

TRAILS = '''<!--TRAILS-->
  <section class="band band-green" id="trails">
    <div class="wrap">
      <p class="eyebrow">Outside</p>
      <hr class="rule">
      <h2>Sixty-three acres to walk</h2>
      <p class="lede">The trails are the reason a lot of people come back. They run through
      oak and madrone and ponderosa, out to the overlooks above the Rogue River Valley, and
      loop back to the lawn in time for supper. Nothing is far, nothing is strenuous, and
      you will not meet a crowd.</p>
      <div class="doings">
        <article class="doing"><span class="doing-ico">&#127794;</span><h3>Nature trails</h3>
          <p>Oak, madrone and pine, with benches where the view opens up.</p></article>
        <article class="doing"><span class="doing-ico">&#9968;</span><h3>The overlooks</h3>
          <p>High ground above the valley &mdash; the best of it early, before the heat.</p></article>
        <article class="doing"><span class="doing-ico">&#9784;</span><h3>The labyrinth</h3>
          <p>A Chartres-style walking labyrinth, open to every guest.</p></article>
        <article class="doing"><span class="doing-ico">&#128330;</span><h3>The lawn</h3>
          <p>Mown, shaded, and quiet. Books, naps, and long conversations.</p></article>
        <article class="doing"><span class="doing-ico">&#128293;</span><h3>The fireplace</h3>
          <p>In the dining hall, and worth the cooler months on its own.</p></article>
        <article class="doing"><span class="doing-ico">&#127756;</span><h3>Dark skies</h3>
          <p>Far enough out of town that the stars actually show up.</p></article>
      </div>
      <figure class="shot" style="margin-top:44px">
        <img src="assets/img/lawn.jpg" alt="The mown lawn between the pines, with a wooden bench and a stone-edged path" loading="lazy" decoding="async">
        <figcaption>The lawn, toward the bluff</figcaption>
      </figure>
    </div>
  </section>
  <!--/TRAILS-->'''

TABLE = '''<!--TABLE-->
  <section class="band band-warm" id="table">
    <div class="wrap narrow">
      <p class="eyebrow">The table</p>
      <hr class="rule">
      <h2>You do not have to cook</h2>
      <p class="lede">The friary holds the kitchen and the dining hall, and meals are cooked
      here and served at the table &mdash; part of the stay, not an add-on. Bring anything you
      particularly need and there is room for it; tell us about allergies before you arrive and
      we will work around them. Nothing is cooked with tree nuts.</p>
      <p class="creed">The dining hall seats a full group comfortably, with a fireplace going
      through the cooler months.</p>
    </div>
  </section>
  <!--/TABLE-->'''

PACKAGE = '''<!--PACKAGE-->
  <section class="band band-gold" id="package">
    <div class="wrap narrow">
      <p class="eyebrow">The retreat package</p>
      <hr class="rule">
      <h2>Two nights, three days</h2>
      <div class="price">
        <span class="price-num">$175</span>
        <span class="price-unit">per person &middot; 2 nights, 3 days</span>
      </div>
      <ul class="marks marks-check">
        <li><span>&#10003;</span>A private room in the guest house</li>
        <li><span>&#10003;</span>Meals cooked and served here</li>
        <li><span>&#10003;</span>The chapel, the grotto and the labyrinth</li>
        <li><span>&#10003;</span>Sixty-three acres of trails</li>
        <li><span>&#10003;</span>Quiet hours, kept</li>
      </ul>
      <div class="hero-actions">
        <a class="btn" href="availability.html">Check Availability</a>
        <a class="btn btn-ghost" href="contact.html">Ask a Question</a>
      </div>
      <p class="creed">Fifteen private rooms, thirty guests at most. When the house is booked,
      it is booked &mdash; there is only one group on the hill at a time.</p>
    </div>
  </section>
  <!--/PACKAGE-->'''

REDDIT = '''<!--REDDIT-->
      <div class="social">
        <a class="social-btn social-reddit" href="https://www.reddit.com/r/oregon/search/?q=st%20rita%27s%20retreat%20gold%20hill&amp;restrict_sr=0"
           target="_blank" rel="noopener">
          <svg viewBox="0 0 24 24" aria-hidden="true" width="17" height="17" fill="currentColor">
            <path d="M12 0C5.37 0 0 5.37 0 12s5.37 12 12 12 12-5.37 12-12S18.63 0 12 0zm5.85 12.9c.02.16.03.32.03.49 0 2.5-2.91 4.52-6.5 4.52s-6.5-2.02-6.5-4.52c0-.17.01-.34.03-.5a1.62 1.62 0 1 1 1.8-2.63 7.96 7.96 0 0 1 4.32-1.37l.82-3.85a.34.34 0 0 1 .4-.26l2.7.57a1.15 1.15 0 1 1-.15.67l-2.38-.5-.73 3.44a7.95 7.95 0 0 1 4.24 1.36 1.62 1.62 0 1 1 1.92 2.58zM8.6 13.2a1.15 1.15 0 1 0 2.3 0 1.15 1.15 0 0 0-2.3 0zm6.8 1.15a1.15 1.15 0 1 0 0-2.3 1.15 1.15 0 0 0 0 2.3zm-.42 1.72a.35.35 0 0 0-.49 0 3.6 3.6 0 0 1-2.47.77 3.6 3.6 0 0 1-2.47-.77.35.35 0 0 0-.49.5 4.3 4.3 0 0 0 2.96.96c1.1 0 2.16-.3 2.96-.97a.35.35 0 0 0 0-.49z"/>
          </svg>
          Find us on Reddit
        </a>
      </div>
      <!--/REDDIT-->'''


def process(path):
    page = os.path.basename(path)
    s = open(path, encoding="utf-8").read()
    orig = s

    for m in ("CHURCH", "TRAILS", "TABLE", "PACKAGE", "REDDIT"):
        s = strip_marked(s, m)

    s = add_nav_videos(s, page)

    if page == "index.html":
        s = hoist_videos(s)
        # the Catholic anchor sits with the patron; then what there is to do,
        # then the table, then what it costs
        s = s.replace('  <!--/DEVOTION-->', '  <!--/DEVOTION-->\n\n' + CHURCH, 1)
        s = s.replace('  <section class="quote">', TRAILS + '\n\n' + TABLE
                      + '\n\n' + PACKAGE + '\n\n  <section class="quote">', 1)

    # Reddit, in the footer of every page
    s = s.replace('    <div class="footer-bottom">',
                  REDDIT + '\n    <div class="footer-bottom">', 1)

    if s != orig:
        open(path, "w", encoding="utf-8").write(s)
    return page, len(orig), len(s)


for p in PAGES:
    print("%-18s %6d -> %6d" % process(os.path.join(SRC, p)))
