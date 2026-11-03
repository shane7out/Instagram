#!/usr/bin/env python3
"""Builds city landing pages at the site root (las-vegas.html, later manhattan-beach.html, los-angeles.html).
Run from the repo root:  python3 docs/key-integration/build_city_pages.py
Only facts already on the site are used (no invented clients, statistics or rankings). Adds sitemap and llms.txt entries (idempotent).
To add a city, add an entry to CITIES with its own true local details and run the script."""
import re, json, os, html
SITE = 'sites/key-technologies/'
BASE = 'https://keytechnologies.si/'
DATE = '2026-11-03'
TEMPLATE = SITE + 'key-platform/demos/booking-scheduling.html'

def esc(t): return html.escape(t, quote=True)

tpl = open(TEMPLATE, encoding='utf-8').read()
svgs = re.findall(r'<svg width="\d+" height="\d+" viewBox="0 4 116 50" aria-hidden="true">.*?</svg>', tpl, flags=re.S)
LOGO_H, LOGO_F = svgs[0], svgs[1]

SERVICE_CARDS = [  # (href, thumb, title, text)
 ('key-platform/voice/', 'voice', 'AI phone receptionist', 'Answers calls day and night, captures the lead and sends anything urgent to a person.'),
 ('key-platform/demos/booking-scheduling.html', 'booking-scheduling', 'Booking and reminders', 'Pick a time, get a confirmation and see the reminders that follow.'),
 ('key-platform/demos/reviews-reputation.html', 'reviews-reputation', 'Review management', 'Drafted replies in your voice, with bad reviews flagged for you first.'),
 ('key-platform/email/', 'email', 'AI email assistant', 'Sorts an inbox and drafts replies that a person approves before they go out.'),
 ('key-platform/demos/content-creators.html', 'content-creators', 'Content and social posts', 'Posts and captions drafted around your brand, with your approval.'),
 ('key-platform/demos/custom-crm.html', 'custom-crm', 'Custom CRM', 'Leads move through your own stages so nothing slips through.'),
]

GUIDE_CARDS = [
 ('guides/ai-for-restaurants.html', 'AI for restaurants: 6 practical ways to save time', 'Phones, bookings, reviews, email and social posts, with a demo of each.'),
 ('guides/ai-receptionist-cost.html', 'How much does an AI receptionist cost?', 'What actually sets the price, and the questions to ask before you buy.'),
 ('guides/php2shell-small-business-websites.html', 'PHP2Shell: what small-business website owners should do now', 'Two critical PHP flaws were patched on October 21, 2026. A 10-minute checklist.'),
]

CITIES = {
 'las-vegas': dict(
  name='Las Vegas', state='Nevada', st='NV', file='las-vegas.html',
  title='AI Consulting in Las Vegas, NV | Key Technologies.si',
  desc='Key Technologies helps Las Vegas businesses use AI practically: phone and email assistants, booking, reviews, custom software and security. Free review.',
  h1='AI and business technology for Las Vegas businesses',
  lead='Key Technologies helps Las Vegas businesses put AI to work in ways that save time and win customers: answering the phone, handling bookings and reviews, and building custom systems around how your business actually runs. In person around Las Vegas, or online.',
  why_h='Why Las Vegas businesses call us',
  why=[('Calls after hours','Many Las Vegas businesses keep late hours, and a missed call is often a missed customer. An AI receptionist can answer, take details and hand anything urgent to a person.'),
       ('Reviews decide visits','Many customers check reviews before they walk in. Replying to every review quickly, in your own voice, is easier with a drafted reply you approve.'),
       ('Lean teams','Reminders, follow-ups and booking questions eat the day. Automating the repetitive parts frees your people for the guests in front of them.'),
       ('A safer website','Websites on PHP and WordPress need attention. We can tell you where you stand and what to ask your host.')],
  industries=[('Restaurants and hospitality','Shane has worked in the restaurant and hospitality world for a decade.','guides/ai-for-restaurants.html'),
              ('Medical and dental','Patient CRM, booking automation and review management.','medical-dental.html'),
              ('Law firms','Intake, follow-up and client communication that a person still approves.','law.html'),
              ('Real estate','Lead response and follow-up that does not slip.','real-estate.html'),
              ('E-commerce','Support, product content and operations for online sellers.','ecommerce.html'),
              ('Something else?','Not on the list? Tell us how your business runs and we will say honestly whether AI can help.','book.html')],
  roots=('Restaurant and hospitality roots',
         'For about ten years, Shane has built restaurant-focused social media brands and audiences, including Las Vegas Restaurants (<a href="https://www.instagram.com/lasvegas_restaurants/">@LasVegas_Restaurants on Instagram</a>), growing real followings and helping local businesses get discovered. Key Technologies applies the same practical, hands-on approach to the systems behind the business: the phones, bookings, reviews and email.'),
  faq=[('Do you work with Las Vegas businesses in person?', 'Yes. Key Technologies works in person around its home markets, which include Las Vegas, and online anywhere. Most of the work can be done remotely, and we meet in person where it helps.'),
       ('What happens in the free review?', 'We talk through how your business runs today and point out where AI or automation could realistically help, and where it would not. There is no obligation and no sales pitch about tools you do not need.'),
       ('Do I need to be technical?', 'No. We explain everything in plain language, and a person on your team stays in charge of anything customer-facing.'),
       ('Which kinds of businesses do you work with in Las Vegas?', 'Restaurants and hospitality, medical and dental practices, law firms, real estate, e-commerce and other small and mid-sized businesses.'),
       ('What does it cost?', 'It depends on the work, so we do not publish a price list. The first call is free, and we give you a clear quote once we understand your business.'),
       ('Can you work with me in my language?', 'Yes. Using AI/SI, Key Technologies can communicate in virtually any language, in writing and by voice, so you can work with us in the language you are most comfortable in. For legal or medical documents, we also recommend a certified human translator.'),
       ('Can I try it before I talk to anyone?', 'Yes. Every service has a free demo with made-up data, so you can see how it behaves before you decide anything.')],
  cta_h='Ready to see where AI fits in your Las Vegas business?',
 ),
}



def ca_city(name, file, lead, area_phrase):
    """California cities: only facts already on the site (Manhattan Beach, the South Bay, Los Angeles and Southern California are served; in person around home markets, online anywhere)."""
    return dict(
      name=name, state='California', st='CA', file=file,
      title='AI Consulting in %s, CA | Key Technologies.si' % name,
      desc='Key Technologies helps %s businesses use AI practically: phone and email assistants, booking, reviews, custom software and security. Free review.' % name,
      lead=lead,
      why_h='Why %s businesses call us' % name,
      why=[('Calls after hours','Many businesses keep long hours, and a missed call is often a missed customer. An AI receptionist can answer, take details and hand anything urgent to a person.'),
           ('Reviews decide visits','Many customers check reviews before they choose. Replying to every review quickly, in your own voice, is easier with a drafted reply you approve.'),
           ('Lean teams','Reminders, follow-ups and booking questions eat the day. Automating the repetitive parts frees your people for the customers in front of them.'),
           ('A safer website','Websites on PHP and WordPress need attention. We can tell you where you stand and what to ask your host.')],
      industries=[('Restaurants and hospitality','Shane has worked in the restaurant and hospitality world for a decade.','guides/ai-for-restaurants.html'),
                  ('Medical and dental','Patient CRM, booking automation and review management.','medical-dental.html'),
                  ('Law firms','Intake, follow-up and client communication that a person still approves.','law.html'),
                  ('Real estate','Lead response and follow-up that does not slip.','real-estate.html'),
                  ('E-commerce','Support, product content and operations for online sellers.','ecommerce.html'),
                  ('Something else?','Not on the list? Tell us how your business runs and we will say honestly whether AI can help.','book.html')],
      roots=('Meet Shane Christensen',
             'Shane Christensen first saw a computer in his junior high school computer lab, back when floppy disks were big, and saw what it could do. He started a computer business while still in high school and has worked with computers and software for more than 42 years. He has been building websites since the early days of the internet.</p><p>Key Technologies brings that hands-on experience to the systems behind your business: the phones, bookings, reviews and email, built around how your work actually happens.'),
      roots_btn=False,
      faq=[('Do you work with %s businesses in person?' % name, 'Yes. Key Technologies works in person around its home markets, which include %s, and online anywhere. Most of the work can be done remotely, and we meet in person where it helps.' % area_phrase),
           ('What happens in the free review?', 'We talk through how your business runs today and point out where AI or automation could realistically help, and where it would not. There is no obligation and no sales pitch about tools you do not need.'),
           ('Do I need to be technical?', 'No. We explain everything in plain language, and a person on your team stays in charge of anything customer-facing.'),
           ('Which kinds of businesses do you work with?', 'Restaurants and hospitality, medical and dental practices, law firms, real estate, e-commerce and other small and mid-sized businesses.'),
           ('What does it cost?', 'It depends on the work, so we do not publish a price list. The first call is free, and we give you a clear quote once we understand your business.'),
           ('Can you work with me in my language?', 'Yes. Using AI/SI, Key Technologies can communicate in virtually any language, in writing and by voice, so you can work with us in the language you are most comfortable in. For legal or medical documents, we also recommend a certified human translator.'),
       ('Can I try it before I talk to anyone?', 'Yes. Every service has a free demo with made-up data, so you can see how it behaves before you decide anything.')],
      cta_h='Ready to see where AI fits in your %s business?' % name)

CITIES['manhattan-beach'] = ca_city('Manhattan Beach', 'manhattan-beach.html',
  'Key Technologies helps Manhattan Beach and South Bay businesses put AI to work in ways that save time and win customers: answering the phone, handling bookings and reviews, and building custom systems around how your business actually runs. In person around the South Bay, or online.',
  'Manhattan Beach and the South Bay')
CITIES['los-angeles'] = ca_city('Los Angeles', 'los-angeles.html',
  'Key Technologies helps Los Angeles and Southern California businesses put AI to work in ways that save time and win customers: answering the phone, handling bookings and reviews, and building custom systems around how your business actually runs. In person around Southern California, or online.',
  'Los Angeles and Southern California')
CITIES['las-vegas']['roots_btn'] = True

def shell(c, body, ld_graph):
    url = BASE + c['file']
    ld = json.dumps({"@context": "https://schema.org", "@graph": ld_graph}, ensure_ascii=False)
    return f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{esc(c['title'])}</title><meta name="description" content="{esc(c['desc'])}"><meta name="theme-color" content="#0f171e">
<link rel="icon" href="apple-touch-icon.png"><link rel="apple-touch-icon" href="apple-touch-icon.png">
<link rel="preload" href="/fonts/lato-400.woff2" as="font" type="font/woff2" crossorigin>
<link rel="stylesheet" href="/fonts/lato.css">
<link rel="stylesheet" href="key-platform/site-base.css"><link rel="stylesheet" href="key-platform/site-extra.css">
<link rel="canonical" href="{url}">
<meta property="og:type" content="website"><meta property="og:title" content="{esc(c['title'])}"><meta property="og:description" content="{esc(c['desc'])}"><meta property="og:url" content="{url}"><meta property="og:image" content="{BASE}og-image.png"><meta name="twitter:card" content="summary_large_image">
<script type="application/ld+json">{ld}</script>
<script>document.documentElement.classList.add("js");</script>
<style>
  .city-hero{{padding-block:56px 36px;border-top:none;}}
  .crumbs{{font-size:14px;color:var(--ink-dim);margin-bottom:18px;}}
  .crumbs a{{color:var(--key-light);text-decoration:underline;text-underline-offset:3px;}}
  .city-hero-grid{{display:grid;grid-template-columns:1.2fr .8fr;gap:36px;align-items:center;}}
  @media (max-width:900px){{.city-hero-grid{{grid-template-columns:1fr;gap:26px;}}}}
  .city-hero h1{{font-size:clamp(34px,5.4vw,54px);line-height:1.08;font-weight:900;}}
  .free-card{{background:var(--card);border:1px solid var(--key-blue);border-radius:18px;padding:24px;box-shadow:0 14px 40px rgba(0,0,0,.4);}}
  .free-card .eyebrow{{display:block;margin-bottom:6px;}}
  .free-card h2{{font-size:24px;margin-bottom:14px;line-height:1.2;}}
  .free-card ul{{list-style:none;display:grid;gap:11px;margin:0 0 18px;padding:0;}}
  .free-card li{{display:flex;gap:10px;font-size:16px;line-height:1.5;color:#dbe4ee;}}
  .free-card li::before{{content:"✓";color:var(--key-light);font-weight:900;flex:none;}}
  .free-card .btn{{display:block;text-align:center;text-decoration:none;}}
  .free-card .fine{{font-size:13px;color:var(--ink-dim);text-align:center;margin-top:10px;}}
  .city-hero h1 .accent{{color:var(--key-light);}}
  .city-hero .lead{{font-size:clamp(17px,2.2vw,20px);line-height:1.6;color:#dbe4ee;max-width:62ch;margin:16px 0 24px;}}
  .hero-ctas{{display:flex;flex-wrap:wrap;gap:12px;}}
  .hero-ctas .btn{{text-decoration:none;flex:0 0 auto;}}
  .why-grid{{display:grid;grid-template-columns:repeat(2,1fr);gap:16px;}}
  @media (max-width:700px){{.why-grid{{grid-template-columns:1fr;}}}}
  .why-card{{background:var(--card);border:1px solid var(--line);border-radius:16px;padding:20px;}}
  .why-card h3{{font-size:19px;margin-bottom:6px;}} .why-card p{{font-size:15.5px;color:var(--ink-dim);}}
  .steps{{display:grid;grid-template-columns:repeat(4,1fr);gap:14px;counter-reset:s;}}
  @media (max-width:900px){{.steps{{grid-template-columns:1fr 1fr;}}}} @media (max-width:520px){{.steps{{grid-template-columns:1fr;}}}}
  .step{{background:var(--card);border:1px solid var(--line);border-radius:16px;padding:18px;counter-increment:s;}}
  .step::before{{content:counter(s);display:flex;align-items:center;justify-content:center;width:34px;height:34px;border-radius:50%;background:var(--bg);border:1px solid var(--key-blue);color:var(--key-light);font-weight:900;margin-bottom:10px;}}
  .step h3{{font-size:18px;margin-bottom:4px;}} .step p{{font-size:15px;color:var(--ink-dim);}}
  .roots{{display:grid;grid-template-columns:1.1fr .9fr;gap:34px;align-items:center;}}
  @media (max-width:860px){{.roots{{grid-template-columns:1fr;}}}}
  .roots p{{font-size:17px;line-height:1.7;color:#dbe4ee;margin-bottom:14px;}} .roots p a:not(.btn){{color:var(--key-light);text-decoration:underline;text-underline-offset:3px;}}
  .roots .about-photo{{margin:0 auto 0 0;}}
  .faq-list details{{background:var(--card);border:1px solid var(--line);border-radius:14px;margin-bottom:10px;}}
  .faq-list summary{{cursor:pointer;padding:16px 18px;font-weight:700;font-size:17px;list-style:none;display:flex;justify-content:space-between;gap:14px;}}
  .faq-list summary::-webkit-details-marker{{display:none}} .faq-list summary::after{{content:"+";color:var(--key-light);font-weight:900;}}
  .faq-list details[open] summary::after{{content:"–";}}
  .faq-list details p{{padding:0 18px 16px;font-size:16px;line-height:1.65;color:#dbe4ee;}}
  .city-cta{{text-align:center;background:var(--bg-2);border-top:1px solid var(--line);border-bottom:1px solid var(--line);padding-block:52px;}}
  .city-cta h2{{margin-bottom:10px;}} .city-cta p{{max-width:54ch;margin:0 auto 22px;font-size:16.5px;color:var(--ink-dim);}}
  .city-cta .row{{display:flex;flex-wrap:wrap;gap:12px;justify-content:center;}} .city-cta .btn{{text-decoration:none;}}
  .sw-card .go,.g-card .go{{display:inline-block;}}
  .g-card .go{{margin-top:10px;}}
</style>
</head>
<body>
<header>
  <div class="wrap nav-row">
    <a class="logo" href="index.html" aria-label="Key Technologies.si — home">
      {LOGO_H}
      <span class="logo-word">KEY TECHNOLOGIES<span class="logo-si">.SI</span></span>
    </a>
    <nav aria-label="Primary">
      <ul class="nav-links">
        <li><a href="index.html#services">Services</a></li>
        <li><a href="index.html#audit">Free Website Audit</a></li>
        <li><a href="key-platform/index.html#library">Demos</a></li>
        <li><a href="guides/index.html">Guides</a></li>
        <li><a href="index.html#about">About</a></li>
        <li><a href="index.html#locations">Locations</a></li>
        <li><a href="index.html#faq">FAQ</a></li>
        <li><a href="index.html#contact">Contact</a></li>
      </ul>
    </nav>
    <div class="nav-cta">
      <a class="btn btn-ghost" href="book.html">Book a Call</a>
      <button class="burger" id="burgerBtn" aria-expanded="false" aria-controls="mobileMenu" aria-label="Open menu">
        <span></span><span></span>
      </button>
    </div>
  </div>
</header>
<div class="mobile-menu" id="mobileMenu">
  <a class="mm-account" id="mmAccount" href="rewards.html"><span>Log in</span><small>LVR Rewards member</small></a>
  <div class="mm-cta-row">
    <a class="btn btn-primary" href="book.html">Book a Call</a>
    <a class="btn btn-ghost" href="index.html#audit">Free Website Audit</a>
  </div>
  <p class="mm-group-label">Explore</p>
  <ul>
    <li><a href="key-platform/index.html#library">Demos</a></li>
    <li><a href="guides/index.html">Guides</a></li>
    <li><a href="index.html#services">Services</a></li>
    <li><a href="index.html#industries">Industries</a></li>
    <li><a href="index.html#solutions">Solutions</a></li>
    <li><a href="index.html#method">How It Works</a></li>
    <li><a href="index.html#results">Results</a></li>
  </ul>
  <p class="mm-group-label">Company</p>
  <ul>
    <li><a href="index.html#about">About Shane</a></li>
    <li><a href="las-vegas.html">Las Vegas</a></li>
    <li><a href="manhattan-beach.html">Manhattan Beach</a></li>
    <li><a href="los-angeles.html">Los Angeles</a></li>
    <li><a href="index.html#locations">Locations</a></li>
    <li><a href="index.html#faq">FAQ</a></li>
    <li><a href="rewards.html">LVR Rewards</a></li>
  </ul>
  <a class="btn btn-primary" style="width:100%" href="index.html#lead-short">Explore My Options</a>
</div>
<main id="main">
{body}
</main>
<footer>
  <div class="wrap">
    <a class="logo" href="index.html" aria-label="Key Technologies.si — home">
      {LOGO_F}
      <span class="logo-word">KEY TECHNOLOGIES<span class="logo-si">.SI</span></span>
    </a>
    <ul class="foot-links">
      <li><a href="index.html#services">Services</a></li>
      <li><a href="index.html#audit">Free Website Audit</a></li>
      <li><a href="key-platform/index.html#library">Demos</a></li>
      <li><a href="guides/index.html">Guides</a></li>
      <li><a href="las-vegas.html">Las Vegas</a></li>
      <li><a href="manhattan-beach.html">Manhattan Beach</a></li>
      <li><a href="los-angeles.html">Los Angeles</a></li>
      <li><a href="index.html#about">About</a></li>
      <li><a href="index.html#locations">Locations</a></li>
      <li><a href="index.html#faq">FAQ</a></li>
      <li><a href="rewards.html">LVR Rewards</a></li>
      <li><a href="privacy.html">Privacy</a></li>
      <li><a href="terms.html">Terms</a></li>
    </ul>
    <a class="foot-phone" href="book.html">Book a Call</a>
    <p class="foot-fine">Manhattan Beach, California &middot; Las Vegas, Nevada &middot; Remote worldwide &middot; Any language</p>
    <p class="foot-fine">&copy; <span id="kpYear"></span> Key Technologies. All rights reserved.</p>
  </div>
</footer>
<div class="sticky-cta" id="stickyCta"><a class="btn btn-primary" href="book.html">Book a Free Call</a></div>
<script>(function(){{var b=document.getElementById("burgerBtn"),m=document.getElementById("mobileMenu");if(!b||!m)return;
function c(){{m.classList.remove("open");b.setAttribute("aria-expanded","false");b.setAttribute("aria-label","Open menu")}}
function o(){{m.classList.add("open");b.setAttribute("aria-expanded","true");b.setAttribute("aria-label","Close menu")}}
b.addEventListener("click",function(){{m.classList.contains("open")?c():o()}});
m.querySelectorAll("a").forEach(function(a){{a.addEventListener("click",c)}});
document.addEventListener("keydown",function(e){{if(e.key==="Escape")c()}});
var y=document.getElementById("kpYear");if(y)y.textContent=new Date().getFullYear();
try{{if(localStorage.getItem("lvr_wallet_token")){{var a=document.getElementById("mmAccount");if(a){{a.href=a.href.replace("rewards.html","my-account.html");a.querySelector("span").textContent="My Account";a.querySelector("small").textContent="Logged in"}}}}}}catch(e){{}}
}})();
(function(){{var bar=document.getElementById("stickyCta"),menu=document.getElementById("mobileMenu"),cta=document.getElementById("cityCta");
if(!bar||!("IntersectionObserver" in window))return;var inCta=false,past=false;
function update(){{bar.classList.toggle("on",past&&!inCta&&!menu.classList.contains("open"));}}
if(cta)new IntersectionObserver(function(es){{inCta=es[0].isIntersecting;update();}}).observe(cta);
window.addEventListener("scroll",function(){{past=window.scrollY>520;update();}},{{passive:true}});
new MutationObserver(update).observe(menu,{{attributes:true,attributeFilter:["class"]}});}})();
(function(){{var els=document.querySelectorAll(".reveal");
if(!("IntersectionObserver" in window)){{els.forEach(function(e){{e.classList.add("in")}});return;}}
var io=new IntersectionObserver(function(es){{es.forEach(function(e){{if(e.isIntersecting){{e.target.classList.add("in");io.unobserve(e.target);}}}})}},{{rootMargin:"0px 0px -8% 0px",threshold:0.05}});
els.forEach(function(e){{io.observe(e)}});}})();
</script>
<script src="key-platform/kp-sound.js" defer></script>
</body></html>
'''

def body_for(c):
    cn = c['name']
    why = ''.join(f'<div class="why-card reveal"><h3>{esc(h)}</h3><p>{esc(p)}</p></div>' for h, p in c['why'])
    svc = ''.join(f'<a class="sw-card reveal" href="{h}"><img src="key-platform/demos/thumbs/{th}.jpg" width="660" height="290" loading="lazy" decoding="async" alt="Screenshot of the {esc(t.lower())} demo"><span class="sw-body"><h3>{esc(t)}</h3><p>{esc(d)}</p><span class="go">Try the demo &rarr;</span></span></a>' for h, th, t, d in SERVICE_CARDS)
    ind = ''.join(f'<a class="g-card reveal" href="{h}"><h3>{esc(t)}</h3><p>{esc(d)}</p><span class="go">Learn more &rarr;</span></a>' for t, d, h in c['industries'])
    steps = ''.join(f'<div class="step reveal"><h3>{esc(h)}</h3><p>{esc(p)}</p></div>' for h, p in [
        ('Understand', 'We learn how your business runs today: your calls, bookings, reviews and daily routine.'),
        ('Find the fit', 'We point out where AI or automation could realistically help, and where it would not.'),
        ('Build it your way', 'We create the system around how your business works, with a person approving anything customer-facing.'),
        ('Measure and improve', 'We check the results before doing more, and keep improving as your business changes.')])
    faq = ''.join(f'<details class="reveal"><summary>{esc(q)}</summary><p>{esc(a)}</p></details>' for q, a in c['faq'])
    gui = ''.join(f'<a class="g-card reveal" href="{h}"><h3>{esc(t)}</h3><p>{esc(d)}</p><span class="go">Read the guide &rarr;</span></a>' for h, t, d in GUIDE_CARDS)
    rh, rp = c['roots']
    roots_more = '<p>Shane first saw a computer in his junior high school computer lab and has worked with computers and software for more than 42 years. He has been building websites since the early days of the internet.</p>' if c.get('roots_btn') else ''
    roots_btn_html = '<p><a class="btn btn-ghost" href="guides/ai-for-restaurants.html" style="text-decoration:none">AI for restaurants: the guide</a></p>' if c.get('roots_btn') else ''
    others = ''.join(f'<a class="g-card reveal" href="{o["file"]}"><h3>{o["name"]}, {o["st"]}</h3><p>AI and business technology for {o["name"]} businesses.</p><span class="go">Visit the page &rarr;</span></a>' for k, o in CITIES.items() if o['file'] != c['file'])
    return f'''<section class="wrap city-hero">
  <nav class="crumbs" aria-label="Breadcrumb"><a href="index.html">Home</a> &rsaquo; <a href="index.html#locations">Locations</a> &rsaquo; <span>{cn}</span></nav>
  <div class="city-hero-grid">
    <div>
      <h1>AI and business technology for <span class="accent">{cn}</span> businesses</h1>
      <p class="lead">{esc(c['lead'])}</p>
      <div class="hero-ctas"><a class="btn btn-primary" href="book.html">Book a free call</a><a class="btn btn-ghost" href="index.html#audit">Run the Free Website Audit</a></div>
    </div>
    <aside class="free-card" aria-label="What the free call includes">
      <span class="eyebrow">Free for {cn} businesses</span>
      <h2>What you get in a free call</h2>
      <ul>
        <li>A plain-English look at how your business runs today</li>
        <li>Where AI could realistically help, and where it would not</li>
        <li>A clear next step, or an honest &ldquo;not yet&rdquo;</li>
      </ul>
      <a class="btn btn-primary" href="book.html">Book a free call</a>
      <p class="fine">No obligation. No sales pitch about tools you don&rsquo;t need.</p>
    </aside>
  </div>
</section>

<section class="wrap trust-band" aria-label="Why Key Technologies">
  <ul class="trust-grid">
    <li class="reveal"><b>42+ years</b><span>working with computers and software</span></li>
    <li class="reveal"><b>Free review</b><span>no obligation, no sales pitch about tools you don&rsquo;t need</span></li>
    <li class="reveal"><b>In person or online</b><span>around {cn}, or anywhere remotely, in any language</span></li>
    <li class="reveal"><b>23 services</b><span>each with a live demo you can try</span></li>
  </ul>
</section>

<section class="wrap" id="why">
  <div class="section-head reveal"><span class="eyebrow">Why {cn}</span><h2>{esc(c['why_h'])}</h2><p>The same few problems come up again and again. Here is where AI helps and where a person should stay in charge.</p></div>
  <div class="why-grid">{why}</div>
</section>

<section class="wrap" id="services">
  <div class="section-head reveal"><span class="eyebrow">See it work</span><h2>Try it before you talk to anyone</h2><p>Every service has a live demo with made-up data. Nothing is sent, booked or charged.</p></div>
  <div class="sw-grid">{svc}</div>
  <p class="sw-more"><a class="btn btn-ghost" href="key-platform/index.html#library">See all 25 demos</a></p>
</section>

<section class="wrap" id="industries">
  <div class="section-head reveal"><span class="eyebrow">Industries</span><h2>Who we help in {cn}</h2><p>Practical systems for small and mid-sized businesses, built around how the work actually happens.</p></div>
  <div class="g-grid">{ind}</div>
</section>

<section class="wrap" id="roots">
  <div class="roots">
    <div class="reveal"><span class="eyebrow">Shane Christensen</span><h2 style="margin:8px 0 14px">{esc(rh)}</h2><p>{rp}</p>
      {roots_more}
      <p><a href="index.html#about">Read more about Shane</a>.</p>{roots_btn_html}</div>
    <figure class="about-photo reveal"><img src="images/shane-christensen-320.jpg" srcset="images/shane-christensen-320.jpg 320w, images/shane-christensen.jpg 528w" sizes="300px" width="528" height="594" alt="Shane Christensen, founder of Key Technologies" loading="lazy" decoding="async"></figure>
  </div>
</section>

<section class="wrap" id="how">
  <div class="section-head reveal"><span class="eyebrow">How it works</span><h2>A straightforward way to start</h2><p>We figure out where AI actually helps, and prove it before scaling it.</p></div>
  <div class="steps">{steps}</div>
</section>

<section class="wrap" id="guides">
  <div class="section-head reveal"><span class="eyebrow">Guides</span><h2>Plain-language help, no jargon</h2></div>
  <div class="g-grid">{gui}</div>
</section>

<section class="wrap" id="locations-more">
  <div class="section-head reveal"><span class="eyebrow">Also serving</span><h2>Other locations</h2><p>Key Technologies works in person around its home markets, and online anywhere.</p></div>
  <div class="g-grid">{others}</div>
</section>

<section class="wrap" id="faq">
  <div class="section-head reveal"><span class="eyebrow">Questions</span><h2>{cn} questions, answered</h2></div>
  <div class="faq-list">{faq}</div>
</section>

<section class="city-cta" id="cityCta">
  <div class="wrap"><h2>{esc(c['cta_h'])}</h2>
  <p>Start with a free conversation about how your business runs. No obligation, and no sales pitch about tools you don&rsquo;t need.</p>
  <div class="row"><a class="btn btn-primary" href="book.html">Book a free call</a><a class="btn btn-ghost" href="index.html#audit">Run the Free Website Audit</a></div></div>
</section>'''

def graph(c):
    url = BASE + c['file']
    cn = c['name']
    return [
     {"@type": "WebPage", "name": c['title'].split(' | ')[0], "description": c['desc'], "url": url, "isPartOf": {"@type": "WebSite", "name": "Key Technologies.si", "url": BASE}},
     {"@type": "ProfessionalService", "name": "Key Technologies", "url": BASE, "description": c['desc'],
      "areaServed": {"@type": "City", "name": cn, "containedInPlace": {"@type": "State", "name": c['state']}},
      "founder": {"@type": "Person", "name": "Shane Christensen", "image": BASE + "images/shane-christensen.jpg"},
      "knowsAbout": ["AI consulting", "Business automation", "AI phone receptionist", "Review management", "Website security"]},
     {"@type": "BreadcrumbList", "itemListElement": [{"@type": "ListItem", "position": 1, "name": "Home", "item": BASE}, {"@type": "ListItem", "position": 2, "name": "Locations", "item": BASE + "#locations"}, {"@type": "ListItem", "position": 3, "name": cn, "item": url}]},
     {"@type": "FAQPage", "mainEntity": [{"@type": "Question", "name": q, "acceptedAnswer": {"@type": "Answer", "text": a}} for q, a in c['faq']]}]

def build():
    for key, c in CITIES.items():
        open(SITE + c['file'], 'w', encoding='utf-8').write(shell(c, body_for(c), graph(c)))
        loc = BASE + c['file']
        sm = open(SITE + 'sitemap.xml', encoding='utf-8').read()
        if loc not in sm:
            sm = sm.replace('</urlset>', '  <url>\n    <loc>%s</loc>\n    <lastmod>%s</lastmod>\n    <changefreq>monthly</changefreq>\n    <priority>0.8</priority>\n  </url>\n</urlset>' % (loc, DATE))
            open(SITE + 'sitemap.xml', 'w', encoding='utf-8').write(sm)
        p = SITE + 'llms.txt'
        t = open(p, encoding='utf-8').read()
        line = f'- [{c["name"]} businesses]({loc}): AI and business technology for {c["name"]}, {c["st"]} businesses, in person or online'
        if line not in t:
            if '## Locations' not in t:
                t = t.replace('## Guides', '## Locations\n' + line + '\n\n## Guides', 1)
            else:
                t = t.replace('## Locations\n', '## Locations\n' + line + '\n', 1)
            open(p, 'w', encoding='utf-8').write(t)
    print('city pages built:', len(CITIES))

if __name__ == '__main__':
    build()
