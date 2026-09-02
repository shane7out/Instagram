#!/usr/bin/env python3
"""Build the video wall: eight videos, every one confirmed real through YouTube's
oEmbed endpoint (title and channel below are what YouTube returns, not invented),
each with a poster frame pulled from YouTube and each playing on hover.
The two St Rita's films lead; the rest are the Rogue River Valley around it."""
import re, os

SRC = "/home/user/Instagram/.github/db-task/fetched/st-ritas"

VIDEOS = [
    ("llcRsfSUhvs", "Welcome to St. Rita Retreat Center", "LeRoy Tomes", "St Rita&rsquo;s"),
    ("e9WlVu-hm_o", "St. Rita Retreat Center, 2006", "LeRoy Tomes", "St Rita&rsquo;s"),
    ("xiQWVlvHUhA", "Rogue River &mdash; Wild and Scenic", "Dan Ransom", "The valley"),
    ("PoAc9_pkr5I", "Must See in Oregon: the Rogue River Valley", "2TexansTravel", "The valley"),
    ("3a77VqrGoFM", "A Complete Guide to Rogue River, Oregon", "Oregon Adventure Realty", "The valley"),
    ("nfnbRgeicSw", "Destination: The Wild and Scenic Rogue River", "Canoe &amp; Kayak Magazine", "The valley"),
    ("CcopJ09DaBY", "The Rogue River: A Must Do For All Adventurers", "Earth Trek", "The valley"),
    ("iMdkibxOuTg", "Valley of the Rogue State Park", "Travel Small Live Big", "The valley"),
]

def card(vid, title, who, tag):
    plain = re.sub(r'&[a-z]+;', "'", title)
    return '''        <article class="vid">
          <div class="vid-frame" data-vid="{vid}">
            <img class="vid-poster" src="assets/img/poster/{vid}.jpg" alt="" loading="lazy" decoding="async">
            <span class="vid-tag">{tag}</span>
            <button class="vid-play" type="button" aria-label="Play video: {plain}">
              <span class="vid-disc" aria-hidden="true">&#9654;</span>
              <span class="vid-cue">Hover to play</span>
            </button>
            <button class="vid-sound" type="button" aria-label="Turn sound on">Sound on</button>
          </div>
          <div class="vid-meta">
            <h3>{title}</h3>
            <p class="vid-by">{who} &middot; <a href="https://www.youtube.com/watch?v={vid}" target="_blank" rel="noopener">Watch on YouTube</a></p>
          </div>
        </article>'''.format(vid=vid, title=title, who=who, tag=tag, plain=plain)


WALL = '''  <section class="videos" id="videos">
    <div class="wrap">
      <p class="eyebrow">Watch</p>
      <hr class="rule">
      <h2>The hill, and the country around it</h2>
      <p class="vid-intro">Two films made at St Rita&rsquo;s itself, and six more of the Rogue
      River Valley it looks out over. Hover over any one of them and it starts playing;
      click to keep it going with sound.</p>
      <div class="vid-grid">
{cards}
      </div>
    </div>
  </section>
'''.format(cards="\n".join(card(*v) for v in VIDEOS))


def swap(path, wall):
    s = open(path, encoding="utf-8").read()
    orig = s
    pat = re.compile(r'  <section class="videos"[^>]*>[\s\S]*?\n  </section>\n')
    if not pat.search(s):
        return os.path.basename(path), len(orig), len(s), "no video section"
    s = pat.sub(wall, s, count=1)
    if s != orig:
        open(path, "w", encoding="utf-8").write(s)
    return os.path.basename(path), len(orig), len(s), "ok"


print("%-18s %6d -> %6d  %s" % swap(os.path.join(SRC, "index.html"), WALL))

# the wall lives on the home page; drop the duplicate three from About
p = os.path.join(SRC, "about.html")
s = open(p, encoding="utf-8").read()
orig = s
s = re.sub(r'\n  <section class="videos"[^>]*>[\s\S]*?\n  </section>\n', '\n', s, count=1)
s = re.sub(r'\n  <section class="videos [^"]*"[^>]*>[\s\S]*?\n  </section>\n', '\n', s, count=1)
if s != orig:
    open(p, "w", encoding="utf-8").write(s)
print("about.html         %6d -> %6d  (video wall now lives on the home page)" % (len(orig), len(s)))
