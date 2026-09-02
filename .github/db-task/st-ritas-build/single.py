#!/usr/bin/env python3
"""Fold the five pages into one self-contained file.

Everything is inlined - stylesheet, scripts, photographs, poster frames, the
availability data - so the result works from any host, behind any content
security policy, and with no second request. Navigation switches sections in
place instead of loading a new document."""
import re, os, base64, json, mimetypes

SRC = "/home/user/Instagram/.github/db-task/fetched/st-ritas"
BLANK = "data:image/gif;base64,R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw=="
OUT = "/home/user/Instagram/.github/db-task/fetched/st-ritas-single.html"
PAGES = [("index", "Home"), ("about", "About"), ("facilities", "Facilities"),
         ("availability", "Availability"), ("contact", "Contact")]

def data_uri(path):
    mime = mimetypes.guess_type(path)[0] or "application/octet-stream"
    with open(path, "rb") as f:
        return "data:%s;base64,%s" % (mime, base64.b64encode(f.read()).decode())

# --- every asset the pages reference, as a data: URI --------------------------
ASSETS = {}
for root, _, files in os.walk(os.path.join(SRC, "assets", "img")):
    for fn in files:
        p = os.path.join(root, fn)
        rel = "assets/" + os.path.relpath(p, os.path.join(SRC, "assets")).replace(os.sep, "/")
        ASSETS[rel] = data_uri(p)
print("inlined %d images (%.1f MB of data URIs)"
      % (len(ASSETS), sum(len(v) for v in ASSETS.values()) / 1e6))

CSS = open(os.path.join(SRC, "assets/styles.css"), encoding="utf-8").read()
JS_MAIN = open(os.path.join(SRC, "assets/main.js"), encoding="utf-8").read()
JS_CAL = open(os.path.join(SRC, "assets/calendar.js"), encoding="utf-8").read()
JS_VID = open(os.path.join(SRC, "assets/videos.js"), encoding="utf-8").read()
AVAIL = open(os.path.join(SRC, "data/availability.json"), encoding="utf-8").read()

HEAD_RE = re.compile(r'<head>([\s\S]*?)</head>', re.I)
BODY_RE = re.compile(r'<body[^>]*>([\s\S]*?)</body>', re.I)

def grab(name):
    s = open(os.path.join(SRC, name + ".html"), encoding="utf-8").read()
    head = HEAD_RE.search(s).group(1)
    body = BODY_RE.search(s).group(1)
    return head, body

head0, _ = grab("index")
# the home page's head carries the title, description and structured data
KEEP = re.findall(r'<script type="application/ld\+json">[\s\S]*?</script>', head0)
KEEP += [m for m in re.findall(r'<meta[^>]*>', head0)
         if 'charset' not in m and 'viewport' not in m]
KEEP += re.findall(r'<link rel="canonical"[^>]*>', head0)

sections, navitems = [], []
for name, label in PAGES:
    _, body = grab(name)
    body = re.sub(r'<header class="site-header">[\s\S]*?</header>', '', body, count=1)
    body = re.sub(r'<footer class="site-footer">[\s\S]*?</footer>', '', body, count=1)
    body = re.sub(r'<script[\s\S]*?</script>', '', body)
    body = re.sub(r'<!--VIDJS-->[\s\S]*?<!--/VIDJS-->', '', body)
    body = body.replace('<main>', '').replace('</main>', '')
    # in-page navigation
    for other, _lbl in PAGES:
        body = body.replace('href="%s.html#' % other, 'href="#')
        body = body.replace('href="%s.html"' % other, 'href="#pg-%s"' % other)
    sections.append('<section class="pg" id="pg-%s" data-pg="%s"%s>\n%s\n</section>'
                    % (name, name, '' if name == "index" else ' hidden', body.strip()))
    navitems.append('<li><a href="#pg-%s"%s>%s</a></li>'
                    % (name, ' aria-current="page"' if name == "index" else '', label))

# the shared header and footer, taken from the home page
_, idxbody = grab("index")
HEADER = re.search(r'<header class="site-header">[\s\S]*?</header>', idxbody).group(0)
FOOTER = re.search(r'<footer class="site-footer">[\s\S]*?</footer>', idxbody).group(0)
HEADER = re.sub(r'<ul>[\s\S]*?</ul>',
                '<ul>\n        ' + "\n        ".join(navitems)
                + '\n        <li><a href="#videos">Videos</a></li>'
                + '\n        <li><a class="btn" href="#pg-availability">Book a Stay</a></li>\n      </ul>',
                HEADER, count=1)
for tag in (HEADER, FOOTER):
    pass
HEADER = HEADER.replace('href="index.html"', 'href="#pg-index"')
FOOTER = re.sub(r'href="(index|about|facilities|availability|contact)\.html"',
                lambda m: 'href="#pg-%s"' % m.group(1), FOOTER)

PAGE_JS = """
(function(){
  var pages=[].slice.call(document.querySelectorAll('.pg'));
  function show(id,push){
    var found=false;
    pages.forEach(function(p){
      var on=(p.id===id); p.hidden=!on; if(on) found=true;
    });
    if(!found){ pages[0].hidden=false; id=pages[0].id; }
    document.querySelectorAll('.nav a').forEach(function(a){
      if(a.getAttribute('href')==='#'+id) a.setAttribute('aria-current','page');
      else a.removeAttribute('aria-current');
    });
    document.body.classList.remove('nav-open');
    var t=document.querySelector('.nav-toggle'); if(t) t.setAttribute('aria-expanded','false');
    window.scrollTo({top:0,behavior:'instant'});
    if(push && location.hash!=='#'+id){ history.replaceState(null,'','#'+id); }
    document.dispatchEvent(new CustomEvent('pagechange',{detail:{id:id}}));
  }
  document.addEventListener('click',function(e){
    var a=e.target.closest && e.target.closest('a[href^="#"]');
    if(!a) return;
    var h=a.getAttribute('href');
    if(h.indexOf('#pg-')===0){ e.preventDefault(); show(h.slice(1),true); return; }
    if(h==='#videos'){
      e.preventDefault(); show('pg-index',true);
      var v=document.getElementById('videos');
      if(v) setTimeout(function(){ v.scrollIntoView({behavior:'smooth',block:'start'}); },40);
      return;
    }
    var el=document.querySelector(h);
    if(el){ e.preventDefault(); el.scrollIntoView({behavior:'smooth',block:'start'}); }
  });
  var h=location.hash;
  if(h.indexOf('#pg-')===0) show(h.slice(1),false);
})();
"""

html = """<title>St Rita's Retreat</title>
%(keep)s
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,400;9..144,500;9..144,600&family=Karla:wght@400;500;700&display=swap">
<style>
%(css)s
/* single-file build: one section visible at a time */
.pg[hidden]{display:none!important}
</style>

%(header)s
<main>
%(sections)s
</main>
%(footer)s

<script>window.__AVAILABILITY__=%(avail)s;</script>
<script>%(main)s</script>
<script>%(cal)s</script>
<script>%(vid)s</script>
<script>/*IMGMAP*/</script>
<script>%(pagejs)s</script>
""" % dict(
    keep="\n".join(KEEP),
    css=CSS,
    header=HEADER,
    footer=FOOTER,
    sections="\n\n".join(sections),
    avail=AVAIL.strip(),
    main=JS_MAIN, cal=JS_CAL, vid=JS_VID, pagejs=PAGE_JS,
)

# Each photograph is inlined exactly once, in a map, and handed to the elements
# that use it - several appear on more than one section and duplicating a
# base64 blob three times would nearly double the file.
missing = set(re.findall(r'(?:src|href)="(assets/[^"]+)"', html))
used = sorted(r for r in missing if r in ASSETS)
keys = {rel: 'i%d' % n for n, rel in enumerate(used)}
for rel, k in keys.items():
    html = html.replace('src="%s"' % rel, 'data-img="%s" src="%s"' % (k, BLANK))
    html = html.replace('href="%s"' % rel, 'href="%s"' % ASSETS[rel])
IMGMAP = "{" + ",".join('"%s":"%s"' % (k, ASSETS[rel]) for rel, k in keys.items()) + "}"
html = html.replace('/*IMGMAP*/', 'var M=' + IMGMAP + ';'
    'function P(){var n=document.querySelectorAll("img[data-img]");'
    'for(var i=0;i<n.length;i++){var s=M[n[i].getAttribute("data-img")];'
    'if(s){n[i].src=s;n[i].removeAttribute("data-img");}}}'
    'P();if(document.readyState==="loading")document.addEventListener("DOMContentLoaded",P);')
still = sorted(r for r in missing if r not in ASSETS)
html = html.replace('href="assets/styles.css"', 'href="#"').replace(
    '<link rel="stylesheet" href="#">', '')
html = re.sub(r'<link[^>]+assets/styles\.css[^>]*>', '', html)

open(OUT, "w", encoding="utf-8").write(html)
print("wrote %s  (%.2f MB)" % (OUT, os.path.getsize(OUT) / 1e6))
print("pages:", html.count('class="pg"'), " videos:", html.count('class="vid-frame"'))
print("unresolved asset refs:", still or "none")
print("leftover assets/ paths:", len(re.findall(r'"assets/', html)))
