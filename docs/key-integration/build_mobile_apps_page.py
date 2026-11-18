#!/usr/bin/env python3
"""Builds sites/key-technologies/mobile-apps.html (Shane, 2026-11-17: "go heavily into the SEO ... custom apps for Android and Apple, and independent, like their own
APK file ... known as the people that know how to build apps, websites"). Same layout, header, form and footer as the law-firm page, with the words replaced.
Idempotent. Run from the repo root after build_restaurant_page.py. Adds the sitemap and llms.txt entries.
Only claims already on the site are used (42+ years of computer and software experience; about 10,000 restaurants in Shane's own CRM). No prices, no client
results, no reviews, no rankings. Platform facts are stated carefully: Android can install an APK file directly, iPhone apps go through the App Store or TestFlight."""
import re, json, pathlib
root = pathlib.Path('sites/key-technologies')
s = (root/'law.html').read_text(encoding='utf-8')

def sub(a, b):
    global s
    assert a in s, a[:70]
    s = s.replace(a, b, 1)

T = 'Custom Mobile Apps for iPhone & Android | Key Technologies.si'
D = 'We build custom mobile apps for iPhone and Android, including an Android APK you own, plus the websites behind them. Las Vegas, Manhattan Beach, worldwide.'
sub('<title>AI and Intake CRM for Law Firms | Key Technologies.si</title>', '<title>%s</title>' % T.replace('&', '&amp;'))
sub('content="Custom intake CRM, document automation and phone and text answering for law firms in Manhattan Beach, the South Bay and Las Vegas."', 'content="%s"' % D)
sub('<meta property="og:title" content="AI and Intake CRM for Law Firms | Key Technologies.si">', '<meta property="og:title" content="%s">' % T.replace('&', '&amp;'))
sub('content="Stop losing retainers to a slow intake process. Custom intake CRM and automation built around how your firm actually works."',
    'content="Custom apps for iPhone and Android, with an Android APK file you own, built by a team with 42+ years of computer and software experience."')
s = s.replace('https://keytechnologies.si/law.html', 'https://keytechnologies.si/mobile-apps.html')
sub('</svg>AI/SI for Law Firms</p>', '</svg>Mobile App Development</p>')
sub('</svg>The Firm Problem</span>', '</svg>Why an App</span>')
sub('Stop losing retainers to <span class="accent">slow intake.</span>', 'Custom mobile apps for <span class="accent">iPhone and Android.</span>')
sub('''Key Technologies builds custom intake CRM, document automation and phone/text answering
          for law firms in Manhattan Beach, the South Bay, and Las Vegas — so no lead sits untouched between the
          first call and the retainer.''',
    '''Key Technologies designs and builds mobile apps for iPhone and Android, including a standalone Android
          APK file you own, with the website and systems behind them. Built by a developer with 42+ years of computer and
          software experience, for businesses in Las Vegas, Manhattan Beach and worldwide.''')
sub('<h2>See what this looks like for your firm</h2>\n        <form', '<h2>Tell us about the app you want</h2>\n        <form')
sub('<a class="btn btn-ghost" href="index.html#services">See All Services</a>', '<a class="btn btn-ghost" href="key-platform/demos/mobile-apps.html">Try the app demo</a>')

sub('<h2>The firm that calls back first usually signs the client.</h2>', '<h2>Your customers already live on their phones.</h2>')
sub('''A potential client who doesn't hear back within the day typically
      calls the next firm on the list. Generic legal CRMs track matters once they're open — they don't catch and
      route the first call, qualify it, or follow up automatically before the case ever becomes a file. That gap
      is where real retainers get lost.''',
    '''An app puts your rewards, ordering, booking or crew tools one tap from the home screen.
      The catch is that many app builders hand you a template that is rented, locked to one platform, and
      gone if you stop paying. We build the app around how your business actually works, and the accounts,
      domain, hosting and data stay in your name.''')

sub('<h2>Built around your intake, not a generic platform</h2>', '<h2>What we build</h2>')
cards = [
 ('iPhone apps', 'Apps for iPhone and iPad, published through the App Store, or shared privately with your team through TestFlight while you test.'),
 ('Android apps and your own APK file', 'Apps for Android, published on Google Play or delivered as an APK file you own. An APK is the installable file for Android, so you can host it on your own website and people can install it without waiting on a store.'),
 ('One app for both phones', 'When it makes sense, one shared codebase for iPhone and Android, so both stay in step and updates ship together. When a feature needs the phone\'s own tools, we build it natively.'),
 ('Installable web apps', 'An app-like experience that installs from the browser, with no store at all, when that is the simpler and better fit.'),
 ('Rewards, ordering and booking apps', 'Loyalty cards, order-ahead, reservations and appointment booking, connected to your website, point-of-sale and calendar where the software allows it.'),
 ('Staff and field apps', 'Job lists, check-in, photo upload and offline mode for crews, drivers and front-of-house teams, with an admin screen for you.'),
 ('Websites, back ends and security', 'The website, database, notifications and sign-in that make the app work, built and secured by the same team. See <a href="key-platform/demos/website-development.html">Website Development</a>.'),
]
html = ''.join('      <article class="service-card">\n        <h3>%s</h3>\n        <p>%s</p>\n      </article>\n' % c for c in cards)
i = s.index('<div class="service-grid">', s.index('<!-- ============ SERVICES'))
j = s.index('</div>\n  </section>', i)
s = s[:i] + '<div class="service-grid">\n' + html + '    ' + s[j:]

sub('<h2>Shane designed and runs his own CRM — this isn\'t theory</h2>', '<h2>We have been building software for a very long time</h2>')
sub('''This is not just a CRM idea. Shane personally
      designed and operates a custom CRM and outreach database, tracking relationships and follow-ups across
      about 10,000 restaurants today. The same approach — built around how the work actually happens, not a
      generic template — is what gets built for your intake process.''',
    '''Shane has been building websites and software since long before
      apps existed, and still designs and runs his own custom systems today, including a CRM and outreach database
      that tracks about 10,000 restaurants. Apps, websites and the systems behind them are the same craft: built
      around how the work actually happens, not around a template.''')
sub('<div class="stat-number">200,000+</div>', '<div class="stat-number">42+ yrs</div>')
sub('<div class="stat-label">Combined audience built and grown from scratch across the brands Shane runs</div>', '<div class="stat-label">Hands-on experience with computers and software</div>')
sub('<div class="stat-number">25+ yrs</div>', '<div class="stat-number">~10,000</div>')
sub('<div class="stat-label">Hands-on experience in security, networking and business technology</div>', '<div class="stat-label">Restaurants tracked in the custom CRM Shane designed and runs</div>')

# the dashboard band becomes the app-demo band
a = s.index('<!-- ============ DASHBOARD BAND'); b = s.index('<!-- ============ FAQ')
s = s[:a] + '''<!-- ============ APP DEMO BAND ============ -->
  <section class="wrap">
    <div class="section-head">
      <h2>See an app before you commit to one</h2>
    </div>
    <p style="max-width:70ch;font-size:17px;">Pick a type of app, tick the features and watch a phone change as you go. Everything in the demo is made-up sample data.</p>
    <p style="margin-top:16px;"><a class="btn btn-primary" href="key-platform/demos/mobile-apps.html">Try the mobile app demo &rarr;</a></p>
    <p style="margin-top:12px;max-width:70ch;color:var(--ink-dim);">Start with one feature and add more as it earns its place.</p>
  </section>

  ''' + s[b:]

faq = [
 ('Do you build apps for both iPhone and Android?', 'Yes. We build for iPhone and Android, either as one shared app or as separate apps when a feature needs the phone\'s own tools. We say which is the better fit for your goals before any work starts.'),
 ('What is an APK file, and can I have my own?', 'An APK is the installable file for an Android app. We can deliver one that you own and host on your own website, so people can install the app without a store. Android may ask the person to allow installs from that source, and many people still prefer Google Play, so we can publish there too. iPhones work differently: Apple controls installs, so iPhone apps go through the App Store, or through TestFlight for private testing.'),
 ('Do I need an app, or is a website enough?', 'Often a good website is enough. An app earns its place when people will use it again and again, or when it needs the phone itself: notifications, the camera, offline use or a saved rewards card. We will tell you honestly if a website or an installable web app is the better answer.'),
 ('Who owns the app, the accounts and the data?', 'Your developer accounts, domain, hosting and data stay in your name, the same as the rest of our work. Who owns the finished app and its code is something we settle with you in writing before work starts.'),
 ('Can the app connect to my website, rewards or bookings?', 'Often yes, and it is set up with you. What can be connected depends on the software you use, so that is worked out in the first conversation, not assumed.'),
 ('How do we get started?', 'Start with the free Opportunity Review: tell us what the app should do and who will use it. We will say honestly whether an app, a website or a smaller first step makes the most sense.'),
]
fh = ''.join('    <details>\n      <summary>%s</summary>\n      <p>%s</p>\n    </details>\n' % f for f in faq)
i = s.index('<h2>Questions, answered</h2>'); i = s.index('</div>', i) + len('</div>\n')
j = s.index('</section>', i)
s = s[:i] + '\n' + fh + '    <p style="margin-top:18px;">Related guide: <a href="guides/iphone-android-apk-mobile-app-guide.html">iPhone app, Android app, APK or web app? A plain guide &rarr;</a></p>\n  ' + s[j:]

sub('<h2>See what this looks like for your firm</h2>\n      <p>Free, no obligation', '<h2>Tell us about the app you want</h2>\n      <p>Free, no obligation')

i = s.index('<script type="application/ld+json">'); j = s.index('<script>\n(function(){')
svc = {"@context":"https://schema.org","@type":"Service","name":"Custom Mobile App Development for iPhone and Android",
 "serviceType":"Mobile app development, Android APK delivery, iPhone apps, cross-platform apps, installable web apps, websites and back ends",
 "provider":{"@type":"Organization","name":"Key Technologies","url":"https://keytechnologies.si/"},
 "areaServed":["Las Vegas, NV","Manhattan Beach, CA","Worldwide"],
 "description":"Custom mobile apps for iPhone and Android, including a standalone Android APK file the client owns, plus the websites and systems behind them.",
 "url":"https://keytechnologies.si/mobile-apps.html"}
fq = {"@context":"https://schema.org","@type":"FAQPage","mainEntity":[{"@type":"Question","name":q,"acceptedAnswer":{"@type":"Answer","text":a.replace('&amp;','&')}} for q,a in faq]}
ld = ''.join('<script type="application/ld+json">\n%s\n</script>\n' % json.dumps(o, indent=2, ensure_ascii=False) for o in (svc, fq))
s = s[:i] + ld + '\n' + s[j:]
sub('wireForm("shortLeadForm", "shortLeadStatus", "law-landing");', 'wireForm("shortLeadForm", "shortLeadStatus", "mobile-apps-landing");')
(root/'mobile-apps.html').write_text(s, encoding='utf-8')

# sitemap + llms.txt (idempotent)
sm = (root/'sitemap.xml').read_text(encoding='utf-8')
loc = 'https://keytechnologies.si/mobile-apps.html'
if loc not in sm:
    sm = sm.replace('</urlset>', '  <url>\n    <loc>%s</loc>\n    <lastmod>2026-11-17</lastmod>\n    <changefreq>monthly</changefreq>\n    <priority>0.8</priority>\n  </url>\n</urlset>' % loc)
    (root/'sitemap.xml').write_text(sm, encoding='utf-8')
t = (root/'llms.txt').read_text(encoding='utf-8')
line = '- [Custom mobile apps](%s): iPhone and Android apps, including an Android APK file the client owns, plus the websites and systems behind them\n' % loc
if loc not in t:
    k = t.index('- [For restaurants]'); t = t[:k] + line + t[k:]
    (root/'llms.txt').write_text(t, encoding='utf-8')
print('wrote mobile-apps.html', len(s))
