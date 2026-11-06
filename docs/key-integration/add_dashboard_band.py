#!/usr/bin/env python3
"""Adds a 'Business Dashboard' band (link to the dashboards demo) to the industry pages, and the soft
'start small' line. Idempotent (marker comment). Run from the repo root AFTER the build_* scripts."""
import pathlib
root = pathlib.Path('sites/key-technologies')
MARK = '<!-- ============ DASHBOARD BAND ============ -->'
PAGES = {
 'restaurants.html': ('restaurant', 'See your whole restaurant on one screen',
   'Sales, covers, busiest hours, reviews and follow-ups together in one dashboard, built around the point-of-sale, reservation and delivery systems you already use, such as Square, Clover, Toast or Otter. Real connections are set up with you and depend on the systems you use.'),
 'law.html': ('law', 'See your whole firm on one screen',
   'New inquiries, consultations booked, consult-to-retainer rate and follow-ups together in one dashboard, built around the practice-management and calendar tools you already use. Real connections are set up with you and depend on the systems you use.'),
 'medical-dental.html': ('dental', 'See your whole practice on one screen',
   'Appointments, new patients, no-shows, reviews and recall follow-ups together in one dashboard, built around the scheduling and practice software you already use. Real connections are set up with you and depend on the systems you use.'),
 'chiropractors-specialists.html': ('chiro', 'See your whole practice on one screen',
   'Visits, new patients, no-shows, busiest hours and follow-ups together in one dashboard, built around the scheduling and billing systems you already use. Real connections are set up with you and depend on the systems you use.'),
}
for page, (ind, h, p) in PAGES.items():
    f = root/page
    s = f.read_text(encoding='utf-8')
    if MARK in s:  # replace an older/inherited band (the restaurant and chiropractor pages are built from law.html)
        a = s.index(MARK); b = s.index('</section>', a) + len('</section>\n\n  ')
        s = s[:a] + s[b:]
    i = s.index('<!-- ============ FAQ')
    band = '''%s
  <section class="wrap">
    <div class="section-head">
      <h2>%s</h2>
    </div>
    <p style="max-width:70ch;font-size:17px;">%s</p>
    <p style="margin-top:16px;"><a class="btn btn-primary" href="key-platform/demos/business-dashboards.html?i=%s">Try the dashboard demo (made-up data) &rarr;</a></p>
    <p style="margin-top:12px;max-width:70ch;color:var(--ink-dim);">Start with one piece and add more as it earns its place. Plans are built around your size and goals.</p>
  </section>

  ''' % (MARK, h, p, ind)
    s = s[:i] + band + s[i:]
    f.write_text(s, encoding='utf-8')
    print('band ->', page)
