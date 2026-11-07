#!/usr/bin/env python3
"""Builds the Guides pages (sites/key-technologies/guides/*.html) on the site shell.
Run from the repo root:  python3 docs/key-integration/build_guides.py
Adds the pages to sitemap.xml and llms.txt (idempotent). Facts in the PHP2Shell guide were checked against the PHP
project's release notes on 2026-11-03; update the guide (and DATE_MODIFIED) if the story changes."""
import re, json, os, html
SITE = 'sites/key-technologies/'
BASE = 'https://keytechnologies.si/'
DATE = '2026-11-03'
TEMPLATE = SITE + 'key-platform/demos/booking-scheduling.html'

def esc(t): return html.escape(t, quote=True)

# ---------- shell pieces taken from an existing page so the guides match the site exactly ----------
tpl = open(TEMPLATE, encoding='utf-8').read()
svgs = re.findall(r'<svg width="\d+" height="\d+" viewBox="0 4 116 50" aria-hidden="true">.*?</svg>', tpl, flags=re.S)
LOGO_H, LOGO_F = svgs[0], svgs[1]

def shell(title, desc, path, body, ld_graph, crumbs):
    url = BASE + path
    ld = json.dumps({"@context": "https://schema.org", "@graph": ld_graph}, ensure_ascii=False)
    return f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{esc(title)}</title><meta name="description" content="{esc(desc)}"><meta name="theme-color" content="#0f171e">
<link rel="icon" href="../apple-touch-icon.png"><link rel="apple-touch-icon" href="../apple-touch-icon.png">
<link rel="stylesheet" href="/fonts/lato.css">
<link rel="stylesheet" href="../key-platform/site-base.css">
<link rel="canonical" href="{url}">
<meta property="og:type" content="article"><meta property="og:title" content="{esc(title)}"><meta property="og:description" content="{esc(desc)}"><meta property="og:url" content="{url}"><meta property="og:image" content="{BASE}og-image.png"><meta name="twitter:card" content="summary_large_image">
<script type="application/ld+json">{ld}</script>
<style>
  .guide{{max-width:760px;margin:0 auto;padding-top:34px;padding-bottom:64px;}}
  .crumbs{{font-size:14px;color:var(--ink-dim);margin-bottom:18px;}}
  .crumbs a{{color:var(--key-light);text-decoration:underline;text-underline-offset:3px;}}
  .guide h1{{font-size:clamp(30px,5vw,44px);line-height:1.12;font-weight:900;margin-bottom:12px;}}
  .byline{{font-size:14px;color:var(--ink-dim);margin-bottom:24px;}}
  .tldr{{background:var(--card);border:1px solid var(--key-blue);border-radius:14px;padding:18px 20px;margin:0 0 28px;font-size:17px;line-height:1.6;color:var(--ink);}}
  .tldr b{{color:#fff;}}
  .glossary dt{{margin-top:18px;font-size:18px;color:#fff;}} .glossary dd{{margin:4px 0 0;color:var(--ink-dim);line-height:1.6;}}
  .guide h2{{font-size:clamp(23px,3.4vw,29px);margin:38px 0 10px;line-height:1.2;}}
  .guide h3{{font-size:19px;margin:22px 0 6px;}}
  .guide p,.guide li{{font-size:17px;line-height:1.7;color:var(--ink);}}
  .guide p{{margin:0 0 14px;color:#dbe4ee;}}
  .guide ul,.guide ol{{margin:0 0 16px;padding-left:22px;display:grid;gap:8px;}}
  .guide a{{color:var(--key-light);text-decoration:underline;text-underline-offset:3px;}}
  .note{{font-size:15px;color:var(--ink-dim);border-left:3px solid var(--line);padding-left:14px;margin:18px 0;}}
  .msg{{background:var(--bg-2);border:1px solid var(--line);border-radius:12px;padding:14px 16px;font-size:16px;line-height:1.6;color:#dbe4ee;margin:0 0 16px;}}
  .guide-cta{{margin-top:40px;padding:22px;border:1px solid var(--line);border-radius:16px;background:var(--card);}}
  .guide-cta h2{{margin:0 0 8px;font-size:24px;}} .guide-cta .row{{display:flex;flex-wrap:wrap;gap:10px;margin-top:14px;}}
  .guide-cta a.btn{{text-decoration:none;color:inherit;}} .guide-cta a.btn-primary{{color:#0f171e;}}
  .more{{display:grid;gap:12px;margin-top:14px;}}
  .more a{{display:block;padding:14px 16px;border:1px solid var(--line);border-radius:12px;background:var(--card);text-decoration:none;color:var(--ink);}}
  .more a b{{display:block;font-size:17px;margin-bottom:3px;}} .more a span{{font-size:15px;color:var(--ink-dim);}}
  .more a:hover{{border-color:var(--key-light);}}
  .src li{{font-size:15px;word-break:break-word;}}
</style>
</head>
<body>
<header>
  <div class="wrap nav-row">
    <a class="logo" href="../index.html" aria-label="Key Technologies.si — home">
      {LOGO_H}
      <span class="logo-word">KEY TECHNOLOGIES<span class="logo-si">.SI</span></span>
    </a>
    <nav aria-label="Primary">
      <ul class="nav-links">
        <li><a href="../index.html#services">Services</a></li>
        <li><a href="../index.html#audit">Free Website Audit</a></li>
        <li><a href="../key-platform/index.html#library">Demos</a></li>
        <li><a href="index.html">Guides</a></li>
        <li><a href="../index.html#about">About</a></li>
        <li><a href="../index.html#locations">Locations</a></li>
        <li><a href="../index.html#faq">FAQ</a></li>
        <li><a href="../index.html#contact">Contact</a></li>
      </ul>
    </nav>
    <div class="nav-cta">
      <a class="btn btn-ghost" href="../book.html">Book a Call</a>
      <button class="burger" id="burgerBtn" aria-expanded="false" aria-controls="mobileMenu" aria-label="Open menu">
        <span></span><span></span>
      </button>
    </div>
  </div>
</header>
<div class="mobile-menu" id="mobileMenu">
  <a class="mm-account" id="mmAccount" href="../rewards.html"><span>Log in</span><small>LVR Rewards member</small></a>
  <div class="mm-cta-row">
    <a class="btn btn-primary" href="../book.html">Book a Call</a>
    <a class="btn btn-ghost" href="../index.html#audit">Free Website Audit</a>
  </div>
  <p class="mm-group-label">Explore</p>
  <ul>
    <li><a href="../key-platform/index.html#library">Demos</a></li>
    <li><a href="index.html">Guides</a></li>
    <li><a href="../index.html#services">Services</a></li>
    <li><a href="../index.html#industries">Industries</a></li>
    <li><a href="../index.html#solutions">Solutions</a></li>
    <li><a href="../index.html#method">How It Works</a></li>
    <li><a href="../index.html#results">Results</a></li>
  </ul>
  <p class="mm-group-label">Company</p>
  <ul>
    <li><a href="../index.html#about">About Shane</a></li>
    <li><a href="../index.html#locations">Locations</a></li>
    <li><a href="../index.html#faq">FAQ</a></li>
    <li><a href="../rewards.html">LVR Rewards</a></li>
  </ul>
  <a class="btn btn-primary" style="width:100%" href="../index.html#lead-short">Explore My Options</a>
</div>
<main id="main">
{body}
</main>
<footer>
  <div class="wrap">
    <a class="logo" href="../index.html" aria-label="Key Technologies.si — home">
      {LOGO_F}
      <span class="logo-word">KEY TECHNOLOGIES<span class="logo-si">.SI</span></span>
    </a>
    <ul class="foot-links">
      <li><a href="../index.html#services">Services</a></li>
      <li><a href="../index.html#audit">Free Website Audit</a></li>
      <li><a href="../key-platform/index.html#library">Demos</a></li>
      <li><a href="index.html">Guides</a></li>
      <li><a href="../index.html#about">About</a></li>
      <li><a href="../index.html#locations">Locations</a></li>
      <li><a href="../index.html#faq">FAQ</a></li>
      <li><a href="../rewards.html">LVR Rewards</a></li>
      <li><a href="../privacy.html">Privacy</a></li>
      <li><a href="../terms.html">Terms</a></li>
    </ul>
    <a class="foot-phone" href="../book.html">Book a Call</a>
    <p class="foot-fine">Manhattan Beach, California &middot; Las Vegas, Nevada &middot; Remote worldwide &middot; Any language</p>
    <p class="foot-fine">&copy; <span id="kpYear"></span> Key Technologies. All rights reserved.</p>
  </div>
</footer>
<script>(function(){{var b=document.getElementById("burgerBtn"),m=document.getElementById("mobileMenu");if(!b||!m)return;
function c(){{m.classList.remove("open");b.setAttribute("aria-expanded","false");b.setAttribute("aria-label","Open menu")}}
function o(){{m.classList.add("open");b.setAttribute("aria-expanded","true");b.setAttribute("aria-label","Close menu")}}
b.addEventListener("click",function(){{m.classList.contains("open")?c():o()}});
m.querySelectorAll("a").forEach(function(a){{a.addEventListener("click",c)}});
document.addEventListener("keydown",function(e){{if(e.key==="Escape")c()}});
var y=document.getElementById("kpYear");if(y)y.textContent=new Date().getFullYear();
try{{if(localStorage.getItem("lvr_wallet_token")){{var a=document.getElementById("mmAccount");if(a){{a.href=a.href.replace("rewards.html","my-account.html");a.querySelector("span").textContent="My Account";a.querySelector("small").textContent="Logged in"}}}}}}catch(e){{}}
}})();</script>
</body></html>
'''

def crumbs_html(items):
    return '<nav class="crumbs" aria-label="Breadcrumb">' + ' &rsaquo; '.join(f'<a href="{h}">{esc(n)}</a>' for n, h in items[:-1]) + (' &rsaquo; ' if len(items) > 1 else '') + f'<span>{esc(items[-1][0])}</span></nav>'

def graph(title, desc, path, headline, faq, crumb_names, date=None):
    date = date or DATE
    url = BASE + path
    g = [{"@type": "Article", "headline": headline, "description": desc, "mainEntityOfPage": url, "url": url,
          "datePublished": date, "dateModified": date, "image": BASE + "og-image.png",
          "author": {"@type": "Organization", "name": "Key Technologies", "url": BASE},
          "publisher": {"@type": "Organization", "name": "Key Technologies", "url": BASE, "logo": {"@type": "ImageObject", "url": BASE + "icon-512.png"}}},
         {"@type": "BreadcrumbList", "itemListElement": [{"@type": "ListItem", "position": i + 1, "name": n, "item": u} for i, (n, u) in enumerate(crumb_names)]}]
    if faq:
        g.append({"@type": "FAQPage", "mainEntity": [{"@type": "Question", "name": q, "acceptedAnswer": {"@type": "Answer", "text": re.sub(r'<[^>]+>', '', a)}} for q, a in faq]})
    return g

def faq_html(faq):
    return '<h2>Common questions</h2>' + ''.join(f'<h3>{esc(q)}</h3><p>{a}</p>' for q, a in faq)

def cta(extra=''):
    return ('<div class="guide-cta"><h2>Want a second pair of eyes on your website?</h2>'
            '<p>The Free Website Audit looks at your site from the outside and grades it. Or book a free call and we will talk through your situation. No obligation.</p>'
            '<div class="row"><a class="btn btn-primary" href="../index.html#audit">Run the Free Website Audit</a><a class="btn btn-ghost" href="../book.html">Book a free call</a></div></div>' + extra)

def more(links):
    return '<h2>More guides</h2><div class="more">' + ''.join(f'<a href="{h}"><b>{esc(t)}</b><span>{esc(d)}</span></a>' for t, d, h in links) + '</div>'

GUIDES = {}

# ================= Guide 1: PHP2Shell =================
G1 = dict(slug='php2shell-small-business-websites',
  title='PHP2Shell: What Website Owners Do Now | Key Technologies.si',
  desc='Two critical PHP flaws were patched on October 21, 2026. How to check your PHP version, what to ask your host and what to do next.',
  h1='PHP2Shell: what small-business website owners should do now',
  short='What the October 2026 PHP security flaws mean for a WordPress or PHP website, and a 10-minute checklist.')
G1['faq'] = [
 ('Do I need to update WordPress for PHP2Shell?', 'No. The flaws are in PHP, the software the server runs, not in WordPress itself. The fix comes from updating PHP on your hosting. Keep updating WordPress as usual too, but that alone does not close this.'),
 ('Can I wait a few weeks to update PHP?', 'The PHP project rates both flaws 9.2 out of 10 and says they can let an outsider run code without logging in, and it strongly encourages updating right away. News sites also report attackers trying them. Ask your host to apply the update now rather than waiting.'),
 ('How do I know if my website was already hacked?', 'The announcement alone cannot tell you that. Look for the warning signs listed above, ask your host to check their logs, and consider a professional review if anything looks wrong.'),
 ('Does the Free Website Audit tell me if I am patched?', 'No. It looks at your site from the outside for common PHP and WordPress exposure signs, but it cannot see inside your server. Your host or your hosting control panel is the place to confirm your PHP version.')]
G1['body'] = f'''<article class="wrap guide">
{crumbs_html([('Home','../index.html'),('Guides','index.html'),('PHP2Shell','')])}
<h1>{esc(G1['h1'])}</h1>
<p class="byline">Key Technologies &middot; Published and checked against PHP&rsquo;s release notes on November 3, 2026</p>
<div class="tldr"><b>Short answer:</b> PHP, the software that runs a very large number of websites including WordPress, had <b>two critical security flaws announced and fixed on October 21, 2026</b>. If your website runs on PHP, <b>ask your host which PHP version you are on and whether it has the October 21 update</b>. Updating WordPress alone does not fix it.</div>

<h2>What was announced</h2>
<ul>
<li>The PHP project released security updates on <b>October 21, 2026</b>.</li>
<li>They fix two critical flaws, CVE-2026-109618 and CVE-2026-109619, both rated <b>9.2 out of 10</b> on the CVSS v4.0 scale.</li>
<li>PHP&rsquo;s release notes say the flaws can allow <b>unauthenticated remote code execution</b>. In plain words: an outsider could make the server run commands without logging in. Setups that serve web pages are potentially affected, including PHP-FPM, Apache with mod_php, php-cgi, FrankenPHP and LiteSpeed.</li>
<li>The fixed versions are <b>8.5.12, 8.4.27, 8.3.36 and 8.2.35</b>. The project strongly encourages updating immediately.</li>
<li>PHP 8.2 is scheduled to reach the end of its official support on December 31, 2026.</li>
</ul>
<p class="note">Several technology blogs also report that WordPress.org does not plan a WordPress update, because the problem is in PHP and not in WordPress code. That is a report, so confirm with your host, but it matches how the fix works: it is installed on the server, not in WordPress.</p>

<h2>Are attackers actually using it?</h2>
<p>Security news sites report that attackers began trying these flaws, in some reports even before the fix was public, and that at least some attempts have worked. Reports differ on how widespread the damage is, so treat the exact numbers with caution. The practical point is the same either way: this is not a purely theoretical problem, and the fix is simple to ask for.</p>
<p>PHP&rsquo;s developers also reportedly suggested a temporary setting change on servers that could not be updated right away. That is something for your host or developer to apply, not something to edit yourself, so mention it when you ask them.</p>

<h2>Is my website affected?</h2>
<p>You are in the group to check if your site runs on PHP. WordPress does. So do many other website tools and a lot of custom-built sites. Here is the 10-minute check.</p>
<ol>
<li><b>Find out if your site uses PHP.</b> If it is WordPress, Joomla, Drupal or a custom site your developer built on a regular web host, the answer is almost certainly yes. If you are on a hosted website builder or a fully managed WordPress service, the company runs the servers for you. Many of them publish a notice when they have applied a fix, so look for theirs instead of assuming.</li>
<li><b>Find your PHP version.</b> Your hosting control panel usually shows it. In WordPress, go to Tools, then Site Health, then the Info tab, then Server.</li>
<li><b>Compare it to the fixed versions.</b> You want at least 8.5.12, 8.4.27, 8.3.36 or 8.2.35, depending on which branch you are on.</li>
<li><b>Look at older versions closely.</b> If you are on PHP 7.4, 8.0 or 8.1, those branches were not in the list of fixed releases, and they are already past or near the end of official support. Plan to move to a supported version instead of waiting for a fix.</li>
<li><b>Ask your host in writing.</b> Hosts handle this differently, and a written answer is worth having. A message you can copy:</li>
</ol>
<div class="msg">Hello, I run a website on your hosting (domain: ________). Has the October 21, 2026 PHP security release (the fix for CVE-2026-109618 and CVE-2026-109619) been applied to my account? What PHP version is my site running now? If it is not patched, how and when will it be?</div>

<h2>If you cannot update right away</h2>
<ul>
<li><b>Move the site to a host that patches PHP for you.</b> This is often the simplest fix for a small business.</li>
<li><b>Ask whether a web application firewall can be turned on in the meantime.</b> It can reduce risk, but it is a stopgap, not a fix.</li>
<li><b>Take down or replace parts you do not need.</b> Old plugins, test pages and forgotten sub-sites give attackers more to find.</li>
<li><b>Plan the move off PHP if you do not need it.</b> Many small business sites are mostly pages and a contact form. A site built as simple static pages has no PHP on its server to attack. That is how keytechnologies.si is built, so this flaw does not touch it. Static pages are not a cure for everything, but there is much less to attack. See our <a href="../key-platform/demos/php-wordpress-migration.html">WordPress and PHP migration demo</a>.</li>
</ul>

<h2>Signs something may already be wrong</h2>
<ul>
<li>Admin users you do not recognize.</li>
<li>Unfamiliar files or folders on the server, especially with random names.</li>
<li>Visitors being sent to other websites, or strange pages showing in Google for your domain.</li>
<li>Your host warning you about unusual activity or a suspended account.</li>
<li>Your site suddenly slow or sending email you did not write.</li>
</ul>
<p>If you see any of these, change your passwords, tell your host, and get a professional to review the site. This guide is general information, not a security guarantee, and no one can promise a site will never be attacked.</p>

{faq_html(G1['faq'])}

<h2>Sources</h2>
<ul class="src">
<li>PHP project release notes: <a href="https://github.com/php/php-src/releases/tag/php-8.5.12">PHP 8.5.12</a> and <a href="https://github.com/php/php-src/releases/tag/php-8.4.27">PHP 8.4.27</a></li>
<li>PHP project site: <a href="https://www.php.net/">php.net</a> (check it for the latest advice; details can change)</li>
<li>News reports on attacks: <a href="https://bleepingcomputer.com/news/security/php2shell-security-flaws-now-sucessfully-exploited-in-the-wild">BleepingComputer</a> and <a href="https://www.recordedfuture.com/blog/php2shell-vulnerability-exploitation">Recorded Future</a> (secondary sources; scale of attacks is reported differently)</li>
</ul>
<p class="note">Facts above were checked against the PHP project&rsquo;s release notes on November 3, 2026. Hosting status and recommendations change quickly, so confirm with your host.</p>

{cta()}
{more([('AI for restaurants: 6 practical ways to save time','Phones, bookings, reviews, email and social posts, with a demo of each.','ai-for-restaurants.html'),('What is AI/SI? A plain-English guide','What AI and superintelligence mean and how to tell real help from hype.','what-is-ai-si.html'),('How to choose an AI consultant: 10 questions to ask','A plain checklist for small-business owners, including the warning signs.','choose-an-ai-consultant.html')])}
</article>'''
GUIDES['G1'] = G1

# ================= Guide 2: AI receptionist cost =================
G2 = dict(slug='ai-receptionist-cost',
  title='AI Receptionist Cost: What Sets the Price | Key Technologies.si',
  desc='No single price exists for an AI receptionist. See what drives the cost, how vendors charge, hidden costs and the questions to ask.',
  h1='How much does an AI receptionist cost? What actually sets the price',
  short='What drives the price of an AI phone receptionist, how vendors charge, and the questions to ask before you buy.')
G2['faq'] = [
 ('Is an AI receptionist cheaper than a human receptionist?', 'It depends on your call volume and what you need the calls to do. An AI receptionist is often used for after-hours calls and overflow, and it does not replace a person who greets customers in your shop. Compare it to the cost of the calls you miss today, not only to a salary.'),
 ('Why do vendors not publish one price?', 'Because the work differs a lot from business to business: call volume, connected tools, what the assistant is allowed to do and who maintains it. Be careful with any quote given without asking about those.'),
 ('Do I need to tell callers it is an AI?', 'Plan to. Rules on AI disclosure and on recording calls differ by state, so decide your wording and consent steps before going live and ask a lawyer about your situation.'),
 ('Can I try one before paying?', 'You can try our demo to see how it behaves. It is a scripted demo with a made-up business and is not a real phone line.')]
G2['body'] = f'''<article class="wrap guide">
{crumbs_html([('Home','../index.html'),('Guides','index.html'),('AI receptionist cost','')])}
<h1>{esc(G2['h1'])}</h1>
<p class="byline">Key Technologies &middot; Published November 3, 2026</p>
<div class="tldr"><b>Short answer:</b> there is no single price, and be wary of any vendor who quotes one without asking questions. The cost depends mostly on <b>how many calls you get, what the assistant is allowed to do, what it connects to, and who looks after it</b>. This guide shows you what to ask so you can compare quotes fairly. We do not publish a price list here, because the right number depends on those answers.</div>

<h2>What an AI receptionist does</h2>
<p>An AI receptionist answers your business phone, says that it is an AI, answers common questions from information you approved (hours, services, location), collects the caller&rsquo;s details, and can propose an appointment. Anything urgent, unclear or sensitive goes to a real person. You can see this in our <a href="../key-platform/voice/">AI phone receptionist demo</a>, which uses a made-up business and is not a real phone line.</p>

<h2>What drives the price</h2>
<ol>
<li><b>Call volume.</b> More calls and longer calls mean more usage. Ask whether you pay per minute, per call or per month.</li>
<li><b>What it is allowed to do.</b> Answering common questions is simple. Booking into a calendar, texting confirmations or taking payments each add setup and risk.</li>
<li><b>Connections to your tools.</b> Calendar, customer list (CRM), email and text messaging each need to be connected and kept working.</li>
<li><b>Phone line setup.</b> Forwarding your existing number, getting a new number or moving a number between providers can each carry a one-time or monthly cost.</li>
<li><b>Human handoff and after-hours rules.</b> Who gets the urgent call at 9 p.m.? Setting that up well takes thought.</li>
<li><b>Languages and voices.</b> Extra languages or a custom voice can cost more.</li>
<li><b>Rules you must follow.</b> Telling callers it is an AI and getting consent to record calls vary by state. Getting this right takes setup time.</li>
<li><b>Who looks after it.</b> Someone has to watch the calls, fix wrong answers and update information when your hours or prices change. Check whether that is included.</li>
</ol>

<h2>How vendors usually charge</h2>
<ul>
<li><b>A monthly plan</b> with a set number of calls or minutes included.</li>
<li><b>Pay per minute or per call</b>, which can be cheap when quiet and surprising when busy.</li>
<li><b>A one-time setup fee</b> plus a monthly service fee.</li>
<li><b>Per booked appointment or per lead</b>, which sounds fair but needs a clear definition of what counts.</li>
</ul>

<h2>Costs people miss</h2>
<ul>
<li>Overage charges when you go past included calls or minutes.</li>
<li>Extra fees for each connected tool or each extra number.</li>
<li>Charges for changes after setup (new hours, new services).</li>
<li>Minimum contract lengths and cancellation terms.</li>
<li>Your own time to review calls and correct the assistant at the start.</li>
</ul>

<h2>Questions to ask any vendor</h2>
<ol>
<li>What is included in the monthly price, and what counts as extra?</li>
<li>What happens when I go over my calls or minutes?</li>
<li>Will it tell callers it is an AI, and how are call recordings and consent handled?</li>
<li>What will it never answer on its own, and where do those calls go?</li>
<li>Which of my tools does it connect to, and who maintains those connections?</li>
<li>Who fixes a wrong answer, and how fast?</li>
<li>Can I leave, and do I keep my phone number and my data?</li>
<li>Can I hear real sample calls, not only a recorded demo?</li>
</ol>

<h2>How to estimate what it is worth to you</h2>
<p>Use your own numbers, not a vendor&rsquo;s. For a week, count: (1) the calls you miss or send to voicemail, (2) roughly how many of those would have become a paying customer, and (3) what an average customer is worth. Multiply them together. That is the order of magnitude of what missed calls cost you, and it tells you how much an AI receptionist could be worth. If the figure is small, a simpler fix such as a better voicemail message may be enough, and we will tell you so.</p>

<h2>Where Key Technologies fits</h2>
<p>We set up and look after AI phone and text answering for small businesses. We quote after learning your call volume, your workflow and the rules that apply to you, so the number is real. The first conversation is free, with no obligation and no sales pitch about tools you do not need.</p>

{faq_html(G2['faq'])}

<div class="guide-cta"><h2>Want a real quote for your business?</h2>
<p>Try the demo first, then book a free call. We will ask about your calls and tell you honestly if an AI receptionist is worth it for you.</p>
<div class="row"><a class="btn btn-primary" href="../book.html">Book a free call</a><a class="btn btn-ghost" href="../key-platform/voice/">Try the receptionist demo</a></div></div>
{more([('PHP2Shell: what small-business website owners should do now','Two critical PHP flaws were patched on October 21, 2026. A 10-minute checklist.','php2shell-small-business-websites.html'),('AI for restaurants: 6 practical ways to save time','Phones, bookings, reviews, email and social posts, with a demo of each.','ai-for-restaurants.html'),('What is AI/SI? A plain-English guide','What AI and superintelligence mean and how to tell real help from hype.','what-is-ai-si.html'),('How to choose an AI consultant: 10 questions to ask','A plain checklist for small-business owners, including the warning signs.','choose-an-ai-consultant.html')])}
</article>'''
RETIRED_GUIDES = ['ai-receptionist-cost']  # taken down at Shane's request (2026-11-05): anything to do with pricing

# ================= Guide 3: AI for restaurants =================
G3 = dict(slug='ai-for-restaurants',
  title='AI for Restaurants: 6 Practical Uses | Key Technologies.si',
  desc='Six practical uses of AI for a restaurant: phones, reminders, review replies, catering email, social posts and a menu assistant. A demo of each.',
  h1='AI for restaurants: 6 practical ways to save time',
  short='Six practical uses of AI in a restaurant, what it should and should not do, and a demo of each.')
G3['faq'] = [
 ('Will AI replace my staff?', 'No. The useful jobs are the repetitive ones: answering the same questions, sending reminders and drafting replies. Guests still want a person for a welcome, a problem or a special occasion.'),
 ('Can AI answer questions about allergies?', 'Not on its own. Allergy and food-safety questions should come from your approved menu information, and anything uncertain or urgent should go straight to a person on your team.'),
 ('Does AI work with OpenTable or my reservation system?', 'It depends on the system and what it allows. Many restaurants already use a reservation platform, and AI is often best placed beside it, handling phone questions and reminders. We would check your setup first.'),
 ('Is this expensive to try?', 'Start small. Pick the one task that costs you the most time, such as missed phone calls or review replies, and try that first. Our demos are free to try and use made-up data.')]
G3['body'] = f'''<article class="wrap guide">
{crumbs_html([('Home','../index.html'),('Guides','index.html'),('AI for restaurants','')])}
<h1>{esc(G3['h1'])}</h1>
<p class="byline">Key Technologies &middot; Published November 3, 2026</p>
<div class="tldr"><b>Short answer:</b> the best uses of AI in a restaurant are the <b>repetitive, rules-based jobs</b>: answering the same phone questions, sending reminders, drafting replies and posts. A person should stay in charge of anything involving food safety, money, complaints and guests who need real hospitality. Start with one job, not six.</div>

<p>Restaurant owners are busy and the phone does not stop. Here are six jobs where AI can help today. Each one has a demo on this site with made-up data, so you can see how it behaves before you think about your own business.</p>

<h2>1. Answering the phone</h2>
<p><b>What it does:</b> picks up when your team is busy or closed, says it is an AI, answers questions about hours, location, parking and menu, takes a message and passes urgent calls to a person.</p>
<p><b>What stays human:</b> complaints, large events, anything about allergies or safety, and any call the assistant is unsure about.</p>
<p><a class="tap" href="../key-platform/voice/">Try the AI phone receptionist demo</a></p>

<h2>2. Booking and reminders</h2>
<p><b>What it does:</b> lets a guest pick a time, sends a confirmation, and sends reminders so fewer people forget. It can also free up a table when someone cancels.</p>
<p><b>What stays human:</b> special requests and your rules for large parties. If you already use a reservation platform, AI works best beside it rather than replacing it.</p>
<p><a class="tap" href="../key-platform/demos/booking-scheduling.html">Try the booking and reminders demo</a></p>

<h2>3. Replying to reviews</h2>
<p><b>What it does:</b> collects new reviews in one place and drafts a polite reply in your voice, so you answer every review quickly.</p>
<p><b>What stays human:</b> you approve every reply, and negative reviews go to you first. It should never write fake reviews or offer rewards for good ones, which the review sites forbid.</p>
<p><a class="tap" href="../key-platform/demos/reviews-reputation.html">Try the review management demo</a></p>

<h2>4. Catering and event email</h2>
<p><b>What it does:</b> sorts incoming email into catering requests, vendor questions and everything else, and drafts a first reply with your menu and policies.</p>
<p><b>What stays human:</b> quotes, contracts and refunds. A person reads and approves each reply before it is sent.</p>
<p><a class="tap" href="../key-platform/email/">Try the AI email assistant demo</a></p>

<h2>5. Social media posts</h2>
<p><b>What it does:</b> drafts captions and post ideas around your dishes, specials and events in your tone, on a weekly calendar.</p>
<p><b>What stays human:</b> your real photos and your approval. Guests can tell generic content from the real thing, so use AI for the first draft and your own food for the picture.</p>
<p><a class="tap" href="../key-platform/demos/content-creators.html">Try the content creator demo</a> &middot; <a href="../key-platform/demos/social-media.html">Try the social media demo</a></p>

<h2>6. A menu and policy assistant</h2>
<p><b>What it does:</b> answers staff and guests from your own documents: menu, hours, gift card rules, parking, event packages. If the answer is not in the documents, it says so.</p>
<p><b>What stays human:</b> keep the source documents current, and have a person handle anything about allergens that is not clearly written down.</p>
<p><a class="tap" href="../key-platform/demos/data-knowledge.html">Try the knowledge assistant demo</a></p>

<h2>Where not to use AI</h2>
<ul>
<li><b>Allergy and food-safety answers that are not in your approved information.</b> Send them to a person.</li>
<li><b>Refunds, comps and disputes.</b> A person decides.</li>
<li><b>Fake reviews or fake testimonials.</b> Never.</li>
<li><b>Anything you would not be comfortable explaining to the guest.</b> If a guest would feel tricked, do not do it.</li>
</ul>

<h2>How to start</h2>
<ol>
<li>Pick the one task that costs you the most time or the most missed business.</li>
<li>Try its demo so you know what good looks like.</li>
<li>Write down what must always go to a person.</li>
<li>Start small, review the results every week for the first month, then decide on the next task.</li>
</ol>

{faq_html(G3['faq'])}

<div class="guide-cta"><h2>Want to talk about your restaurant?</h2>
<p>Tell us where your time goes and we will say honestly whether AI can help and where to start. The first call is free.</p>
<div class="row"><a class="btn btn-primary" href="../book.html">Book a free call</a><a class="btn btn-ghost" href="../key-platform/index.html#library">See all the demos</a></div></div>
{more([('PHP2Shell: what small-business website owners should do now','Two critical PHP flaws were patched on October 21, 2026. A 10-minute checklist.','php2shell-small-business-websites.html'),('What is AI/SI? A plain-English guide','What AI and superintelligence mean and how to tell real help from hype.','what-is-ai-si.html'),('How to choose an AI consultant: 10 questions to ask','A plain checklist for small-business owners, including the warning signs.','choose-an-ai-consultant.html')])}
</article>'''
GUIDES['G3'] = G3

# ================= Guide 4: What is AI/SI? =================
G4 = dict(slug='what-is-ai-si', date='2026-11-05',
  title='What Is AI/SI? Plain-English Guide | Key Technologies.si',
  desc='AI/SI explained without hype: what AI and superintelligence mean, what AI can and cannot do for a small business today, and how to tell real from hype.',
  h1='What is AI/SI? A plain-English guide for business owners',
  short='What AI and superintelligence mean, what AI can and cannot do for a small business today, and how to tell real help from hype.')
G4['faq'] = [
 ('What does AI/SI stand for?', 'AI/SI stands for Artificial Intelligence / Super Intelligence. Key Technologies uses it as its name for putting the most advanced AI available to work as a practical business tool. It is not a claim that anyone has built superintelligence.'),
 ('Is AI/SI the same as AGI?', 'No. AGI usually means an AI as capable as a person across most tasks. Superintelligence means beyond the best humans. Neither is a product you can buy today, and Key Technologies does not claim to sell either one.'),
 ('Is Key Technologies building superintelligent AI?', 'No. We build practical systems for businesses (phone answering, content, CRM, automation) using the strongest AI tools available, with a person approving anything important.'),
 ('Can AI make mistakes?', 'Yes. AI can write a confident answer that is wrong, so anything that goes to a customer, touches money, or involves legal or medical matters should be checked by a person. Good systems are built with that in mind.'),
 ('Do I need to know which AI tools I need?', 'No. Start from the problem (missed calls, slow follow-up, repetitive work), not the tool. A free conversation is enough to find out whether AI helps and where.'),
 ('Where should a small business start?', 'Pick one repetitive job that costs you time or customers, try a small version, and measure the result before doing more. Our free Website Audit and a free call are two easy first steps.')]
G4['body'] = f"""<article class="wrap guide">
{crumbs_html([('Home','../index.html'),('Guides','index.html'),('What is AI/SI?','')])}
<h1>{esc(G4['h1'])}</h1>
<p class="byline">Key Technologies &middot; Published November 5, 2026</p>
<div class="tldr"><b>Short answer:</b> <b>AI/SI</b> stands for <b>Artificial Intelligence / Super Intelligence</b>. It is how Key Technologies describes putting the most advanced AI available to work as a <b>practical business tool</b>. It is <b>not</b> a claim that superintelligent AI exists today. This guide explains the terms in plain language, what AI can and cannot do for a small business right now, and how to tell real help from hype.</div>

<h2>What &ldquo;AI&rdquo; means</h2>
<p>Artificial intelligence, or AI, is software that can do tasks that normally need human judgment: writing and summarizing text, answering questions, sorting messages, spotting patterns, understanding speech. The tools in the news today, such as chatbots and voice assistants, are AI.</p>

<h2>What &ldquo;superintelligence&rdquo; means</h2>
<p>In research, <b>superintelligence</b> is a hypothetical AI that is better than the best humans at almost every thinking task. It is a topic of serious debate, and it does <b>not</b> exist today. Related words you may see: <b>AGI</b> (artificial general intelligence), usually meaning an AI as capable as a person across most tasks. Be wary of anyone who says they are selling either one.</p>

<h2>Why we write &ldquo;AI/SI&rdquo;</h2>
<p>At Key Technologies the two letters work as a pair. The <b>AI</b> side is the strategy and automation we build around how your business actually works. The <b>SI</b> side is the tool itself: the most advanced, frontier-level AI we put to work for you, backed by real security and infrastructure basics so the result holds up and is not just a demo that looks good once. It is also built into our own address, keytechnologies.si.</p>

<h2>What it looks like in a small business</h2>
<ul>
<li><b>Phones and texts:</b> an assistant answers common questions, takes details and passes anything urgent to a person.</li>
<li><b>Reviews and email:</b> drafts replies in your own voice that you approve before anything is sent.</li>
<li><b>Content:</b> posts, captions and graphics made on a schedule, with you deciding how much freedom it has.</li>
<li><b>Customer list (CRM):</b> leads captured, sorted and followed up so nobody goes cold.</li>
<li><b>Busywork:</b> connecting the steps that already exist so people stop re-typing the same information.</li>
</ul>
<p>You can try each of these in our <a href="../key-platform/">interactive demos</a>. They use made-up data and nothing is sent, booked or charged.</p>

<h2>What AI is good at today, and where it needs a person</h2>
<ul>
<li><b>Good at:</b> drafting, summarizing, sorting, answering from information you approved, and doing the same small job the same way every time.</li>
<li><b>Needs a person:</b> anything that goes to a customer for the first time, anything involving money, contracts, or legal or medical matters, and any decision that depends on judgment about your relationships.</li>
<li><b>Can be wrong:</b> AI can write a confident answer that is false. A well-built system limits what the AI may do and keeps a person in charge of the rest.</li>
</ul>

<h2>How to tell real help from hype</h2>
<ol>
<li><b>Does it start with a problem or a tool?</b> A good provider asks what is going wrong in your business first.</li>
<li><b>Can you see it working?</b> Ask for a demo or a live example, not only slides.</li>
<li><b>Are the limits stated?</b> Honest providers say what AI will not do and where a person stays in charge.</li>
<li><b>Who owns your accounts and data?</b> They should stay in your name.</li>
<li><b>Are the claims believable?</b> Be careful with promises of guaranteed results, instant revenue or &ldquo;replacing your whole team.&rdquo;</li>
</ol>

<h2>Where Key Technologies fits</h2>
<p>We help small and mid-sized businesses use AI in practical, safe ways: strategy, automation, AI assistants, phone and email help, custom software, security and training. The first conversation is free, with no obligation and no sales pitch about tools you do not need. Key Technologies does not guarantee results.</p>

{faq_html(G4['faq'])}

<div class="guide-cta"><h2>Curious what AI could do for your business?</h2>
<p>Book a free call and we will talk it through, or run the Free Website Audit to see where your site stands.</p>
<div class="row"><a class="btn btn-primary" href="../book.html">Book a free call</a><a class="btn btn-ghost" href="../index.html#audit">Run the Free Website Audit</a></div></div>
{more([('How to choose an AI consultant: 10 questions to ask','A plain checklist for small-business owners, including the warning signs.','choose-an-ai-consultant.html'),('AI for restaurants: 6 practical ways to save time','Phones, bookings, reviews, email and social posts, with a demo of each.','ai-for-restaurants.html'),('What is AI/SI? A plain-English guide','What AI and superintelligence mean and how to tell real help from hype.','what-is-ai-si.html'),('How to choose an AI consultant: 10 questions to ask','A plain checklist for small-business owners, including the warning signs.','choose-an-ai-consultant.html')])}
</article>"""
GUIDES['G4'] = G4

# ================= Guide 5: choosing an AI consultant =================
G5 = dict(slug='choose-an-ai-consultant', date='2026-11-05',
  title='Choose an AI Consultant: 10 Questions | Key Technologies.si',
  desc='Ten plain questions to ask before hiring an AI consultant or agency, what a good answer sounds like, and the warning signs to watch for.',
  h1='How to choose an AI consultant: 10 questions to ask',
  short='A plain checklist for small-business owners: ten questions to ask, what good answers sound like, and the warning signs.')
G5['faq'] = [
 ('Do I need an AI consultant, or can I use a chatbot myself?', 'You can start on your own for drafting and brainstorming. A consultant helps when AI has to connect to your phones, customer list or website, when customers will see the output, or when security and accuracy matter.'),
 ('What should I prepare before the first call?', 'Write down the one or two jobs that cost you the most time or customers, the tools you use today, and what a good result would look like. You do not need to know which AI tools you want.'),
 ('Should I be worried if a consultant will not name a price on the first call?', 'No. A fair quote needs to know what you want built. Be careful if there is no written scope afterwards, or if the price keeps changing without a change in what you asked for.'),
 ('Who should own the accounts and data?', 'You. Your accounts, domain, customer list and data should stay in your name. A good consultant needs login access to do the work, but should never become the owner.'),
 ('How can I check a consultant is real?', 'Ask to see work you can try yourself, such as a demo or a system they run for their own business, and talk to them directly, not only to a sales form.')]
G5['body'] = f"""<article class="wrap guide">
{crumbs_html([('Home','../index.html'),('Guides','index.html'),('How to choose an AI consultant','')])}
<h1>{esc(G5['h1'])}</h1>
<p class="byline">Key Technologies &middot; Published November 5, 2026</p>
<div class="tldr"><b>Short answer:</b> choose the consultant who <b>starts with your problem, shows you something real, says what AI will not do, and leaves you owning your accounts and data</b>. The ten questions below help you check each of those. We are an AI consultancy ourselves, so we have written this to be useful whoever you hire.</div>

<h2>The ten questions</h2>
<ol>
<li><b>What problem do you think I should solve first?</b> A good answer comes from questions about your business. A weak answer starts with a tool or a product name.</li>
<li><b>Can I see something working?</b> Look for a demo you can try or a live system they run themselves. Slides are not proof.</li>
<li><b>What will the AI not do on its own?</b> You want a clear line: what is automatic, what needs your approval, and what stays with a person.</li>
<li><b>What happens when the AI is wrong?</b> AI can be confidently wrong. Ask how mistakes are caught, logged and fixed.</li>
<li><b>Who owns my accounts, domain, customer list and data?</b> The answer should be you, in your name.</li>
<li><b>What access do you need, and how is it kept safe?</b> Real work needs login access. Ask about passwords, who has access, and what happens if something goes wrong.</li>
<li><b>How will we know it is working?</b> Agree on one or two simple measures before you start, such as missed calls or hours saved, and check them after.</li>
<li><b>What will it cost, in writing?</b> Ask for a written scope that says what is included, what is extra, and what ongoing costs there are.</li>
<li><b>What rules apply to my business?</b> Telling callers they are speaking to an AI, recording calls, privacy, and advertising rules differ by place and industry. A good consultant raises these, and you should check with a lawyer where it matters.</li>
<li><b>Can I leave, and what do I keep?</b> You should be able to take your systems, data and phone number with you.</li>
</ol>

<h2>Warning signs</h2>
<ul>
<li>Promises of guaranteed results, instant revenue, or replacing your whole team.</li>
<li>No written scope, or a price that changes without your request changing.</li>
<li>Pressure to decide on the first call.</li>
<li>Reluctance to show anything you can try yourself.</li>
<li>Asking to own or hold your accounts instead of using access you grant.</li>
<li>Skipping the limits: no word about mistakes, privacy or when a person steps in.</li>
</ul>

<h2>What a good first conversation looks like</h2>
<p>It should feel like a diagnosis: questions about how your business runs today, where time or customers are lost, and what has been tried. You should leave knowing whether AI helps, where it helps first, and what a small first step looks like. Sometimes the honest answer is that a simpler fix works better.</p>

<h2>Where Key Technologies fits</h2>
<p>Key Technologies helps small and mid-sized businesses with AI strategy, automation, assistants, custom software, security and training. Our <a href="../key-platform/">demos</a> let you try each service with made-up data, and the founder, Shane Christensen, runs his own custom customer-tracking system. The first conversation is free, with no obligation. We do not guarantee results.</p>

{faq_html(G5['faq'])}

<div class="guide-cta"><h2>Want to talk it through?</h2>
<p>Book a free call and bring your questions, including these ten.</p>
<div class="row"><a class="btn btn-primary" href="../book.html">Book a free call</a><a class="btn btn-ghost" href="../key-platform/">Try the demos</a></div></div>
{more([('What is AI/SI? A plain-English guide','What AI and superintelligence mean and how to tell real help from hype.','what-is-ai-si.html'),('AI for restaurants: 6 practical ways to save time','Phones, bookings, reviews, email and social posts, with a demo of each.','ai-for-restaurants.html')])}
</article>"""
GUIDES['G5'] = G5

# ================= Guide 6: AI glossary =================
G6 = dict(slug='ai-terms-plain-english', date='2026-11-06',
  title='AI Terms in Plain English: A Glossary | Key Technologies.si',
  desc='A plain-English glossary of AI terms for business owners: AI, AI/SI, LLM, AI agent, automation, CRM, hallucination, prompt and more.',
  h1='AI terms in plain English: a glossary for business owners',
  short='Short, jargon-free definitions of the AI words business owners hear most, with a note on what each means for you.')
TERMS = [
 ('AI (artificial intelligence)', 'Software that can do tasks that normally need human judgment, such as writing, summarizing, answering questions, sorting messages or understanding speech.'),
 ('AI/SI', 'Artificial Intelligence / Super Intelligence. Key Technologies uses it as its name for putting the most advanced AI available to work as a practical business tool. It is not a claim that superintelligence exists. See <a href="what-is-ai-si.html">What is AI/SI?</a>'),
 ('Superintelligence', 'A hypothetical AI that is better than the best humans at almost every thinking task. It does not exist today.'),
 ('AGI (artificial general intelligence)', 'A hypothetical AI as capable as a person across most tasks. It is a research goal, not a product you can buy today.'),
 ('LLM (large language model)', 'The kind of AI behind many chatbots. It is trained on large amounts of text and predicts useful words, which is why it can write, summarize and answer questions. It can also be wrong.'),
 ('Chatbot', 'A program you talk to by typing. Some are simple scripts; others use an LLM.'),
 ('AI assistant', 'An AI tool set up for a specific job, such as answering your business phone or drafting replies to reviews, usually with limits on what it may do.'),
 ('AI agent', 'An AI assistant that can take steps on its own, such as looking up information or filling in a form, inside permission levels you set. A good agent asks a person before anything important.'),
 ('Automation', 'Software that does a repeated job on its own, such as sending a reminder or copying details from one system to another. Automation does not need AI, and AI can make it more flexible.'),
 ('CRM (customer relationship management)', 'The system where you keep your customers and leads, and note what happened with each one, so follow-ups do not slip.'),
 ('Prompt', 'The instruction you give an AI. Clear instructions with examples usually get better results.'),
 ('Hallucination', 'When an AI writes something that sounds confident but is false. It is the main reason a person should check anything important.'),
 ('Human in the loop', 'A setup where a person approves what the AI does before it goes out or takes effect.'),
 ('Training data', 'The material an AI learned from. A private AI for your business is set up to use your documents without sharing them with others.'),
 ('RAG (retrieval-augmented generation)', 'A way to let an AI answer from your own documents: it looks up the right passage first, then writes the answer from it. It helps keep answers tied to what you approved.'),
 ('API', 'A way for two programs to talk to each other, such as your website sending a form to your customer list.'),
 ('Voice AI / AI receptionist', 'An AI that answers phone calls, takes details and passes anything urgent to a person. It should tell callers it is an AI.'),
 ('Workflow', 'The steps a job goes through from start to finish, such as inquiry, reply, booking, reminder. Mapping the workflow is the first step in deciding what to automate.'),
 ('Fine-tuning', 'Extra training that adapts an AI to a style or task. Many business jobs do not need it; giving the AI good instructions and your documents is often enough.'),
]
G6['faq'] = [(f'What is {t.split(" (")[0]}?', re.sub(r'<[^>]+>', '', d)) for t, d in TERMS[:6]]
_items = ''.join(f'<dt><b>{esc(t)}</b></dt><dd>{d}</dd>' for t, d in TERMS)
G6['body'] = f"""<article class="wrap guide">
{crumbs_html([('Home','../index.html'),('Guides','index.html'),('AI terms in plain English','')])}
<h1>{esc(G6['h1'])}</h1>
<p class="byline">Key Technologies &middot; Published November 6, 2026</p>
<div class="tldr"><b>Short answer:</b> here are the AI words business owners hear most, each in one or two plain sentences. Skim for the one you just heard, or read it top to bottom. If a term is not here, <a href="../book.html">ask us on a free call</a>.</div>
<dl class="glossary">{_items}</dl>
<h2>Where to go next</h2>
<p>If you are deciding whether AI can help your business, start with <a href="choose-an-ai-consultant.html">ten questions to ask any AI consultant</a>, then try our <a href="../key-platform/">interactive demos</a> (made-up data, nothing is sent or charged). The first conversation with us is free, with no obligation. Key Technologies does not guarantee results.</p>
<div class="guide-cta"><h2>Have a question about an AI term or tool?</h2>
<p>Book a free call and ask. We will tell you honestly what we know.</p>
<div class="row"><a class="btn btn-primary" href="../book.html">Book a free call</a><a class="btn btn-ghost" href="../index.html#audit">Run the Free Website Audit</a></div></div>
{more([('What is AI/SI? A plain-English guide','What AI and superintelligence mean and how to tell real help from hype.','what-is-ai-si.html'),('How to choose an AI consultant: 10 questions to ask','A plain checklist for small-business owners, including the warning signs.','choose-an-ai-consultant.html')])}
</article>"""
GUIDES['G6'] = G6

# ================= Guide 7: AI for law firms =================
G7 = dict(slug='ai-for-law-firms', date='2026-11-06',
  title='AI for Law Firms: Where It Helps | Key Technologies.si',
  desc='Where AI helps a law office (intake, scheduling, routine drafts), what a lawyer must still approve, and the confidentiality questions to ask.',
  h1='AI for law firms: where it helps and what a person must still approve',
  short='Where AI helps a law office, what a lawyer must still approve, and the confidentiality questions to ask before using it.')
G7['faq'] = [
 ('Can AI give legal advice to my clients?', 'It should not. Legal advice is the lawyer\'s job. AI can collect details, answer routine office questions from information you approved, and route anything that needs a lawyer to a lawyer.'),
 ('Is it safe to put client information into an AI tool?', 'It depends on the tool and its terms. Ask where the data goes, whether it is used to train the provider\'s models, who can see it, and how it is deleted. Check your state bar\'s guidance and, if unsure, your ethics counsel.'),
 ('Can AI draft documents?', 'It can produce a first draft of routine letters and summaries. A lawyer must review every word before it goes out, and must verify every citation, because AI can invent sources that do not exist.'),
 ('How can AI help with intake?', 'It can answer calls and texts after hours, collect the basics, and flag urgent matters, so a prospective client is not left waiting. A person decides whether to take the matter.'),
 ('Where should a small firm start?', 'Pick one low-risk, repetitive job, such as after-hours call capture or appointment reminders, keep a person in charge, and measure the result before adding more.')]
G7['body'] = f"""<article class="wrap guide">
{crumbs_html([('Home','../index.html'),('Guides','index.html'),('AI for law firms','')])}
<h1>{esc(G7['h1'])}</h1>
<p class="byline">Key Technologies &middot; Published November 6, 2026</p>
<div class="tldr"><b>Short answer:</b> AI is useful in a law office for the <b>routine, repetitive work around the law</b>: intake, scheduling, reminders and first drafts of routine messages. It should not replace the lawyer&rsquo;s judgment. A person must approve anything that is legal advice, anything filed or sent for the first time, and anything that touches client confidences. This guide is general information, not legal advice.</div>

<h2>Where AI helps a law office</h2>
<ul>
<li><b>Intake:</b> answer calls and texts after hours, collect the basics, and flag urgent matters, so a prospective client is not left waiting. The firm that answers first often gets the call.</li>
<li><b>Scheduling and reminders:</b> consultation booking, confirmations and reminders without staff re-typing.</li>
<li><b>Follow-up:</b> messages to people who have not yet signed, so a lead does not go cold.</li>
<li><b>Routine drafts:</b> a first draft of a standard letter or a summary of a long email thread, for a person to review and rewrite.</li>
<li><b>Reviews and reputation:</b> drafted replies to online reviews that you approve before posting.</li>
</ul>

<h2>What a person must still approve</h2>
<ol>
<li><b>Legal advice.</b> The assistant may answer office questions (hours, how to get documents to you). Legal questions go to a lawyer.</li>
<li><b>Anything filed or sent for the first time.</b> Read it, and check every citation yourself. AI can produce sources that sound real and are not, and courts have criticized filings that contained them.</li>
<li><b>Conflicts and taking the matter.</b> Whether to take a case is a decision for the firm, not the tool.</li>
<li><b>Fees and engagement terms.</b> These come from a person.</li>
<li><b>Anything involving client confidences</b> until you are satisfied how the tool handles them.</li>
</ol>

<h2>Confidentiality questions to ask any vendor</h2>
<ol>
<li>Where does my data go, and who can see it?</li>
<li>Is it used to train the provider&rsquo;s models?</li>
<li>How is it stored, and how is it deleted when I leave?</li>
<li>Can I limit what the assistant may see and do?</li>
<li>What does your agreement say if something goes wrong?</li>
</ol>
<p>Rules on technology and client information differ by state and by matter. Check your state bar&rsquo;s guidance, and ask your ethics counsel if you are unsure.</p>

<h2>A sensible way to start</h2>
<p>Pick one low-risk, repetitive job (after-hours call capture is common), keep a person in charge, and decide in advance how you will measure it. Review what the assistant did each week at the start and correct it. Add more only when the first job is working.</p>

<h2>Where Key Technologies fits</h2>
<p>We build custom intake systems and automation for law firms around how your firm actually works, with permission levels you set so you decide how much runs on its own. See our <a href="../law.html">law firm page</a>, try the <a href="../key-platform/">interactive demos</a> (made-up data), or book a free call. We do not guarantee results and we do not give legal advice.</p>

{faq_html(G7['faq'])}

<div class="guide-cta"><h2>Want to talk it through?</h2>
<p>Book a free call. We will ask how your intake works today and tell you honestly where AI helps and where it does not.</p>
<div class="row"><a class="btn btn-primary" href="../book.html">Book a free call</a><a class="btn btn-ghost" href="../law.html">See the law firm page</a></div></div>
{more([('How to choose an AI consultant: 10 questions to ask','A plain checklist for small-business owners, including the warning signs.','choose-an-ai-consultant.html'),('AI terms in plain English: a glossary','Short, jargon-free definitions of the AI words business owners hear most.','ai-terms-plain-english.html')])}
</article>"""
GUIDES['G7'] = G7

# ================= Guide 8: AI for medical and dental offices =================
G8 = dict(slug='ai-for-medical-dental-offices', date='2026-11-06',
  title='AI for Medical and Dental Offices | Key Technologies.si',
  desc='Where AI helps a medical or dental office (calls, booking, reminders), what staff must still handle, and privacy questions to ask first.',
  h1='AI for medical and dental offices: where it helps and the privacy questions to ask first',
  short='Where AI helps a medical or dental office, what staff and clinicians must still handle, and the privacy questions to ask first.')
G8['faq'] = [
 ('Can AI give medical or dental advice to patients?', 'It should not. Clinical advice is for the clinician. AI can answer office questions from information you approved (hours, location, how to prepare for a visit) and route anything clinical to a person.'),
 ('Is it safe to put patient information into an AI tool?', 'Only if the tool and its agreement meet your obligations. In the United States, providers that handle protected health information generally need the right agreements and safeguards in place. Ask your compliance advisor or attorney before any patient information goes into a new tool.'),
 ('What can AI do without touching patient records?', 'Many useful jobs need no patient records: answering general questions, collecting a name and callback number, sending appointment reminders from a schedule you control, and drafting replies to public reviews.'),
 ('How can AI help with missed calls?', 'It can answer after hours, collect a name and number and the reason for the call, flag anything urgent for a person, and propose appointment times for staff to confirm.'),
 ('Where should a practice start?', 'Pick one low-risk job that does not involve clinical decisions, such as after-hours call capture or reminders, keep a person in charge, and check the results weekly before adding more.')]
G8['body'] = f"""<article class="wrap guide">
{crumbs_html([('Home','../index.html'),('Guides','index.html'),('AI for medical and dental offices','')])}
<h1>{esc(G8['h1'])}</h1>
<p class="byline">Key Technologies &middot; Published November 6, 2026</p>
<div class="tldr"><b>Short answer:</b> AI is most useful in a medical or dental office for the <b>front-desk work around care</b>: answering calls, booking, reminders and replies to reviews. It should not give clinical advice, and patient information should only go into a tool after you have checked the privacy and legal side. This guide is general information, not legal or medical advice, and it does not certify any tool as compliant.</div>

<h2>Where AI helps</h2>
<ul>
<li><b>Calls and texts:</b> answer after hours, take a name, number and reason for the call, and flag anything urgent for a person.</li>
<li><b>Booking and reminders:</b> propose appointment times, send confirmations and reminders from a schedule you control, and reduce no-shows.</li>
<li><b>Patient follow-up messages:</b> general reminders and practice news that a person approves.</li>
<li><b>Reviews and reputation:</b> drafted replies to public reviews for you to edit and approve. Never confirm that someone is a patient in a public reply.</li>
<li><b>Staff time:</b> summaries of long email threads and first drafts of routine office letters, reviewed by a person.</li>
</ul>

<h2>What people must still handle</h2>
<ol>
<li><b>Clinical advice and triage.</b> Anything about symptoms, treatment, medication or urgency goes to a clinician. A good assistant says so and hands off.</li>
<li><b>Emergencies.</b> The assistant should tell callers with an emergency to call emergency services, and route urgent calls to a person.</li>
<li><b>Anything that goes into a patient record.</b> A person reviews and enters it.</li>
<li><b>Anything involving consent, billing disputes or complaints.</b></li>
<li><b>Final say on every message sent to a patient for the first time.</b></li>
</ol>

<h2>Privacy questions to ask first</h2>
<ol>
<li>Will patient information go into this tool, and does the job really need it? Often it does not.</li>
<li>Where does the data go, who can see it, and is it used to train the provider&rsquo;s models?</li>
<li>Does the provider sign the agreements your situation requires (for example, a business associate agreement in the United States where it applies)?</li>
<li>How is data stored, protected and deleted when you leave?</li>
<li>Can you limit what the assistant can see and do, and is there a log of what it did?</li>
</ol>
<p>Rules differ by country, state and type of practice. Check with your compliance advisor or attorney before using any tool with patient information. Nothing here certifies a tool or a practice as compliant.</p>

<h2>A sensible way to start</h2>
<p>Pick one low-risk job that involves no clinical decisions (after-hours call capture is common), keep a person in charge, and review what the assistant did each week at the start. Add more only when the first job is working and your privacy questions are answered.</p>

<h2>Where Key Technologies fits</h2>
<p>We build patient-communication systems and automation for medical and dental offices around how your office actually works, with permission levels you set. See our <a href="../medical-dental.html">medical and dental page</a>, try the <a href="../key-platform/">interactive demos</a> (made-up data), or book a free call. We do not guarantee results, and we do not give legal or medical advice.</p>

{faq_html(G8['faq'])}

<div class="guide-cta"><h2>Want to talk it through?</h2>
<p>Book a free call. We will ask how your front desk works today and tell you honestly where AI helps and where it does not.</p>
<div class="row"><a class="btn btn-primary" href="../book.html">Book a free call</a><a class="btn btn-ghost" href="../medical-dental.html">See the medical and dental page</a></div></div>
{more([('AI for law firms: where it helps and what a person must still approve','Where AI helps a law office, what a lawyer must still approve, and confidentiality questions.','ai-for-law-firms.html'),('How to choose an AI consultant: 10 questions to ask','A plain checklist for small-business owners, including the warning signs.','choose-an-ai-consultant.html')])}
</article>"""
GUIDES['G8'] = G8

# ================= Guide 9: business dashboards =================
G9 = dict(slug='business-dashboard-what-to-track', date='2026-11-06',
  title='What a Business Dashboard Should Show | Key Technologies.si',
  desc='What a small-business dashboard should show for a restaurant, a practice or a firm, how to tell a useful one from a pretty one, and how to start.',
  h1='What a business dashboard should show (and what to leave off)',
  short='A plain guide to what belongs on a small-business dashboard, with examples for restaurants, practices and firms, and how to start.')
G9['faq'] = [
 ('What is a business dashboard?', 'A single screen that pulls numbers from the systems you already use (sales, appointments, reviews, calls) so you can see how the business is doing without opening five different tools.'),
 ('How many numbers should a dashboard show?', 'Fewer than you think. Six to eight numbers you actually act on beat thirty you glance at. If nobody would change a decision because of a number, leave it off.'),
 ('Can a dashboard connect to my point-of-sale or practice software?', 'Often yes, but it depends on the software. Some systems offer a connection, some only let you export a report, and some do neither. Ask the vendor what they support before you plan around it.'),
 ('How often should I look at it?', 'Pick a rhythm and keep it: a quick look each morning for the day ahead, and a longer look weekly for trends. A dashboard nobody opens is just decoration.'),
 ('Where should I start?', 'Write down the three questions you ask most often about the business, such as "how was last night?" or "how many new patients this week?", and build the first screen to answer only those.')]
G9['body'] = f"""<article class="wrap guide">
{crumbs_html([('Home','../index.html'),('Guides','index.html'),('What a business dashboard should show','')])}
<h1>{esc(G9['h1'])}</h1>
<p class="byline">Key Technologies &middot; Published November 6, 2026</p>
<div class="tldr"><b>Short answer:</b> a good dashboard answers the few questions you ask every day, in one glance, using numbers you would actually act on. Start with six to eight, add more only when you miss one.</div>

<h2>What makes a dashboard useful</h2>
<ul>
<li><b>It answers real questions.</b> "Did we have a good night?" or "Are new patients coming in?" Not "what can the software chart?"</li>
<li><b>It compares.</b> A number alone means little. Today against the same day last week, or this week against the one before, tells you whether to worry.</li>
<li><b>It is current and trusted.</b> If the numbers are a week old or often wrong, people stop looking.</li>
<li><b>It fits one screen on a phone.</b> You will mostly check it away from a desk.</li>
</ul>

<h2>Examples of what to track</h2>
<p>These are common starting points, not a rule. Pick what matches how you run things.</p>
<ul>
<li><b>Restaurant:</b> net sales, number of checks, average check, labor as a share of sales, comps and voids, online orders, busiest hours, new reviews.</li>
<li><b>Medical or dental practice:</b> appointments, new patients, no-shows, open slots, patients due for a recall visit, new reviews, missed calls.</li>
<li><b>Chiropractor or specialist clinic:</b> visits, new patients, no-shows, referrals received, follow-ups due.</li>
<li><b>Law firm:</b> new inquiries, consultations booked, how many became clients, follow-ups waiting, response time to a new inquiry.</li>
</ul>

<h2>What to leave off</h2>
<ol>
<li><b>Numbers nobody acts on.</b> If no decision would change, it is clutter.</li>
<li><b>Anything you cannot trust.</b> A wrong number is worse than a missing one.</li>
<li><b>Personal details you do not need.</b> Especially for patients and clients, a dashboard rarely needs names. Counts and trends are enough, and showing less keeps it safer.</li>
</ol>

<h2>Where the numbers come from</h2>
<p>Most dashboards pull from systems you already pay for: a point-of-sale or ordering system, a scheduling or practice-management tool, a review site, a phone system. Whether a given tool can be connected depends on that tool, so ask the vendor what it supports and whether there is a cost. If a system cannot connect, a regular export of its report is often enough to start.</p>

<h2>A sensible way to start</h2>
<p>Write down the three questions you ask most about the business. Build one screen that answers just those, check it for a few weeks against what you already know to be true, and only then add more.</p>

<h2>Where Key Technologies fits</h2>
<p>We build dashboards around the systems you already use, with real connections set up with you and depending on the systems involved. You can try a demo with made-up numbers for a <a href="../key-platform/demos/business-dashboards.html?i=restaurant">restaurant</a>, a <a href="../key-platform/demos/business-dashboards.html?i=dental">dental office</a>, a <a href="../key-platform/demos/business-dashboards.html?i=law">law firm</a> or a <a href="../key-platform/demos/business-dashboards.html?i=chiro">chiropractor</a>. See also our <a href="../restaurants.html">restaurant</a> and <a href="../chiropractors-specialists.html">chiropractor and specialist</a> pages.</p>

{faq_html(G9['faq'])}

<div class="guide-cta"><h2>Want to talk it through?</h2>
<p>Book a free call. Tell us the three questions you ask most about your business and we will tell you honestly what a dashboard for it could look like.</p>
<div class="row"><a class="btn btn-primary" href="../book.html">Book a free call</a><a class="btn btn-ghost" href="../key-platform/demos/business-dashboards.html">Try the dashboard demo</a></div></div>
{more([('AI for restaurants: 6 practical ways to save time','Phones, bookings, reviews, email and social posts, with a demo of each.','ai-for-restaurants.html'),('What is AI/SI? A plain-English guide','What AI and superintelligence mean and how to tell real help from hype.','what-is-ai-si.html')])}
</article>"""
GUIDES['G9'] = G9

# ================= Guide 10: how we work =================
G10 = dict(slug='how-we-work', date='2026-11-06',
  title='How Key Technologies Works With a Business | Key Technologies.si',
  desc='What happens from the first free call to a working system: how Key Technologies starts small, sets permission levels, and keeps you in control.',
  h1='How Key Technologies works with a business, step by step',
  short='What happens from the first free call to a working system, and how you stay in control at every step.')
G10['faq'] = [
 ('Is the first call really free?', 'Yes. The first call is a free, no-obligation conversation about your business and where AI/SI could help. If it is not a fit, we will say so.'),
 ('Do I have to change the software I already use?', 'Not necessarily. We look at what you already use first. Some tools can be connected, some are better left alone, and occasionally replacing one is the better fit. That is worked out with you, not assumed.'),
 ('Who owns my accounts and customer information?', 'You do. Your accounts, customer lists and systems stay in your name. Key Technologies does not host or own them. Doing the work does mean trusting us with real access, the same as hiring any contractor, so we limit access to what a job needs.'),
 ('Will AI act on its own without my approval?', 'Only as much as you allow. Each assistant runs inside permission levels you set: read-only, approval required, or fully on its own. Anything sensitive can wait for a person.'),
 ('Where do we start?', 'With one small, useful piece, such as answering missed calls, following up with new inquiries, or a dashboard for the numbers you check every day. You add more once the first piece is working.')]
G10['body'] = f"""<article class="wrap guide">
{crumbs_html([('Home','../index.html'),('Guides','index.html'),('How we work','')])}
<h1>{esc(G10['h1'])}</h1>
<p class="byline">Key Technologies &middot; Published November 6, 2026</p>
<div class="tldr"><b>Short answer:</b> we start with a free conversation, pick one small useful piece, build it around how your business already works, keep a person in charge of anything important, and only then add more.</div>

<h2>The steps</h2>
<ol>
<li><b>A free call.</b> Thirty minutes about your business: what takes time, where customers or leads slip through, and what you already use. No obligation, and no sales pitch about tools you do not need.</li>
<li><b>A plain-language look at where AI/SI helps and where it does not.</b> Some jobs are a good fit, some should start as a small trial, and some should stay with a person. You get an honest answer, including &ldquo;not yet.&rdquo;</li>
<li><b>One small piece first.</b> Common starting points are answering missed calls and texts, following up with new inquiries, replies to reviews, or a dashboard for the numbers you check every day.</li>
<li><b>Built around your business.</b> We work from how you actually operate, using the systems you already have where that makes sense, instead of fitting you to a generic template.</li>
<li><b>Permission levels you set.</b> Each assistant is read-only, needs your approval, or runs on its own. You decide how much freedom it gets, and anything sensitive can wait for a person.</li>
<li><b>Check it before relying on it.</b> You see what it does on real examples first. AI-made content is labeled wherever a platform or the law asks for it.</li>
<li><b>Add more when it earns its place.</b> Once the first piece works, we add the next one. You can stop at any step.</li>
</ol>

<h2>What stays yours</h2>
<p>Your accounts, customer information and systems stay in your name. Key Technologies does not host or own them. Doing the work means trusting us with real access, the same as hiring any contractor, so access is limited to what each job needs.</p>

<h2>What we will not do</h2>
<ul>
<li>Promise results we cannot show, or invent numbers, clients or reviews.</li>
<li>Recommend a tool just because it is new.</li>
<li>Let an AI send something sensitive without a person approving it, unless you have chosen that.</li>
</ul>

<h2>See it first</h2>
<p>Every service has a live demo with made-up data, so you can see how it behaves before you talk to anyone. Start with the <a href="../key-platform/index.html">demo library</a>, or read our plain-English guides on <a href="what-is-ai-si.html">what AI/SI is</a> and <a href="choose-an-ai-consultant.html">how to choose an AI consultant</a>.</p>

{faq_html(G10['faq'])}

<div class="guide-cta"><h2>Want to talk it through?</h2>
<p>Book a free call. Tell us what takes the most time in your week and we will tell you honestly where AI/SI helps.</p>
<div class="row"><a class="btn btn-primary" href="../book.html">Book a free call</a><a class="btn btn-ghost" href="../key-platform/index.html">Try the demos</a></div></div>
{more([('How to choose an AI consultant: 10 questions to ask','A plain checklist for small-business owners, including the warning signs.','choose-an-ai-consultant.html'),('What a business dashboard should show (and what to leave off)','A plain guide to what belongs on a small-business dashboard, with examples.','business-dashboard-what-to-track.html')])}
</article>"""
GUIDES['G10'] = G10

# ================= Guide 11: AI phone answering for dental and law offices =================
G11 = dict(slug='ai-phone-answering-dental-law', date='2026-11-06',
  title='AI Phone Answering for Dental and Law Offices | Key Technologies.si',
  desc='How AI phone answering works for a dental or law office, what it should and should not do, and what to check before you turn it on.',
  h1='AI phone answering for dental and law offices: what it should and should not do',
  short='How AI phone answering works for a dental or law office, what it should hand to a person, and what to check before turning it on.')
G11['faq'] = [
 ('What can an AI phone assistant do for a dental or law office?', 'Answer when the front desk is busy or the office is closed, give approved information such as hours, location and how to prepare for a visit, collect a name, number and reason for the call, and offer appointment or consultation times for staff to confirm.'),
 ('What should it never do?', 'It should not give medical, dental or legal advice, quote outcomes, handle an emergency on its own, or promise anything on behalf of the office. Those go to a person, and a good assistant says so plainly.'),
 ('Does the caller know it is an AI?', 'They should. Telling callers they are talking to an automated assistant is the honest approach, and in some places rules about recording and automated calls apply. Check the rules where you operate and with your attorney or compliance advisor.'),
 ('Is it safe to let it hear patient or client details?', 'It depends on the tool, its agreement with you, and your obligations. Many useful jobs need only a name, a callback number and a reason for the call. Ask your compliance advisor or attorney before sensitive details go into any new tool.'),
 ('How do I start?', 'Begin with after-hours calls only, give it a short list of approved answers, route anything urgent or sensitive to a person, and review every call it handled for the first few weeks before widening its role.')]
G11['body'] = f"""<article class="wrap guide">
{crumbs_html([('Home','../index.html'),('Guides','index.html'),('AI phone answering for dental and law offices','')])}
<h1>{esc(G11['h1'])}</h1>
<p class="byline">Key Technologies &middot; Published November 6, 2026</p>
<div class="tldr"><b>Short answer:</b> an AI phone assistant is best at the calls nobody can pick up: after hours, at lunch, or while the front desk is with a patient or client. It collects who called and why, answers a short list of approved questions, and hands anything urgent or sensitive to a person.</div>

<h2>Why calls get missed</h2>
<p>In a dental office the front desk is often with a patient. In a law office the attorney is in a meeting or in court. A caller who reaches voicemail often tries the next office on the list, so a missed first call can be a lost new patient or a lost new client. Most practice software tracks appointments and matters after they exist. It does not catch the call that never became one.</p>

<h2>What it can handle</h2>
<ul>
<li><b>After-hours and overflow calls:</b> answer, say it is an automated assistant, and take a message.</li>
<li><b>Approved information:</b> hours, location, parking, what to bring, how to prepare for a visit or a consultation.</li>
<li><b>A clean message:</b> name, callback number and the reason for the call, sent to the right person.</li>
<li><b>Appointment or consultation requests:</b> offer times from a schedule you control, for staff to confirm.</li>
<li><b>Routing:</b> anything urgent goes straight to a person or to emergency instructions.</li>
</ul>

<h2>What it should hand to a person</h2>
<ol>
<li><b>Anything clinical or legal.</b> Symptoms, treatment, medication, case strategy, deadlines and outcomes are for a clinician or an attorney.</li>
<li><b>Emergencies.</b> A caller with a dental or medical emergency should be told to call emergency services, and the office should be alerted.</li>
<li><b>Upset or distressed callers.</b> A person should call back quickly.</li>
<li><b>Billing disputes, consent questions and complaints.</b></li>
<li><b>Anything the assistant is unsure about.</b> Handing off is the correct answer.</li>
</ol>

<h2>Questions to settle before turning it on</h2>
<ol>
<li>Will callers be told clearly that they are speaking to an automated assistant?</li>
<li>Are calls recorded or transcribed, and what do the rules where you operate require?</li>
<li>Where do messages and recordings go, who can see them, and for how long are they kept?</li>
<li>Does the job really need patient or client details, or only a name, a number and a reason?</li>
<li>Who is alerted when something urgent comes in, and how fast?</li>
</ol>
<p>Rules differ by country, state and profession. Check with your compliance advisor or attorney. Nothing here certifies a tool or an office as compliant.</p>

<h2>A sensible way to start</h2>
<p>Begin with after-hours calls only. Give the assistant a short list of approved answers, set clear hand-off rules, and read or listen to every call it handled for the first few weeks. Widen its role only when the results are right.</p>

<h2>Where Key Technologies fits</h2>
<p>We build phone and text answering for dental, medical and law offices around how your office works, with permission levels you set. Hear how it sounds in the <a href="../key-platform/voice.html">AI phone receptionist demo</a> (fictional business, made-up data), or see our <a href="../medical-dental.html">medical and dental page</a> and <a href="../law.html">law firm page</a>.</p>

{faq_html(G11['faq'])}

<div class="guide-cta"><h2>Want to talk it through?</h2>
<p>Book a free call. We will ask how your front desk handles calls today and tell you honestly where an assistant helps and where it does not.</p>
<div class="row"><a class="btn btn-primary" href="../book.html">Book a free call</a><a class="btn btn-ghost" href="../key-platform/voice.html">Try the phone demo</a></div></div>
{more([('AI for medical and dental offices: where it helps and the privacy questions to ask first','Where AI helps a medical or dental office, what staff must still handle, and privacy questions.','ai-for-medical-dental-offices.html'),('AI for law firms: where it helps and what a person must still approve','Where AI helps a law office, what a lawyer must still approve, and confidentiality questions.','ai-for-law-firms.html')])}
</article>"""
GUIDES['G11'] = G11

# ================= Guide 12: restaurant rewards programs =================
G12 = dict(slug='restaurant-rewards-program', date='2026-11-07',
  title='How a Restaurant Rewards Program Works | Key Technologies.si',
  desc='A plain guide to restaurant rewards programs: how points or rewards work, what expiry dates mean, who covers the cost, and what to check before you start.',
  h1='How a restaurant rewards program works, and what to check before you start',
  short='A plain guide to restaurant rewards: how they work, who pays, what expiry dates mean, and the questions to settle first.')
G12['faq'] = [
 ('What is a restaurant rewards program?', 'A way for guests to earn something for coming back, usually points or rewards they can trade for free food. The restaurant decides what a reward is worth, where it can be used and how long it lasts.'),
 ('Who pays for the free food?', 'The restaurant that honors the offer. Before you start, decide how many rewards you are willing to honor and put a cap on it, so you always know the most the program could cost.'),
 ('Should rewards expire?', 'Many programs use an expiry date so rewards do not pile up forever. If you use one, tell guests the date when they earn the rewards and do not shorten it afterward. Rules about expiring rewards differ by place, so check with an attorney.'),
 ('Can rewards be exchanged for cash?', 'Most programs say no: rewards can only be used for free food at the participating restaurants and have no cash value. Keeping them food-only keeps the program simple and avoids stored-value questions.'),
 ('How do you stop people gaming it?', 'Confirm who is really there before rewards are given out, allow one check-in per person per event, and set a cap on what one person can receive. A person on staff approving the guest list is the simplest control.')]
G12['body'] = f"""<article class="wrap guide">
{crumbs_html([('Home','../index.html'),('Guides','index.html'),('How a restaurant rewards program works','')])}
<h1>{esc(G12['h1'])}</h1>
<p class="byline">Key Technologies &middot; Published November 7, 2026</p>
<div class="tldr"><b>Short answer:</b> a rewards program gives guests a reason to return. Decide what a reward can be used for, who covers it, when it expires and how you stop abuse, and write it down in plain terms before the first guest earns anything.</div>

<h2>The pieces of a simple program</h2>
<ul>
<li><b>Earning:</b> how a guest gets rewards, for example by checking in at a guest night or by being thanked for a visit.</li>
<li><b>Using:</b> what the rewards buy. Free food at participating restaurants is the simplest answer.</li>
<li><b>A minimum offer:</b> a smallest reward amount that can be used, so each free offer is worth the restaurant honoring.</li>
<li><b>An expiry date:</b> optional, set when the rewards are issued and shown to the guest.</li>
<li><b>A record:</b> who has how many rewards, when they expire, and what was used.</li>
</ul>

<h2>Sharing a pool at an event</h2>
<p>One easy way to start is a guest night. The restaurant sets aside a pool of rewards. Guests check in, staff confirm who is really there, and the pool is divided equally among confirmed guests, with a cap per person. Whatever is left over is simply not issued.</p>

<h2>What to settle before you start</h2>
<ol>
<li><b>The cost.</b> How many rewards will you honor in total, and per event? Put a ceiling on it.</li>
<li><b>The rules in writing.</b> What rewards can be used for, that they have no cash value, when they expire, and that you can end or change the program.</li>
<li><b>Fairness.</b> How you confirm who is there and prevent a person from claiming twice.</li>
<li><b>Privacy.</b> Collect as little as you need, such as a first name, and say what you keep.</li>
<li><b>The law where you operate.</b> Promotions, loyalty programs and expiry dates are regulated differently by place. Check with an attorney before you launch.</li>
</ol>
<p>Nothing here is legal advice.</p>

<h2>Where Key Technologies fits</h2>
<p>We build rewards systems for restaurants, with guest check-in, staff approval, a dashboard and a message line between you and your guests. You can try a made-up demo in the <a href="../key-platform/demos/key-rewards-events.html">Key Rewards demo</a>. It is a test version until the terms have been reviewed and a restaurant has signed on.</p>

{faq_html(G12['faq'])}

<div class="guide-cta"><h2>Want to talk it through?</h2>
<p>Book a free call. Tell us what you would want a rewards program to do and we will tell you honestly what it would take.</p>
<div class="row"><a class="btn btn-primary" href="../book.html">Book a free call</a><a class="btn btn-ghost" href="../key-platform/demos/key-rewards-events.html">Try the demo</a></div></div>
{more([('AI for restaurants: 6 practical ways to save time','Phones, bookings, reviews, email and social posts, with a demo of each.','ai-for-restaurants.html'),('What a business dashboard should show (and what to leave off)','A plain guide to what belongs on a small-business dashboard.','business-dashboard-what-to-track.html')])}
</article>"""
GUIDES['G12'] = G12

def build():
    os.makedirs(SITE + 'guides', exist_ok=True)
    for g in GUIDES.values():
        path = 'guides/%s.html' % g['slug']
        cn = [("Home", BASE), ("Guides", BASE + 'guides/'), (g['h1'].split(':')[0] if ':' in g['h1'] and len(g['h1']) > 60 else g['h1'], BASE + path)]
        ldg = graph(g['title'], g['desc'], path, g['h1'], g['faq'], cn, g.get('date'))
        open(SITE + path, 'w', encoding='utf-8').write(shell(g['title'], g['desc'], path, g['body'], ldg, cn))
    # retired guides: quiet redirect to the guides hub, not indexed, no sitemap / llms.txt entry
    stub = ('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
            '<meta name="robots" content="noindex,follow"><meta http-equiv="refresh" content="0; url=index.html"><title>Key Technologies.si</title>'
            '<link rel="canonical" href="' + BASE + 'guides/"></head><body style="background:#0f171e;color:#eef4fb;font-family:system-ui,sans-serif;padding:24px">'
            '<p>Taking you to the <a style="color:#00a8e1" href="index.html">guides</a>.</p></body></html>')
    for slug in RETIRED_GUIDES:
        open(SITE + 'guides/%s.html' % slug, 'w', encoding='utf-8').write(stub)
    # hub
    cards = ''.join(f'<a href="{g["slug"]}.html"><b>{esc(g["h1"][0].upper() + g["h1"][1:])}</b><span>{esc(g["short"])}</span></a>' for g in GUIDES.values())
    hub_title = 'Guides on AI and Website Security | Key Technologies.si'
    hub_desc = 'Short, practical guides: what AI/SI means, choosing an AI consultant, AI for law firms and medical offices, PHP2Shell, and AI for restaurants.'
    body = f'''<section class="wrap guide">
{crumbs_html([('Home','../index.html'),('Guides','')])}
<h1>Guides</h1>
<p class="byline">Plain-language help from Key Technologies</p>
<p>Short, practical guides for small-business owners on AI and website security, written without jargon. Each one says what is known, what is not, and what to do next.</p>
<div class="more">{cards}</div>
<div class="guide-cta"><h2>Have a question that is not here?</h2><p>Book a free call and ask. We will tell you honestly what we know.</p><div class="row"><a class="btn btn-primary" href="../book.html">Book a free call</a><a class="btn btn-ghost" href="../key-platform/index.html#library">See the demos</a></div></div>
</section>'''
    items = [{"@type": "ListItem", "position": i + 1, "name": g['h1'], "url": BASE + 'guides/' + g['slug'] + '.html'} for i, g in enumerate(GUIDES.values())]
    ldg = [{"@type": "CollectionPage", "name": "Guides", "description": hub_desc, "url": BASE + 'guides/', "isPartOf": {"@type": "WebSite", "name": "Key Technologies.si", "url": BASE}},
           {"@type": "ItemList", "name": "Key Technologies guides", "itemListElement": items},
           {"@type": "BreadcrumbList", "itemListElement": [{"@type": "ListItem", "position": 1, "name": "Home", "item": BASE}, {"@type": "ListItem", "position": 2, "name": "Guides", "item": BASE + 'guides/'}]}]
    open(SITE + 'guides/index.html', 'w', encoding='utf-8').write(shell(hub_title, hub_desc, 'guides/', body, ldg, []).replace('<meta property="og:type" content="article">', '<meta property="og:type" content="website">'))
    # sitemap
    sm = open(SITE + 'sitemap.xml', encoding='utf-8').read()
    urls = [('guides/', DATE)] + [('guides/%s.html' % g['slug'], g.get('date', DATE)) for g in GUIDES.values()]
    for u, lm in urls:
        loc = BASE + u
        if loc not in sm:
            sm = sm.replace('</urlset>', '  <url>\n    <loc>%s</loc>\n    <lastmod>%s</lastmod>\n    <changefreq>monthly</changefreq>\n    <priority>0.7</priority>\n  </url>\n</urlset>' % (loc, lm))
    for slug in RETIRED_GUIDES:
        sm = re.sub(r'  <url>\s*<loc>%s</loc>.*?</url>\n' % re.escape(BASE + 'guides/%s.html' % slug), '', sm, flags=re.S)
    open(SITE + 'sitemap.xml', 'w', encoding='utf-8').write(sm)
    # llms.txt
    p = SITE + 'llms.txt'
    t = open(p, encoding='utf-8').read()
    if '## Guides' not in t:
        block = '## Guides\n' + '\n'.join(f'- [{g["h1"][0].upper() + g["h1"][1:]}]({BASE}guides/{g["slug"]}.html): {g["short"]}' for g in GUIDES.values()) + '\n\n'
        t = t.replace('## LVR Rewards', block + '## LVR Rewards', 1)
    for g in GUIDES.values():
        url = f'{BASE}guides/{g["slug"]}.html'
        if url not in t:
            line = f'- [{g["h1"][0].upper() + g["h1"][1:]}]({url}): {g["short"]}\n'
            i = t.index('## Guides'); j = t.index('\n\n', i)
            t = t[:j + 1] + line + t[j + 1:]
    open(p, 'w', encoding='utf-8').write(t)
    t = open(p, encoding='utf-8').read()
    for slug in RETIRED_GUIDES:
        t = re.sub(r'- \[[^\]]*\]\(%s\):[^\n]*\n' % re.escape(BASE + 'guides/%s.html' % slug), '', t)
    open(p, 'w', encoding='utf-8').write(t)
    print('guides built:', len(GUIDES) + 1, 'pages')

if __name__ == '__main__':
    build()
