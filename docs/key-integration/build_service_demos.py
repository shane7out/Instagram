#!/usr/bin/env python3
"""Builds one demo page per Key Technologies service into sites/key-technologies/key-platform/demos/.
Run from the repo root: python3 docs/key-integration/build_service_demos.py
Uses the shared site shell (same header, menu, footer and styles as the homepage) and demo-widgets.js."""
import re, os, sys
SITE = 'sites/key-technologies/'
OUT = SITE + 'key-platform/demos/'
idx = open(SITE + 'index.html', encoding='utf-8').read()

def grab(start, end_marker):
    a = idx.index(start); b = idx.index(end_marker, a) + len(end_marker); return idx[a:b]
HEADER = grab('<header>', '</header>')
MENU = grab('<div class="mobile-menu" id="mobileMenu">', '\n</div>\n')
FOOTER = grab('<footer>', '</footer>')

def fix(h, root):
    h = re.sub(r'href="#"', 'href="%sindex.html"' % root, h)
    h = re.sub(r'href="#([a-z-]+)"', lambda m: 'href="%sindex.html#%s"' % (root, m.group(1)), h)
    h = re.sub(r'href="(rewards|my-account|privacy|terms)\.html"', lambda m: 'href="%s%s.html"' % (root, m.group(1)), h)
    # any other root-relative link in the shared header/menu/footer (guides/, las-vegas.html, ...) must also climb to the site root
    h = re.sub(r'href="(?!https?:|mailto:|tel:|#|/|\.\./|%s)([A-Za-z0-9_-][^"]*)"' % re.escape(root), lambda m: 'href="%s%s"' % (root, m.group(1)), h)
    h = h.replace('href="key-platform/', 'href="%skey-platform/' % root)
    h = h.replace('href="book.html"', 'href="%sbook.html"' % root)
    return h.replace('<span id="year"></span>', '<span id="kpYear"></span>')

# reuse the menu/toast script already present in the hub page (key-platform/index.html)
_hub = open(SITE + 'key-platform/index.html', encoding='utf-8').read()
_a = _hub.index('<script>(function(){var b=document.getElementById("burgerBtn")')
BURGER = _hub[_a:_hub.index('</script>', _a) + 9]

# slug, number, title, tagline, widget, heading, how-to, bullets, section anchor on main page
S = [
 ('content-creators', '01', 'Digital Content Creators', 'AI/SI creators with a consistent brand voice that make posts around the clock.', 'content', 'Make a post for a fictional bakery', 'Pick a voice and a post type, then decide how much freedom the creator has.', ['A creator built around your brand, products and tone', 'Posts, captions, graphics and short video on a schedule', 'You choose: publish on its own, or wait for your approval', 'AI-made content is labeled wherever a platform or the law asks']),
 ('ai-strategy', '02', 'AI/SI Strategy', 'Find where AI/SI pays off, and where it can not yet.', 'fit', 'Where would AI/SI help most?', 'Tick the tasks your business does and set the hours. The table sorts them into good fit, pilot first, or keep with a person.', ['A plain-language review of how your business actually works', 'A ranked list of where AI/SI helps and where it does not', 'Effort goes where it pays off, not where it sounds exciting']),
 ('business-automation', '03', 'Business Automation', 'Connect steps that run by hand today so they run on their own.', 'workflow', 'Build and run a workflow', 'Choose a trigger and the steps that should follow. Try making a step fail to see how it is handled.', ['Workflows that run on their own schedule and triggers', 'Failed steps are retried, then handed to a person with the details', 'Built to work in the background, not when someone remembers']),
 ('ai-agents', '04', 'AI/SI Agents', 'Assistants that do defined tasks, with limits you set.', 'agent', 'Watch an agent do a task', 'Pick a role. See what it is allowed to do, then approve or reject its work.', ['Built around a specific job, not a generic chatbot', 'Clear permissions: what it may and may not do', 'A person approves anything that goes out']),
 ('custom-crm', '05', 'Custom CRM & Lead Management', 'A CRM built around your business, not stretched to fit.', 'crm', 'Try a small pipeline', 'Move leads through stages, filter them, and add your own.', ['Capture, qualify, organize and follow up with leads', 'Your own stages, fields and reports', 'Connects to your website forms and your phone and email tools']),
 ('customer-experience', '06', 'Customer Experience', 'Faster replies that still sound like a person wrote them.', 'cx', 'Reply to a customer', 'Use the samples or type a message. Compare a generic automated reply with a personal one. Angry messages go straight to a person.', ['Quick, personal replies using the customer\'s details', 'Upset customers are escalated to a human right away', 'A person can review before anything is sent']),
 ('operations', '07', 'Operations', 'Find the slow steps and what automating them would give back.', 'ops', 'Where does the time go?', 'Edit the minutes per step and how many quotes you handle a week. Mark what could be automated.', ['A look at the real workflow, step by step', 'The biggest time drain, in numbers', 'Automation only where it moves the needle']),
 ('data-knowledge', '08', 'Data & Knowledge Systems', 'Make what your business knows easy to find and use.', 'knowledge', 'Ask your own documents', 'Ask a question. The answer comes only from the sample documents, with its source. If it is not there, it says so.', ['Search across the tools and files you already have', 'Answers show their source', 'No guessing when the information is missing']),
 ('marketing', '09', 'Marketing', 'Segments, research and content, with a person approving the message.', 'segments', 'Find a customer segment', 'Move the sliders to find lapsed or loyal customers and see a campaign idea.', ['Customer segments from your own data', 'Campaign ideas and content production', 'AI-made images and short video are labeled as such']),
 ('security-technology', '10', 'Security & Technology', 'Check access before an AI tool touches your systems.', 'permissions', 'Review who can reach what', 'Change who has access, two-step sign-in and shared passwords. See which systems are ready for an AI tool.', ['A review of networks, databases and permissions', 'Fix access first, then connect AI tools', 'Every automated action is logged and limited']),
 ('custom-ai-systems', '11', 'Custom AI/SI Systems', 'Systems built around how your business operates.', 'brief', 'Describe the business, see a proposed system', 'Pick your biggest problems and where your information lives.', ['Built for your workflow, not a one-size-fits-all package', 'A clear plan in phases', 'We also say what we would not automate']),
 ('website-development', '12', 'AI/SI Website Development', 'Websites with chat, personalization and lead capture built in.', 'site', 'A site with a built-in assistant', 'Ask the florist site a question and toggle personalization.', ['Websites built and maintained with AI/SI-assisted development', 'On-site chat, personalization and smart lead capture', 'Your hosting, domain and data stay in your name']),
 ('social-media', '14', 'Social Media Management', 'A real presence on a schedule, with review before anything goes live.', 'social', 'Approve a week of posts', 'Pick a post, approve it, then schedule it.', ['Automated, consistent posting', 'Posts drafted fast, reviewed by a person before going live', 'Content management that tracks what is posted, scheduled and performing']),
 ('reviews-reputation', '15', 'Review & Reputation Management', 'Answer reviews quickly and flag negative ones early.', 'reviews', 'Handle new reviews', 'Draft a reply, edit it, and approve. Negative reviews are flagged for the owner first.', ['Google, Yelp and other reviews watched in one place', 'Drafted replies in your voice', 'Negative reviews flagged before they sit unanswered']),
 ('booking-scheduling', '17', 'Booking & Scheduling Automation', 'Booking, confirmations and reminders without staff time.', 'booking', 'Book a sample appointment', 'Pick a day and time, then book. See the reminders that would go out.', ['Online booking and reservations', 'Confirmations and reminders sent for you', 'Times confirmed against your calendar before a customer is told']),
 ('ai-training', '18', 'AI/SI Training & Custom Training Software', 'Teach your team to use AI/SI well, in your own portal.', 'training', 'Take a short course', 'Read each lesson and answer the check question.', ['Training built around how your business already works', 'Your own portal with progress and completion', 'Not a generic off-the-shelf course']),
 ('custom-programming', '19', 'Custom Website Programming', 'Full custom-coded sites and web applications.', 'webapp', 'A custom quote tool', 'Change the inputs and watch the price follow your rules.', ['Custom logic a template can not do', 'Built and maintained by someone with 42+ years of experience with computers and software', 'Your pricing rules, forms and workflows']),
 ('accessibility-ada', '20', 'ADA & Accessibility Compliance', 'Make a site usable for everyone and reduce legal risk.', 'a11y', 'Fix a sample page', 'Turn on each fix and watch the sample page and score change.', ['Websites built and audited to ADA and WCAG standards', 'A source of legal exposure reduced', 'Usable for every visitor, not just some']),
 ('php-wordpress-migration', '21', 'PHP & WordPress Migration', 'Move off PHP and WordPress to a modern custom stack.', 'migration', 'Plan a migration', 'Describe the current site to see a plan and an example redirect map.', ['For sites flagged by our free audit, or anyone who wants out', 'Redirects so search rankings are kept', 'Tested, with a rollback ready']),
 ('private-llm', '22', 'Private LLM Setup', 'Your own private AI that knows your business and keeps it private.', 'privatellm', 'Ask the private assistant', 'Sign in as staff or as the owner and ask about a document.', ['Loaded with your own documents and records', 'Isolated, never used to train anyone else\'s model', 'Managed by us with login access, or handed to you']),
 ('cybersecurity', '23', 'Cybersecurity & Network Hardening', 'A full security pass that closes real gaps.', 'hardening', 'Run an example check', 'Run the check on a fictional office and read the fix plan.', ['Passwords, access, networks, backups and exposed systems', 'Findings explained in plain language', 'Backed by a decade of hands-on security experience']),
 ('rewards', 'P', 'LVR Rewards', 'Earn rewards at restaurants and use them for food.', 'points', 'Try the rewards program', 'Earn from a receipt, take the free spin, use rewards, and see the monthly rewards share.', ['Earn 1 reward per $1 on checked receipts', 'A free spin that comes and goes', 'Rewards used only for food at participating restaurants']),
]
EXISTING = {'13': ('Email Automation', '../email/index.html', 'Sorts the inbox and drafts replies that a person approves.'), '16': ('AI/SI Phone & Text Answering', '../voice/index.html', 'An AI receptionist that answers calls and captures leads.')}  # '24' Sales Partner Network demo taken down at Shane's request (2026-11-05)

def switch():
    items = [('Overview', '../index.html'), ('Voice Services', '../voice/index.html'), ('Email Intelligence', '../email/index.html'), ('All demos', '../index.html#library')]
    return '<nav class="kp-switch" aria-label="KEY Platform demos"><span class="lbl">KEY Platform</span>' + ''.join('<a href="%s">%s</a>' % (h, t) for t, h in items) + '</nav>'

def page(i, s):
    slug, num, title, tag, widget, head, how, bullets = s
    prev = S[i - 1] if i > 0 else None
    nxt = S[i + 1] if i < len(S) - 1 else None
    nav = '<div class="demo-strip" style="margin-top:26px">'
    nav += ('<a href="%s.html">&larr; %s</a>' % (prev[0], prev[2])) if prev else '<span></span>'
    nav += ('<a href="%s.html">%s &rarr;</a>' % (nxt[0], nxt[2])) if nxt else '<a href="../index.html#library">All demos &rarr;</a>'
    nav += '</div>'
    label = 'Service %s' % num if num != 'P' else 'LVR Rewards'
    cta = '<a class="btn btn-primary" href="../../index.html#contact">Talk to us about this</a>' if num != 'P' else '<a class="btn btn-primary" href="../../rewards.html">Join LVR Rewards</a>'
    ghost = '<a class="btn btn-ghost" href="../../index.html#services">See all services</a>' if num != 'P' else '<a class="btn btn-ghost" href="../index.html#library">All demos</a>'
    body = '''<section class="page active" style="display:block;padding-top:6px">
<a class="kp-back" href="../index.html#library">&larr; All demos</a>
<div class="hero"><span class="eyebrow">%s &middot; Demo</span><h1 style="margin-top:10px">%s</h1><p>%s</p></div>
<div class="sectionhead"><div><span class="eyebrow">Try it</span><h2>%s</h2></div></div>
<p class="lead">%s</p>
<div id="widget"></div>
<div class="two-columns" style="margin-top:22px"><div class="panel"><h3>What you get</h3><ul style="margin:10px 0 0;padding-left:18px">%s</ul></div>
<div class="panel"><h3>About this demo</h3><p>Everything here is fictional sample data that runs in your browser. Nothing is sent, posted, booked or charged, and nothing is connected to a real system. A real project starts with your own information and a review of what is safe to automate.</p><div class="action-row">%s%s</div></div></div>
%s</section>''' % (label, esc(title), esc(tag), esc(head), esc(how), ''.join('<li>%s</li>' % esc(b) for b in bullets), cta, ghost, nav)
    root = '../../'
    return '''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex">
<title>%s demo | Key Technologies.si</title><meta name="description" content="%s"><meta name="theme-color" content="#0f171e">
<link rel="icon" href="%sapple-touch-icon.png"><link rel="apple-touch-icon" href="%sapple-touch-icon.png">
<link rel="stylesheet" href="/fonts/lato.css">
<link rel="stylesheet" href="../site-base.css"><link rel="stylesheet" href="../kp.css"></head><body>
%s
%s
<div class="launch-banner" role="region" aria-label="Demo notice"><p><span class="launch-tag">Demo</span>Every business, person, message and number here is fictional. Nothing is sent, booked, charged or paid.</p></div>
<main id="main" class="wrap kp-main">
%s
%s
</main>
%s
<div id="toast" role="status" aria-live="polite"></div>
%s
<script src="../kp-sound.js" defer></script><script src="../kp-tour.js"></script><script src="../lead-send.js"></script><script src="../kp-followup.js"></script><script src="../demo-widgets.js"></script><script>KPD.mount(%r,document.getElementById("widget"));</script>
</body></html>''' % (esc(title), esc(tag), '../../', '../../', fix(HEADER, root), fix(MENU, root), switch(), body, fix(FOOTER, root), BURGER, widget)

def esc(t):
    return t.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;')

os.makedirs(OUT, exist_ok=True)
for i, s in enumerate(S):
    open(OUT + s[0] + '.html', 'w', encoding='utf-8').write(page(i, s))
print('wrote', len(S), 'pages')

# machine-readable list for the hub and the homepage
import json
CAT = {'01': 'Marketing & Content', '09': 'Marketing & Content', '14': 'Marketing & Content',
       '13': 'Customers & Communication', '16': 'Customers & Communication', '06': 'Customers & Communication', '15': 'Customers & Communication', '17': 'Customers & Communication',
       '02': 'AI Systems & Strategy', '04': 'AI Systems & Strategy', '08': 'AI Systems & Strategy', '11': 'AI Systems & Strategy', '22': 'AI Systems & Strategy',
       '03': 'Operations & Sales', '05': 'Operations & Sales', '07': 'Operations & Sales',
       '10': 'Websites & Security', '12': 'Websites & Security', '19': 'Websites & Security', '20': 'Websites & Security', '21': 'Websites & Security', '23': 'Websites & Security',
       '18': 'Training & Rewards', 'P': 'Training & Rewards'}
lst = [{'slug': s[0], 'num': s[1], 'title': s[2], 'tag': s[3], 'cat': CAT[s[1]], 'thumb': 'demos/thumbs/%s.jpg' % s[0], 'href': 'demos/%s.html' % s[0]} for s in S]
for n, (t, h, tg) in EXISTING.items():
    lst.append({'slug': h, 'num': n, 'title': t, 'tag': tg, 'cat': CAT[n], 'thumb': 'demos/thumbs/%s.jpg' % h.replace('../', '').split('/')[0], 'href': h.replace('../', '')})
lst.sort(key=lambda x: (x['num'] == 'P', int(x['num']) if x['num'].isdigit() else 99))
json.dump(lst, open(SITE + 'key-platform/demos/list.json', 'w'), indent=1)

# keep the indexable demos indexable after a rebuild
import sys as _s, os as _o
_s.path.insert(0, _o.path.dirname(_o.path.abspath(__file__)))
import apply_demo_seo
apply_demo_seo.run()
