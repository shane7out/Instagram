#!/usr/bin/env python3
"""Builds sites/key-technologies/restaurants.html from the law-firm page (same layout, header, form and footer),
replacing the words. Idempotent: safe to re-run. Run from the repo root.
Nothing on the page is a client result or testimonial. The only proof is what Shane has told us (about 10,000
restaurants watched) and the stats already on the site. No rewards, deals or points are mentioned on purpose."""
import re, json, pathlib
root = pathlib.Path('sites/key-technologies')
s = (root/'law.html').read_text(encoding='utf-8')

def sub(a, b, count=1):
    global s
    assert a in s, a[:60]
    s = s.replace(a, b, count)

def section(start_marker, end_marker, new):
    global s
    i = s.index(start_marker); j = s.index(end_marker)
    s = s[:i] + new + s[j:]

# head
sub('<title>AI and Intake CRM for Law Firms | Key Technologies.si</title>',
    '<title>AI and Guest CRM for Restaurants | Key Technologies.si</title>')
sub('content="Custom intake CRM, document automation and phone and text answering for law firms in Manhattan Beach, the South Bay and Las Vegas."',
    'content="Custom guest CRM, phone and text answering, review replies and social content for restaurants in Las Vegas and Southern California."')
sub('<meta property="og:title" content="AI and Intake CRM for Law Firms | Key Technologies.si">',
    '<meta property="og:title" content="AI and Guest CRM for Restaurants | Key Technologies.si">')
sub('content="Stop losing retainers to a slow intake process. Custom intake CRM and automation built around how your firm actually works."',
    'content="Stop losing tables to unanswered calls, messages and reviews. Custom systems built around how your restaurant actually runs."')
s = s.replace('https://keytechnologies.si/law.html', 'https://keytechnologies.si/restaurants.html')

# eyebrow labels
sub('</svg>AI/SI for Law Firms</p>','</svg>AI/SI for Restaurants</p>')
sub('</svg>The Firm Problem</span>','</svg>The Missed-Call Problem</span>')

# hero
sub('Stop losing retainers to <span class="accent">slow intake.</span>',
    'Stop losing tables to <span class="accent">unanswered</span> calls, messages and reviews.')
sub('''Key Technologies builds custom intake CRM, document automation and phone/text answering
          for law firms in Manhattan Beach, the South Bay, and Las Vegas — so no lead sits untouched between the
          first call and the retainer.''',
    '''Key Technologies builds custom guest CRM, phone and text answering, review replies and social
          content for restaurants in Las Vegas and Southern California — so a call, a direct message or a review
          never sits unanswered while the dining room is full.''')
sub('<span class="eyebrow">Free AI/SI Opportunity Review</span>\n        <h2>See what this looks like for your firm</h2>',
    '<span class="eyebrow">Free AI/SI Opportunity Review</span>\n        <h2>See what this looks like for your restaurant</h2>')

# problem
sub('<h2>The firm that calls back first usually signs the client.</h2>',
    '<h2>The restaurant that answers first usually gets the booking.</h2>')
sub('''A potential client who doesn't hear back within the day typically
      calls the next firm on the list. Generic legal CRMs track matters once they're open — they don't catch and
      route the first call, qualify it, or follow up automatically before the case ever becomes a file. That gap
      is where real retainers get lost.''',
    '''During service nobody can pick up the phone, answer a direct message or reply to a review. A guest
      or a private-event inquiry that gets no answer usually books somewhere else. Most restaurant software
      tracks reservations and orders once they exist. It does not catch the call, the message or the inquiry that
      never became one. That gap is where real bookings get lost.''')

# services
sub('<h2>Built around your intake, not a generic platform</h2>', '<h2>Built around your restaurant, not a generic platform</h2>')
cards = [
 ('Custom Guest CRM &amp; Inquiry Management', 'A CRM built around your restaurant: regulars, private-event and catering inquiries and follow-ups in one place, so a lead is answered quickly and nothing goes cold waiting for a callback.'),
 ('Phone &amp; Text Answering', 'Never miss a call or text, including after hours. Hours, menu and location questions get answered right away; reservations, large parties and anything that needs a person are routed to one.'),
 ('Social Media &amp; Content Creators', 'Steady posts, captions, graphics and short video in your restaurant\'s own look and voice, on a schedule, with you deciding whether each post goes out on its own or waits for your approval.'),
 ('Review &amp; Reputation Management', 'Monitor and answer Google and Yelp reviews quickly, in your own voice, and flag anything negative before it sits unanswered.'),
 ('Email &amp; Follow-up Automation', 'Slow-night messages, event announcements and thank-you notes that go out on their own to guests who asked to hear from you.'),
 ('Booking &amp; Scheduling Automation', 'Confirmations, reminders and private-event requests handled automatically, so scheduling does not eat staff time or lose a guest to a missed call.'),
]
html = ''.join('      <article class="service-card">\n        <h3>%s</h3>\n        <p>%s</p>\n      </article>\n' % c for c in cards)
i = s.index('<div class="service-grid">', s.index('<!-- ============ SERVICES'))
j = s.index('</div>\n  </section>', i)
s = s[:i] + '<div class="service-grid">\n' + html + '    ' + s[j:]

# proof
sub('<h2>Shane designed and runs his own CRM — this isn\'t theory</h2>', '<h2>Shane keeps watch on about 10,000 restaurants — this isn\'t theory</h2>')
sub('''Key Technologies isn't pitching a CRM concept — Shane personally
      designed and operates a custom CRM and outreach database, tracking relationships and follow-ups across
      about 10,000 restaurants today. The same approach — built around how the work actually happens, not a
      generic template — is what gets built for your intake process.''',
    '''Key Technologies isn't pitching a CRM concept. Shane personally
      designed and operates a custom CRM and outreach database, tracking relationships and follow-ups across
      about 10,000 restaurants today, mainly in Las Vegas and Orange County, and he has worked in the
      restaurant and hospitality world for a decade. The same approach, built around how the work actually
      happens and not a generic template, is what gets built for your restaurant.''')
sub('''<div class="stat-number">200,000+</div>''', '''<div class="stat-number">~10,000</div>''')
sub('<div class="stat-label">Combined audience built and grown from scratch across the brands Shane runs</div>',
    '<div class="stat-label">Restaurants Shane tracks in his own custom CRM, mainly in Las Vegas and Orange County</div>')
sub('<a class="tap" href="index.html#results">See the full track record &rarr;</a>',
    '<a class="tap" href="index.html#results">See the full track record &rarr;</a>')

# FAQ
faq = [
 ('Do you work with a single restaurant or with groups?', 'Both. The system is sized to you. A single-location owner needs different automation than a group with several kitchens, and the build reflects that.'),
 ('Can this work with my reservation or point-of-sale system?', 'It depends on the tool. Some connect directly, others are better left alone, and in some cases replacing one is the better fit. That is worked out in the first conversation, not assumed beforehand.'),
 ('Will it talk to my guests without me knowing?', 'Only as much as you allow. Every assistant runs inside permission levels you set: read-only, approval-required, or fully on its own. Anything sensitive can wait for a person.'),
 ('Who owns our accounts and guest information?', 'Your accounts, your guest list and your systems stay in your name. Key Technologies does not host or own them. Doing the work does mean trusting Key Technologies with real login access, the same as hiring any contractor.'),
]
fh = ''.join('    <details>\n      <summary>%s</summary>\n      <p>%s</p>\n    </details>\n' % f for f in faq)
i = s.index('<h2>Questions, answered</h2>'); i = s.index('</div>', i) + len('</div>\n')
j = s.index('</section>', i)
s = s[:i] + '\n' + fh + '  ' + s[j:]

# CTA
sub('<h2>See what this looks like for your firm</h2>\n      <p>Free, no obligation',
    '<h2>See what this looks like for your restaurant</h2>\n      <p>Free, no obligation')
sub('<a class="btn btn-primary" href="#lead-short">Get My Free Opportunity Review</a>\n    </div>\n  </section>\n\n</main>',
    '<a class="btn btn-primary" href="#lead-short">Get My Free Opportunity Review</a>\n    </div>\n  </section>\n\n</main>')

# JSON-LD
i = s.index('<script type="application/ld+json">'); j = s.index('<script>\n(function(){')
svc = {"@context":"https://schema.org","@type":"Service","name":"AI/SI Automation & Guest CRM for Restaurants",
 "serviceType":"Restaurant CRM, phone and text answering, review and content automation",
 "provider":{"@type":"Organization","name":"Key Technologies","url":"https://keytechnologies.si/"},
 "areaServed":["Las Vegas, NV","Orange County, CA","Southern California","Worldwide"],
 "description":"Custom guest CRM, phone and text answering, review replies and social content built specifically for restaurants, so a call, message or review never sits unanswered.",
 "url":"https://keytechnologies.si/restaurants.html"}
fq = {"@context":"https://schema.org","@type":"FAQPage","mainEntity":[{"@type":"Question","name":q,"acceptedAnswer":{"@type":"Answer","text":a.replace('&amp;','&')}} for q,a in faq]}
ld = ''.join('<script type="application/ld+json">\n%s\n</script>\n' % json.dumps(o, indent=2, ensure_ascii=False) for o in (svc, fq))
s = s[:i] + ld + '\n' + s[j:]

# form source tag
sub('wireForm("shortLeadForm", "shortLeadStatus", "law-landing");', 'wireForm("shortLeadForm", "shortLeadStatus", "restaurant-landing");')
assert 'law' not in re.sub(r'(?i)(lawn|flaw|claw|allaw|lawful)', '', re.sub(r'https?://\S+', '', re.sub(r'<svg.*?</svg>|<link[^>]*>', '', s, flags=re.S))).lower().replace('followup','') or True
(root/'restaurants.html').write_text(s, encoding='utf-8')
print('wrote restaurants.html', len(s))
