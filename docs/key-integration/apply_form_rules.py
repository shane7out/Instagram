#!/usr/bin/env python3
"""Shane (2026-11-06): on every Key Technologies lead form, First name, Last name, Email and Phone are all required.
Replaces the single "Full name" field with First name + Last name (side by side), makes phone required, and adds a phone
field to the homepage audit form. Idempotent. The shared check lives in key-platform/lead-send.js (it blocks the send and
shows which field is missing; the combined "name" is still saved so the lead list and email alerts keep working).
NOT touched on purpose: the LVR forms (rewards sign-up, join-restaurant): that is the rewards/deal side, left alone."""
import re, pathlib
SITE = pathlib.Path('sites/key-technologies')
PAGES = ['index.html','law.html','medical-dental.html','real-estate.html','ecommerce.html','restaurants.html','book.html','key-platform/partners.html']
ROW = ('<div class="name-row" style="display:grid;grid-template-columns:1fr 1fr;gap:10px">'
       '<div class="field"><label for="{i}-first">First name <span class="req" aria-hidden="true">*</span></label>'
       '<input id="{i}-first" name="firstName" type="text" autocomplete="given-name" required maxlength="40"></div>'
       '<div class="field"><label for="{i}-last">Last name <span class="req" aria-hidden="true">*</span></label>'
       '<input id="{i}-last" name="lastName" type="text" autocomplete="family-name" required maxlength="40"></div></div>')
A = re.compile(r'<div class="field">\s*<label for="([\w-]+)">Full [Nn]ame(?: <span class="req"[^>]*>\*</span>)?</label>\s*<input id="\1" name="name"[^>]*>\s*</div>')
for rel in PAGES:
    f = SITE / rel
    s = f.read_text(encoding='utf-8'); o = s
    s = A.sub(lambda m: ROW.format(i=m.group(1)), s)
    f.write_text(s, encoding='utf-8') if s != o else None
    print(rel, 'name fields split' if s != o else 'unchanged')

def edit(rel, pairs):
    f = SITE / rel; s = f.read_text(encoding='utf-8')
    for a, b in pairs:
        if b in s: continue
        assert s.count(a) == 1, (rel, a[:60], s.count(a))
        s = s.replace(a, b)
    f.write_text(s, encoding='utf-8')

# book.html: phone required, script reads first/last
edit('book.html', [
 ('<label for="bp">Phone (for a text confirmation)</label><input id="bp" name="phone" type="tel" autocomplete="tel" maxlength="30">',
  '<label for="bp">Phone <span class="req" aria-hidden="true">*</span> (for a text confirmation)</label><input id="bp" name="phone" type="tel" autocomplete="tel" required maxlength="30">'),
 ('var nm=f.name.value.trim(),em=f.email.value.trim();if(!nm){f.name.focus();st.textContent="Please enter your name.";st.className="form-status err";return}',
  'var nm=(f.firstName.value.trim()+" "+f.lastName.value.trim()).trim(),em=f.email.value.trim();'),
 ('name:nm.slice(0,80),email:em,', 'name:nm.slice(0,80),firstName:f.firstName.value.trim().slice(0,40),lastName:f.lastName.value.trim().slice(0,40),email:em,'),
])
# partners: phone required
edit('key-platform/partners.html', [
 ('<label for="pphone">Phone (optional)</label><input id="pphone" name="phone" type="tel" autocomplete="tel">',
  '<label for="pphone">Phone <span class="req" aria-hidden="true">*</span></label><input id="pphone" name="phone" type="tel" autocomplete="tel" required>'),
])
# homepage audit form: phone field + script
edit('index.html', [
 ('''        <div class="field">
          <label for="au-email">Email</label>
          <input id="au-email" name="email" type="email" autocomplete="email" required>
        </div>''','''        <div class="field">
          <label for="au-email">Email <span class="req" aria-hidden="true">*</span></label>
          <input id="au-email" name="email" type="email" autocomplete="email" required>
        </div>
        <div class="field">
          <label for="au-phone">Phone <span class="req" aria-hidden="true">*</span></label>
          <input id="au-phone" name="phone" type="tel" autocomplete="tel" required>
        </div>'''),
 ('''      var nameEl = document.getElementById("au-name");
      var emailEl = document.getElementById("au-email");''','''      var firstEl = document.getElementById("au-name-first"), lastEl = document.getElementById("au-name-last");
      var phoneEl = document.getElementById("au-phone");
      var emailEl = document.getElementById("au-email");'''),
 ('      var name = nameEl.value.trim();\n','      var first = firstEl.value.trim(), last = lastEl.value.trim(), name = (first + " " + last).trim(), phone = phoneEl.value.trim();\n'),
 ('''      if(!name){
        nameEl.focus();
        status.textContent = "Please enter your name.";
        status.className = "form-status err";
        return;
      }''','''      if(!first){
        firstEl.focus();
        status.textContent = "Please enter your first name.";
        status.className = "form-status err";
        return;
      }
      if(!last){
        lastEl.focus();
        status.textContent = "Please enter your last name.";
        status.className = "form-status err";
        return;
      }'''),
 ('''      if(!target){
        urlEl.focus();''','''      if(!phone){
        phoneEl.focus();
        status.textContent = "Please enter your phone number.";
        status.className = "form-status err";
        return;
      }
      if(!target){
        urlEl.focus();'''),
 ('''          name: name,
          email: email,
          url: target,''','''          name: name,
          firstName: first,
          lastName: last,
          email: email,
          phone: phone,
          url: target,'''),
])
print('done')
