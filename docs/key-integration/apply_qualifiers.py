#!/usr/bin/env python3
"""Shane (2026-11-26): every client lead form must ask, as REQUIRED fields, (1) what the business does, (2) what they want done,
(3) when they want to start. Without them the form does not send ("they don't fill that out, they don't reach us").
Inserts the three fields right after the Business name field on: the home page (audit, short and full forms), the service/industry pages
(short form) and the book-a-call form. Idempotent. The check itself (and copying the answers into the saved lead + email alert) lives in
key-platform/lead-send.js. NOT touched on purpose: partners.html (a partner application), the LVR rewards / join forms.
Run after apply_form_rules.py and every build_* script (the build scripts regenerate the short forms)."""
import re, pathlib
SITE = pathlib.Path('sites/key-technologies')
PAGES = ['index.html','law.html','medical-dental.html','real-estate.html','ecommerce.html','restaurants.html','chiropractors-specialists.html','website-development.html','mobile-apps.html','book.html']
BIZ = re.compile(r'(<div class="field">\s*<label for="[\w-]+">Business [Nn]ame[^<]*(?:<span class="req"[^>]*>\*</span>)?</label>\s*<input id="([\w-]+)" name="business"[^>]*>\s*</div>)')
CSS = ('<style id="qualifiers-css">.field textarea,.field select{font-family:inherit;font-size:16px;color:var(--ink);background:var(--bg-2);'
       'border:1px solid var(--control-line,var(--line));border-radius:8px;padding:12px 13px;width:100%}'
       '.field textarea{resize:vertical;min-height:84px}.field textarea:focus,.field select:focus{outline:2px solid var(--key-blue);outline-offset:1px}</style>')
def block(i):
    return ('<!--QUALIFIERS-->'
     '<div class="field"><label for="%(i)s-does">What does your business do? <span class="req" aria-hidden="true">*</span></label>'
     '<input id="%(i)s-does" name="businessDoes" type="text" required maxlength="160" placeholder="For example: family dental practice"></div>'
     '<div class="field"><label for="%(i)s-want">What do you want done? <span class="req" aria-hidden="true">*</span></label>'
     '<textarea id="%(i)s-want" name="wantDone" rows="3" required maxlength="600" placeholder="The result you are after, in a sentence or two"></textarea></div>'
     '<div class="field"><label for="%(i)s-when">When do you want to start? <span class="req" aria-hidden="true">*</span></label>'
     '<select id="%(i)s-when" name="startWhen" required><option value="">Choose one</option><option>As soon as possible</option>'
     '<option>Within 30 days</option><option>In 1 to 3 months</option><option>More than 3 months from now</option></select></div>'
     '<!--/QUALIFIERS-->') % {'i': i}
for rel in PAGES:
    f = SITE / rel
    s = f.read_text(encoding='utf-8')
    if '<!--QUALIFIERS-->' in s:
        # a rebuilt page may have lost one form's block: only add where a business field has no block right after it
        pass
    n = 0
    def sub(m):
        global n
        tail = s[m.end():m.end()+20]
        if tail.startswith('<!--QUALIFIERS-->'): return m.group(1)
        n += 1
        return m.group(1) + block(m.group(2))
    out = BIZ.sub(sub, s)
    # pages with their own small stylesheet only style <input>: give the new answer box and dropdown the same look
    if 'id="qualifiers-css"' not in out and '<link rel="stylesheet" href="key-platform/site-base.css">' not in out and '</head>' in out:
        out = out.replace('</head>', CSS + '</head>', 1)
    if out != s: f.write_text(out, encoding='utf-8')
    print(rel, 'added to %d form(s)' % n if n else 'unchanged', '| forms:', s.count('name="business"'))
