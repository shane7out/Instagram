#!/usr/bin/env python3
"""Makes the best demos findable on Google: removes noindex, sets title/description/canonical/share tags and structured data,
and adds a short plain-language "how it works" block with questions and answers (the visible text matches the structured data).
Idempotent: safe to re-run. build_service_demos.py calls run() at the end, so rebuilt pages keep this.
Run from the repo root:  python3 docs/key-integration/apply_demo_seo.py"""
import re, json, os
SITE = 'sites/key-technologies/'
BASE = 'https://keytechnologies.si/'
H_START, H_END = '<!--demo-seo-head-->', '<!--/demo-seo-head-->'
B_START, B_END = '<!--demo-seo-body-->', '<!--/demo-seo-body-->'

# file, canonical path, title, description, service name, steps, before-live notes, FAQ
SEO = {
 'voice': dict(
  file='key-platform/voice/index.html', path='key-platform/voice/',
  title='AI Receptionist Demo: How AI Phone Answering Works | Key Technologies.si',
  desc='Try an interactive demo of an AI phone receptionist: it answers common questions, captures leads, sends urgent calls to a person and proposes appointments. Made-up business, nothing connected.',
  name='AI phone receptionist',
  h2='How an AI receptionist works',
  steps=['A call comes in on your business number, or on a line that forwards to the system.',
         'The assistant says it is an AI, greets the caller and answers common questions from information you approved, such as hours, services and location.',
         'It collects the caller\'s name, number and reason for calling, and can propose an appointment time.',
         'Anything urgent, unclear or sensitive is sent to a real person, and a summary lands in your inbox or CRM.'],
  before='Before a system like this goes live there are real decisions to make: how callers are told they are talking to an AI, whether and how calls are recorded (the rules differ by state), what your assistant may and may not say, which phone provider to use, and what a human handoff looks like after hours. Costs depend on your call volume and the provider, so they are set after we understand your business.',
  faq=[('Can an AI receptionist book appointments?','It can propose times and, once it is connected to your calendar, hold a slot. In this demo nothing is booked and nothing is connected to a real calendar.'),
       ('Does it replace my staff?','No. It handles common questions and calls you would otherwise miss, and hands anything urgent or complicated to a person.'),
       ('Is this a real phone line?','No. This is a scripted demo with a made-up business. You can play a sample call or type your own question.')]),
 'email': dict(
  file='key-platform/email/index.html', path='key-platform/email/',
  title='AI Email Assistant Demo: Sorted Inbox and Draft Replies | Key Technologies.si',
  desc='Try an interactive demo of an AI email assistant that sorts a business inbox and drafts replies from approved information, with a person approving before anything is sent. Fictional emails only.',
  name='AI email assistant',
  h2='How an AI email assistant works',
  steps=['It connects to your mailbox with read-only permission first, so it can sort and label but not send.',
         'New messages are sorted by type, such as new lead, billing question or support, and flagged when they look urgent or risky.',
         'For routine messages it drafts a reply using only information you approved, such as your hours, services and policies, and shows what the draft is based on.',
         'A person reads, edits and approves the draft. Nothing goes out on its own unless you deliberately switch on a narrow, tested automation.'],
  before='Before connecting a real mailbox we agree what the assistant may use, which messages must always go to a person (refunds, disputes, legal, medical and anything sensitive), how approvals are logged, and how access can be turned off. Emails are treated as untrusted input, so instructions hidden inside a message are never followed.',
  faq=[('Will the assistant send emails by itself?','Not by default. A person approves each reply. Fully automatic replies are only for narrow cases you choose and test.'),
       ('What happens to angry or sensitive emails?','They are flagged and sent to a person. The assistant does not argue with an upset customer or give advice in regulated areas.'),
       ('Is this connected to a real inbox?','No. The demo uses made-up emails in your browser and sends nothing.')]),
 'reviews-reputation': dict(
  file='key-platform/demos/reviews-reputation.html', path='key-platform/demos/reviews-reputation.html',
  title='Online Review Management Demo: Reply to Google and Yelp Reviews | Key Technologies.si',
  desc='Try a demo of review and reputation management: new reviews in one place, drafted replies in your voice, and negative reviews flagged for the owner first. Sample data only.',
  name='Review and reputation management',
  h2='How review management works',
  steps=['New reviews from places like Google and Yelp are collected in one list.',
         'Each review gets a drafted reply in your voice, which you can edit.',
         'Low ratings are flagged so the owner sees them before anyone replies.',
         'You approve each reply. Replies are posted by you or with your approval, never by a script acting alone.'],
  before='A good process answers every review quickly and politely. It does not write fake reviews, offer rewards for positive ones or hide negative ones, because the review sites forbid that and customers notice.',
  faq=[('Do you write reviews for me?','No. We help you answer the reviews you receive, and make it easier to ask real customers for feedback. We do not write or buy reviews.'),
       ('Who approves the replies?','You do. Negative reviews are flagged for the owner first.'),
       ('Is this connected to Google or Yelp?','No. The demo uses made-up reviews and posts nothing.')]),
 'booking-scheduling': dict(
  file='key-platform/demos/booking-scheduling.html', path='key-platform/demos/booking-scheduling.html',
  title='Online Booking and Appointment Reminder Demo | Key Technologies.si',
  desc='Try a demo of online booking and scheduling automation: pick a day and time, get a confirmation, and see the reminders that go out. Sample business, nothing booked.',
  name='Booking and scheduling automation',
  h2='How booking automation works',
  steps=['The customer picks a service, a day and an open time on your website.',
         'The system checks your real calendar before telling them the time is booked.',
         'Confirmations and reminders go out by email or text on the schedule you choose.',
         'Customers can cancel or move a booking, and the time opens up again for someone else.'],
  before='Texts and emails need the customer\'s permission, and the system should never promise a time until your calendar confirms it. We set the rules for cancellations, double-booking and reminders with you first.',
  faq=[('Can customers book at any hour?','Yes, once it is connected to your calendar the booking page works around the clock, within the hours you allow.'),
       ('Does it double-book?','It checks your calendar before confirming, which is what prevents double-booking.'),
       ('Did this demo book anything?','No. Nothing here is booked, sent or saved anywhere.')]),
 'custom-crm': dict(
  file='key-platform/demos/custom-crm.html', path='key-platform/demos/custom-crm.html',
  title='Custom CRM and Lead Management Demo for Small Business | Key Technologies.si',
  desc='Try a small-business CRM demo: leads move through your stages, follow-ups are tracked and sources are recorded. Built around how your business actually sells. Sample data only.',
  name='Custom CRM and lead management',
  h2='How a custom CRM works',
  steps=['Leads from your website forms, calls and referrals land in one place with their source.',
         'Each lead moves through stages that match how you actually sell, with a follow-up date so nothing slips.',
         'You see what is new, what is waiting on you and what has gone quiet.',
         'Simple reports show where leads come from and how many become customers.'],
  before='A CRM is only useful if people use it, so we start from your real process, keep the fields few, and connect it to the places leads already arrive. Your data stays yours and can be exported.',
  faq=[('Why a custom CRM instead of a big off-the-shelf one?','Off-the-shelf tools are built for everyone. A custom one fits your stages, your fields and your reports, and stays simple.'),
       ('Can it connect to my website and phone?','Yes. Website forms, calls and email can feed it, once those are set up for your business.'),
       ('Is the data in this demo real?','No. It is made up and stays in your browser.')]),
 'content-creators': dict(
  file='key-platform/demos/content-creators.html', path='key-platform/demos/content-creators.html',
  title='AI Social Media Content Creator Demo for Small Business | Key Technologies.si',
  desc='Try a demo of an AI content creator built around one brand: pick a voice and a topic, get a draft post and image idea, and choose whether it waits for your approval. Fictional bakery.',
  name='Digital content creators',
  h2='How a digital content creator works',
  steps=['We build the creator around your brand: your products, your tone and your look.',
         'It drafts posts, captions and image or short-video ideas on a schedule.',
         'You choose how much freedom it has: wait for your approval, or publish on its own with you reviewing afterward.',
         'A content system tracks what was made, what is scheduled and what is performing.'],
  before='AI-made content should be labeled wherever a platform or the law asks for it, and a person should review anything that matters before it goes live. The goal is steady, on-brand posting, not a flood of generic content.',
  faq=[('Will it post without my approval?','Only if you choose that. The safer default is that every post waits for your approval.'),
       ('Does it sound like my business?','It is set up around your voice and products, and you can edit anything before it goes out.'),
       ('Did this demo post anything?','No. It uses a made-up bakery and nothing is posted anywhere.')]),
}

from demo_seo_more import MORE
SEO.update(MORE)

# Shorter titles and descriptions so search results do not truncate them (title main part + " | Key Technologies.si" <= ~70 chars; description <= ~155)
SEO_OVERRIDES = {'voice': ('AI Phone Receptionist Demo', 'Try a demo AI phone receptionist: it answers common questions, captures leads and sends urgent calls to a person. Made-up business, nothing connected.'), 'email': ('AI Email Assistant Demo', 'Try a demo AI email assistant that sorts a business inbox and drafts replies a person approves. Fictional emails only, nothing is sent.'), 'reviews-reputation': ('Review Management Demo', 'Try review management: reviews in one place, drafted replies in your voice, and bad reviews flagged for the owner first. Sample data only.'), 'booking-scheduling': ('Online Booking and Reminders Demo', 'Try online booking and reminders: pick a day and time, get a confirmation and see the reminders. Sample business, nothing is booked.'), 'custom-crm': ('Custom CRM and Lead Tracking Demo', 'Try a small-business CRM: leads move through your stages, follow-ups are tracked and sources recorded. Sample data only.'), 'content-creators': ('AI Content Creator Demo', 'Try an AI content creator built around one brand: choose a voice and topic, get a draft post, and decide if it waits for approval. Fictional bakery.'), 'ai-strategy': ('AI Strategy for Small Business', 'Sort sample business tasks into good fits for AI, tasks to pilot first and work to keep with a person. Sample data, honest about the limits of AI.'), 'business-automation': ('Business Process Automation Demo', 'Build and run a sample workflow: a trigger starts a chain of steps, and failed steps are retried, then handed to a person. Made-up data.'), 'ai-agents': ('AI Agents for Business Demo', 'Watch a sample AI agent do one defined job, see its limits, and approve or reject its work. A person stays in control. Fictional data.'), 'customer-experience': ('Customer Service Automation Demo', 'Compare a generic automated reply with a personal one drafted from customer details, and see angry messages go to a person. Sample messages.'), 'operations': ('Business Operations Review Demo', 'Enter the steps of a work process and see where the time goes and what automating could give back. The estimates are yours to adjust.'), 'data-knowledge': ('AI Knowledge Search Demo', 'Ask a question and get an answer from sample business documents, with the source shown. If it is not in the documents, it says so.'), 'marketing': ('AI Marketing for Small Business', 'Sort a sample customer list into segments like lapsed or loyal and get a campaign idea for each. A person approves every message. Fictional customers.'), 'security-technology': ('AI and Business Security Review', 'Review who can reach which business systems, flag weak spots like shared passwords, and see which are ready for AI tools. Sample data.'), 'custom-ai-systems': ('Custom AI Systems Demo', 'Describe your business and see an example AI system proposed in phases, including what we would not automate. Example plan only.'), 'website-development': ('AI-Assisted Website Development', 'See a sample website with a built-in assistant that answers questions, greets returning visitors and captures leads. Your site stays yours.'), 'social-media': ('Social Media Management Demo', "Try a sample content calendar: draft the week's posts, approve them and schedule them. Nothing goes live without approval, and nothing is published."), 'ai-training': ('AI Training for Your Team', 'Take a short sample course on using AI safely at work, with lessons and check questions. Training built around how your business works.'), 'custom-programming': ('Custom Web Application Development', "See a custom quote tool that follows a business's own pricing rules, which a template cannot do. Custom websites and web apps, built and maintained."), 'accessibility-ada': ('ADA Website Accessibility Demo', 'Fix a sample web page one problem at a time and watch the accessibility score change: image descriptions, contrast, labels. Not legal advice.'), 'php-wordpress-migration': ('WordPress and PHP Migration Demo', 'Describe your current site and see an example migration plan: phases, a rough timeline and a redirect map that protects search rankings.'), 'private-llm': ('Private AI Assistant (Private LLM)', 'See a private AI assistant that answers only from your documents and shows each person only what they may see. Your data stays isolated.'), 'cybersecurity': ('Small Business Cybersecurity Demo', 'Run a sample security check on a fictional office and read the plain-language fix plan: passwords, backups, updates and exposed systems.'), 'rewards': ('LVR Rewards Demo', 'Try LVR Rewards: earn 1 reward per $1 on checked receipts, take the free spin when it is on, and use rewards for food. Sample data only.')}
for _k, (_t, _d) in SEO_OVERRIDES.items():
    if _k in SEO:
        SEO[_k]["title"] = _t + " | Key Technologies.si"; SEO[_k]["desc"] = _d

HUB = dict(
 file='key-platform/index.html', path='key-platform/',
 title='Interactive Demos for Every Service | Key Technologies.si',
 desc='Try interactive demos of AI business tools: phone answering, email, reviews, booking, CRM and more. Each uses made-up data, so nothing is connected.')

def esc(t): return t.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;')

def head_block(path, title, desc, extra_graph):
    url = BASE + path
    graph = [{"@type": "WebPage", "name": title.split(' | ')[0], "description": desc, "url": url,
              "isPartOf": {"@type": "WebSite", "name": "Key Technologies.si", "url": BASE}}]
    graph += extra_graph
    crumbs = [("Home", BASE), ("Demos", BASE + 'key-platform/')]
    if path != 'key-platform/': crumbs.append((title.split(' | ')[0], url))
    graph.append({"@type": "BreadcrumbList", "itemListElement": [{"@type": "ListItem", "position": i + 1, "name": n, "item": u} for i, (n, u) in enumerate(crumbs)]})
    ld = json.dumps({"@context": "https://schema.org", "@graph": graph}, ensure_ascii=False)
    return (H_START + '\n<link rel="canonical" href="%s">\n<meta property="og:type" content="website"><meta property="og:title" content="%s"><meta property="og:description" content="%s"><meta property="og:url" content="%s"><meta property="og:image" content="%sog-image.png"><meta name="twitter:card" content="summary_large_image">\n<script type="application/ld+json">%s</script>\n' % (url, esc(title), esc(desc), url, BASE, ld) + H_END)

def body_block(cfg):
    steps = ''.join('<li>%s</li>' % esc(x) for x in cfg['steps'])
    faq = ''.join('<h3 style="margin-top:14px">%s</h3><p>%s</p>' % (esc(q), esc(a)) for q, a in cfg['faq'])
    return (B_START + '\n<section class="kp-seo panel" style="margin-top:22px" aria-labelledby="seoh"><h2 id="seoh" style="font-size:clamp(22px,3.2vw,28px)">%s</h2><ol style="margin:12px 0 0;padding-left:20px;display:grid;gap:6px">%s</ol>'
            '<h3 style="margin-top:18px">Before it goes live</h3><p>%s</p><h3 style="margin-top:18px;font-size:20px">Common questions</h3>%s'
            '<p class="small muted" style="margin-top:16px">This page is a demo with made-up data. <a href="../../book.html">Book a free call</a> to talk about your own business.</p></section>\n' % (esc(cfg['h2']), steps, esc(cfg['before']), faq) + B_END)

def strip(t):
    t = re.sub(re.escape(H_START) + '.*?' + re.escape(H_END) + r'\n?', '', t, flags=re.S)
    t = re.sub(re.escape(B_START) + '.*?' + re.escape(B_END) + r'\n?', '', t, flags=re.S)
    return t

def set_title_desc(t, title, desc):
    t = re.sub(r'<title>.*?</title>', '<title>%s</title>' % esc(title), t, count=1, flags=re.S)
    if re.search(r'<meta name="description"', t): t = re.sub(r'<meta name="description" content="[^"]*">', '<meta name="description" content="%s">' % esc(desc), t, count=1)
    else: t = t.replace('</title>', '</title><meta name="description" content="%s">' % esc(desc), 1)
    return t.replace('<meta name="robots" content="noindex">', '')

def run():
    for key, cfg in SEO.items():
        f = SITE + cfg['file']
        if not os.path.exists(f): continue
        t = strip(open(f, encoding='utf-8').read())
        t = set_title_desc(t, cfg['title'], cfg['desc'])
        faq_ld = {"@type": "FAQPage", "mainEntity": [{"@type": "Question", "name": q, "acceptedAnswer": {"@type": "Answer", "text": a}} for q, a in cfg['faq']]}
        svc = {"@type": "Service", "name": cfg['name'], "provider": {"@type": "ProfessionalService", "name": "Key Technologies", "url": BASE}, "description": cfg['desc']}
        t = t.replace('</head>', head_block(cfg['path'], cfg['title'], cfg['desc'], [svc, faq_ld]) + '\n</head>', 1)
        block = body_block(cfg)
        if '<div class="kp-foot-note">' in t: t = t.replace('<div class="kp-foot-note">', block + '<div class="kp-foot-note">', 1)
        else: t = t.replace('<div class="demo-strip" style="margin-top:26px">', block + '<div class="demo-strip" style="margin-top:26px">', 1)
        if 'href="../../book.html"' in block and '/demos/' not in cfg['file']:
            pass
        open(f, 'w', encoding='utf-8').write(t)
    # hub
    f = SITE + HUB['file']; t = strip(open(f, encoding='utf-8').read()); t = set_title_desc(t, HUB['title'], HUB['desc'])
    lst = json.load(open(SITE + 'key-platform/demos/list.json'))
    items = [{"@type": "ListItem", "position": i + 1, "name": x['title'], "url": BASE + 'key-platform/' + x['href']} for i, x in enumerate(lst)]
    t = t.replace('</head>', head_block(HUB['path'], HUB['title'], HUB['desc'], [{"@type": "ItemList", "name": "Key Technologies demos", "itemListElement": items}]) + '\n</head>', 1)
    # crawlable list inside the gallery placeholder (JS replaces it on load)
    li = ''.join('<li><a href="%s">%s</a></li>' % (esc(x['href']), esc(x['title'])) for x in lst)
    t = re.sub(r'(<div class="demo-gallery" id="libgrid" aria-live="polite">).*?(</div>)', lambda m: m.group(1) + '<ul>' + li + '</ul>' + m.group(2), t, count=1, flags=re.S)
    open(f, 'w', encoding='utf-8').write(t)
    # sitemap
    sm = open(SITE + 'sitemap.xml', encoding='utf-8').read()
    urls = [HUB['path']] + [c['path'] for c in SEO.values()]
    for u in urls:
        loc = BASE + u
        if loc not in sm:
            sm = sm.replace('</urlset>', '  <url>\n    <loc>%s</loc>\n    <changefreq>monthly</changefreq>\n    <priority>0.6</priority>\n  </url>\n</urlset>' % loc)
    open(SITE + 'sitemap.xml', 'w', encoding='utf-8').write(sm)
    print('seo applied to', len(SEO) + 1, 'pages')

if __name__ == '__main__':
    run()
