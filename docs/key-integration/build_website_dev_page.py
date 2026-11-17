#!/usr/bin/env python3
"""Builds sites/key-technologies/website-development.html (SEO push, 2026-11-17: Shane wants to be known as the people who build apps AND websites). Same layout, header,
form and footer as the law-firm page, with the words replaced. Idempotent. Run from the repo root after build_mobile_apps_page.py. Adds the sitemap and llms.txt entries.
Only claims already on the site are used (42+ years of computer and software experience; about 10,000 restaurants in Shane's own CRM). No prices, no client results,
no reviews, no rankings, no delivery-time promises."""
import re, json, pathlib
root = pathlib.Path('sites/key-technologies')
s = (root/'law.html').read_text(encoding='utf-8')

def sub(a, b):
    global s
    assert a in s, a[:70]
    s = s.replace(a, b, 1)

T = 'Custom Website Development | Key Technologies.si'
D = 'Custom websites built around your business: fast, secure, easy to find, with chat and lead capture built in. Las Vegas, Manhattan Beach, worldwide.'
sub('<title>AI and Intake CRM for Law Firms | Key Technologies.si</title>', '<title>%s</title>' % T.replace('&', '&amp;'))
sub('content="Custom intake CRM, document automation and phone and text answering for law firms in Manhattan Beach, the South Bay and Las Vegas."', 'content="%s"' % D)
sub('<meta property="og:title" content="AI and Intake CRM for Law Firms | Key Technologies.si">', '<meta property="og:title" content="%s">' % T.replace('&', '&amp;'))
sub('content="Stop losing retainers to a slow intake process. Custom intake CRM and automation built around how your firm actually works."',
    'content="Custom websites built by a developer with 42+ years of computer and software experience: fast, secure, easy to find, with lead capture built in."')
s = s.replace('https://keytechnologies.si/law.html', 'https://keytechnologies.si/website-development.html')
sub('</svg>AI/SI for Law Firms</p>', '</svg>Website Development</p>')
sub('</svg>The Firm Problem</span>', '</svg>Why It Matters</span>')
sub('Stop losing retainers to <span class="accent">slow intake.</span>', 'Websites built <span class="accent">around your business.</span>')
sub('''Key Technologies builds custom intake CRM, document automation and phone/text answering
          for law firms in Manhattan Beach, the South Bay, and Las Vegas — so no lead sits untouched between the
          first call and the retainer.''',
    '''Key Technologies designs and builds fast, secure websites with chat, personalization and lead
          capture built in, for businesses in Las Vegas, Manhattan Beach and worldwide. Built by a developer with 42+ years
          of computer and software experience.''')
sub('<h2>See what this looks like for your firm</h2>\n        <form', '<h2>Tell us about the website you want</h2>\n        <form')
sub('<a class="btn btn-ghost" href="index.html#services">See All Services</a>', '<a class="btn btn-ghost" href="key-platform/demos/website-development.html">Try the website demo</a>')

sub('<h2>The firm that calls back first usually signs the client.</h2>', '<h2>Your website is often the first thing a customer sees.</h2>')
sub('''A potential client who doesn't hear back within the day typically
      calls the next firm on the list. Generic legal CRMs track matters once they're open — they don't catch and
      route the first call, qualify it, or follow up automatically before the case ever becomes a file. That gap
      is where real retainers get lost.''',
    '''A slow, hard-to-use or hard-to-find website quietly costs you customers every day. Many
      sites are built from a rented template that is slow, locked to one company and hard to change. We build the
      website around how your business actually works, and the accounts, domain, hosting and data stay in your name.''')

sub('<h2>Built around your intake, not a generic platform</h2>', '<h2>What we build</h2>')
cards = [
 ('Custom business websites', 'A website designed around your business, your customers and your brand, not a one-size-fits-all template. Fast on phones, clear to read, easy to update.'),
 ('Chat, personalization and lead capture', 'An on-site assistant that answers common questions, a page that welcomes returning visitors, and forms that capture a lead the moment someone is interested. See the <a href="key-platform/demos/website-development.html">website demo</a>.'),
 ('Custom web applications and tools', 'Quote tools, customer portals, dashboards and other custom logic a template cannot do, built and maintained by the same developer. See <a href="key-platform/demos/custom-programming.html">Custom Website Programming</a>.'),
 ('Move off WordPress or PHP', 'If your current site is slow, hard to secure or hard to change, we plan the move to a modern custom build and keep your search rankings with redirects. See <a href="key-platform/demos/php-wordpress-migration.html">the migration demo</a>.'),
 ('Speed, accessibility and security', 'Pages that load quickly, sites built and audited to ADA and WCAG accessibility standards, and a full security pass. See <a href="key-platform/demos/accessibility-ada.html">ADA &amp; Accessibility</a>.'),
 ('Found on Google and by AI assistants', 'Clean structure, honest titles and descriptions, structured data and plain-language content, so search engines and AI assistants can understand and cite your site.'),
 ('Mobile apps to go with it', 'When your customers will use you again and again, an iPhone and Android app can sit alongside the website. See <a href="mobile-apps.html">mobile apps</a>.'),
]
html = ''.join('      <article class="service-card">\n        <h3>%s</h3>\n        <p>%s</p>\n      </article>\n' % c for c in cards)
i = s.index('<div class="service-grid">', s.index('<!-- ============ SERVICES'))
j = s.index('</div>\n  </section>', i)
s = s[:i] + '<div class="service-grid">\n' + html + '    ' + s[j:]

sub('<h2>Shane designed and runs his own CRM — this isn\'t theory</h2>', '<h2>We have been building websites for a very long time</h2>')
sub('''Key Technologies isn't pitching a CRM concept — Shane personally
      designed and operates a custom CRM and outreach database, tracking relationships and follow-ups across
      about 10,000 restaurants today. The same approach — built around how the work actually happens, not a
      generic template — is what gets built for your intake process.''',
    '''Shane has been building websites and software for decades, and still designs and runs his own
      custom systems today, including a CRM and outreach database that tracks about 10,000 restaurants. Websites,
      apps and the systems behind them are the same craft: built around how the work actually happens, not around a template.''')
sub('<div class="stat-number">200,000+</div>', '<div class="stat-number">42+ yrs</div>')
sub('<div class="stat-label">Combined audience built and grown from scratch across the brands Shane runs</div>', '<div class="stat-label">Hands-on experience with computers and software</div>')
sub('<div class="stat-number">25+ yrs</div>', '<div class="stat-number">~10,000</div>')
sub('<div class="stat-label">Hands-on experience in security, networking and business technology</div>', '<div class="stat-label">Restaurants tracked in the custom CRM Shane designed and runs</div>')

# the dashboard band becomes the app-demo band
a = s.index('<!-- ============ DASHBOARD BAND'); b = s.index('<!-- ============ FAQ')
s = s[:a] + '''<!-- ============ APP DEMO BAND ============ -->
  <section class="wrap">
    <div class="section-head">
      <h2>See a site before you commit to one</h2>
    </div>
    <p style="max-width:70ch;font-size:17px;">Try the sample florist website: ask its built-in assistant a question and switch personalization on. Everything in the demo is made-up sample data.</p>
    <p style="margin-top:16px;"><a class="btn btn-primary" href="key-platform/demos/website-development.html">Try the website demo &rarr;</a></p>
    <p style="margin-top:12px;max-width:70ch;color:var(--ink-dim);">Start with what matters most and add more as it earns its place.</p>
  </section>

  ''' + s[b:]

faq = [
 ('Do you build on WordPress or from scratch?', 'We build custom sites from scratch around your business, and we can move an existing WordPress or PHP site to a modern custom build when that is the better answer. We say honestly which fits your goals before any work starts.'),
 ('Who owns the website, the domain and the hosting?', 'You do. Your domain, hosting and data stay in your name, the same as the rest of our work. Who owns the finished code is something we settle with you in writing before work starts.'),
 ('Can the website take bookings, collect leads and answer questions?', 'Yes. Forms, lead capture, an on-site assistant and booking can be built in, and connected to the tools you already use where the software allows it. What can be connected depends on your software, so that is worked out in the first conversation.'),
 ('Will my site be found on Google?', 'We build it so search engines can read it properly: clean structure, honest titles and descriptions and structured data. Nobody can promise a ranking, and we will not. We can promise a site that gives search engines and AI assistants the best chance to understand you.'),
 ('Can you rebuild or fix my current website?', 'Often yes. Start with our free website audit, which shows where your site stands on speed, security and accessibility, and then we talk about what is worth changing.'),
 ('How do we get started?', 'Start with the free Opportunity Review: tell us what the website should do and who it is for. We will say honestly whether a new site, a rebuild or a smaller first step makes the most sense.'),
]
fh = ''.join('    <details>\n      <summary>%s</summary>\n      <p>%s</p>\n    </details>\n' % f for f in faq)
i = s.index('<h2>Questions, answered</h2>'); i = s.index('</div>', i) + len('</div>\n')
j = s.index('</section>', i)
s = s[:i] + '\n' + fh + '    <p style="margin-top:18px;">Related guide: <a href="guides/iphone-android-apk-mobile-app-guide.html">iPhone app, Android app, APK or web app? A plain guide &rarr;</a></p>\n  ' + s[j:]

sub('<h2>See what this looks like for your firm</h2>\n      <p>Free, no obligation', '<h2>Tell us about the website you want</h2>\n      <p>Free, no obligation')

i = s.index('<script type="application/ld+json">'); j = s.index('<script>\n(function(){')
svc = {"@context":"https://schema.org","@type":"Service","name":"Custom Website Development",
 "serviceType":"Custom website development, web applications, WordPress and PHP migration, accessibility and security, search and AI visibility",
 "provider":{"@type":"Organization","name":"Key Technologies","url":"https://keytechnologies.si/"},
 "areaServed":["Las Vegas, NV","Manhattan Beach, CA","Worldwide"],
 "description":"Custom websites built around the business, with chat and lead capture, built and secured by one developer with 42+ years of experience.",
 "url":"https://keytechnologies.si/website-development.html"}
fq = {"@context":"https://schema.org","@type":"FAQPage","mainEntity":[{"@type":"Question","name":q,"acceptedAnswer":{"@type":"Answer","text":a.replace('&amp;','&')}} for q,a in faq]}
ld = ''.join('<script type="application/ld+json">\n%s\n</script>\n' % json.dumps(o, indent=2, ensure_ascii=False) for o in (svc, fq))
s = s[:i] + ld + '\n' + s[j:]
sub('wireForm("shortLeadForm", "shortLeadStatus", "law-landing");', 'wireForm("shortLeadForm", "shortLeadStatus", "website-development-landing");')
(root/'website-development.html').write_text(s, encoding='utf-8')

# sitemap + llms.txt (idempotent)
sm = (root/'sitemap.xml').read_text(encoding='utf-8')
loc = 'https://keytechnologies.si/website-development.html'
if loc not in sm:
    sm = sm.replace('</urlset>', '  <url>\n    <loc>%s</loc>\n    <lastmod>2026-11-17</lastmod>\n    <changefreq>monthly</changefreq>\n    <priority>0.8</priority>\n  </url>\n</urlset>' % loc)
    (root/'sitemap.xml').write_text(sm, encoding='utf-8')
t = (root/'llms.txt').read_text(encoding='utf-8')
line = '- [Custom website development](%s): custom websites with chat and lead capture, web applications, WordPress and PHP migration, accessibility and security\n' % loc
if loc not in t:
    k = t.index('- [For restaurants]'); t = t[:k] + line + t[k:]
    (root/'llms.txt').write_text(t, encoding='utf-8')
print('wrote website-development.html', len(s))
