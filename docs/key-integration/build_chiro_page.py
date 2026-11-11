#!/usr/bin/env python3
"""Builds sites/key-technologies/chiropractors-specialists.html from the law-firm page (same layout, header,
form and footer), replacing the words. Idempotent. Run from the repo root.
No client results, testimonials or compliance claims. Real-system connections are described as set up with you."""
import re, json, pathlib
root = pathlib.Path('sites/key-technologies')
s = (root/'law.html').read_text(encoding='utf-8')

def sub(a, b):
    global s
    assert a in s, a[:70]
    s = s.replace(a, b, 1)

T = 'Patient CRM & AI for Chiropractors | Key Technologies.si'
sub('<title>AI and Intake CRM for Law Firms | Key Technologies.si</title>', '<title>%s</title>' % T)
sub('content="Custom intake CRM, document automation and phone and text answering for law firms in Manhattan Beach, the South Bay and Las Vegas."',
    'content="Patient CRM, appointment reminders, phone and text answering and a practice dashboard for chiropractors and specialists in Manhattan Beach, the South Bay and Las Vegas."')
sub('<meta property="og:title" content="AI and Intake CRM for Law Firms | Key Technologies.si">', '<meta property="og:title" content="%s">' % T)
sub('content="Stop losing retainers to a slow intake process. Custom intake CRM and automation built around how your firm actually works."',
    'content="Stop losing patients to missed calls and empty appointment slots. Custom systems and a practice dashboard built around how your clinic actually works."')
s = s.replace('https://keytechnologies.si/law.html', 'https://keytechnologies.si/chiropractors-specialists.html')
sub('</svg>AI/SI for Law Firms</p>', '</svg>AI/SI for Chiropractors &amp; Specialists</p>')
sub('</svg>The Firm Problem</span>', '</svg>The Empty-Slot Problem</span>')
sub('Stop losing retainers to <span class="accent">slow intake.</span>',
    'Stop losing patients to <span class="accent">missed calls</span> and empty slots.')
sub('''Key Technologies builds custom intake CRM, document automation and phone/text answering
          for law firms in Manhattan Beach, the South Bay, and Las Vegas — so no lead sits untouched between the
          first call and the retainer.''',
    '''Key Technologies builds custom patient CRM, appointment reminders, phone and text answering and a
          practice dashboard for chiropractors and specialist clinics in Manhattan Beach, the South Bay, and
          Las Vegas, so a new patient never goes unanswered and you can see the whole practice on one screen.''')
sub('<h2>See what this looks like for your firm</h2>\n        <form', '<h2>See what this looks like for your practice</h2>\n        <form')
sub('<h2>The firm that calls back first usually signs the client.</h2>', '<h2>The practice that answers first usually books the new patient.</h2>')
sub('''A potential client who doesn't hear back within the day typically
      calls the next firm on the list. Generic legal CRMs track matters once they're open — they don't catch and
      route the first call, qualify it, or follow up automatically before the case ever becomes a file. That gap
      is where real retainers get lost.''',
    '''When the front desk is busy with a patient, the next call goes to voicemail,
      and someone searching for care usually tries the next clinic on the list. Most practice software tracks
      appointments once they exist. It does not catch the call, the form or the message that never became one,
      or tell you which days run empty. That gap is where real new patients get lost.''')
sub('<h2>Built around your intake, not a generic platform</h2>', '<h2>Built around your practice, not a generic platform</h2>')
cards = [
 ('Practice Dashboard', 'Appointments, new patients, no-shows, busiest hours, reviews and follow-ups on one screen, built around the scheduling and billing systems you already use. Try the demo with made-up data.'),
 ('Custom Patient CRM &amp; Inquiry Management', 'A CRM built around your clinic: new-patient inquiries, referrals and follow-ups in one place, captured the moment they arrive, so nothing goes cold waiting for a callback.'),
 ('Phone &amp; Text Answering', 'Never miss a call or text, including after hours. Hours, location and new-patient questions get answered right away; anything clinical or urgent is routed to a person.'),
 ('Appointment Reminders &amp; Rebooking', 'Confirmations, reminders and "time for your next visit" messages that go out on their own to patients who asked to hear from you, so fewer slots sit empty.'),
 ('Review &amp; Reputation Management', 'Monitor and answer Google reviews quickly, in your own voice, and flag anything negative before it sits unanswered.'),
 ('AI/SI Agents', 'An assistant that handles repetitive front-desk tasks, such as common questions and scheduling requests, inside permission levels you set, so you decide how much runs on its own.'),
]
html = ''.join('      <article class="service-card">\n        <h3>%s</h3>\n        <p>%s</p>\n      </article>\n' % c for c in cards)
i = s.index('<div class="service-grid">', s.index('<!-- ============ SERVICES'))
j = s.index('</div>\n  </section>', i)
s = s[:i] + '<div class="service-grid">\n' + html + '    ' + s[j:]

sub('<h2>Shane designed and runs his own CRM — this isn\'t theory</h2>', '<h2>Shane designs and runs his own systems — this isn\'t theory</h2>')
sub('''Key Technologies isn't pitching a CRM concept — Shane personally
      designed and operates a custom CRM and outreach database, tracking relationships and follow-ups across
      about 10,000 restaurants today. The same approach — built around how the work actually happens, not a
      generic template — is what gets built for your intake process.''',
    '''Key Technologies isn't pitching a concept. Shane personally
      designed and operates a custom CRM and outreach database, tracking relationships and follow-ups across
      about 10,000 restaurants today. The same approach, built around how the work actually happens and not a
      generic template, is what gets built for your practice.''')
sub('<div class="stat-number">200,000+</div>', '<div class="stat-number">~10,000</div>')
sub('<div class="stat-label">Combined audience built and grown from scratch across the brands Shane runs</div>',
    '<div class="stat-label">Businesses Shane tracks in his own custom CRM</div>')

faq = [
 ('Can the dashboard connect to my scheduling or practice software?', 'Often yes, and it is set up with you. Which systems can be connected depends on the software you use, so that is worked out in the first conversation, not assumed beforehand. The demo on this site runs on made-up data.'),
 ('What about patient privacy?', 'Anything that touches patient information is planned around your privacy obligations and set up with you, with access limited to the people you choose. Ask in the first conversation and we will go through exactly what would be stored and where.'),
 ('Will it talk to my patients without me knowing?', 'Only as much as you allow. Every assistant runs inside permission levels you set: read-only, approval-required, or fully on its own. Anything clinical or sensitive can wait for a person.'),
 ('Do you work with solo practices as well as larger clinics?', 'Both. A solo practice needs different automation than a multi-provider clinic, and the build reflects that. You can start with one piece, such as the dashboard or the phone answering, and add more later.'),
]
fh = ''.join('    <details>\n      <summary>%s</summary>\n      <p>%s</p>\n    </details>\n' % f for f in faq)
i = s.index('<h2>Questions, answered</h2>'); i = s.index('</div>', i) + len('</div>\n')
j = s.index('</section>', i)
s = s[:i] + '\n' + fh + '  ' + s[j:]

sub('<h2>See what this looks like for your firm</h2>\n      <p>Free, no obligation', '<h2>See what this looks like for your practice</h2>\n      <p>Free, no obligation')

i = s.index('<script type="application/ld+json">'); j = s.index('<script>\n(function(){')
svc = {"@context":"https://schema.org","@type":"Service","name":"AI/SI Automation, Patient CRM & Practice Dashboard for Chiropractors and Specialists",
 "serviceType":"Patient CRM, appointment reminders, phone and text answering and practice dashboards",
 "provider":{"@type":"Organization","name":"Key Technologies","url":"https://keytechnologies.si/"},
 "areaServed":["Manhattan Beach, CA","Las Vegas, NV","Worldwide"],
 "description":"Custom patient CRM, appointment reminders, phone and text answering and a practice dashboard for chiropractors and specialist clinics.",
 "url":"https://keytechnologies.si/chiropractors-specialists.html"}
fq = {"@context":"https://schema.org","@type":"FAQPage","mainEntity":[{"@type":"Question","name":q,"acceptedAnswer":{"@type":"Answer","text":a.replace('&amp;','&')}} for q,a in faq]}
ld = ''.join('<script type="application/ld+json">\n%s\n</script>\n' % json.dumps(o, indent=2, ensure_ascii=False) for o in (svc, fq))
s = s[:i] + ld + '\n' + s[j:]
sub('wireForm("shortLeadForm", "shortLeadStatus", "law-landing");', 'wireForm("shortLeadForm", "shortLeadStatus", "chiropractor-landing");')
(root/'chiropractors-specialists.html').write_text(s, encoding='utf-8')
print('wrote chiropractors-specialists.html', len(s))
