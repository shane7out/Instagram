#!/usr/bin/env python3
"""Shane (2026-11-06): on every Key Technologies lead form, First name, Last name, Email and Phone are all required.
Replaces the single "Full name" field with First name + Last name (side by side), makes phone required, and adds a phone
field to the homepage audit form. Idempotent. The shared check lives in key-platform/lead-send.js (it blocks the send and
shows which field is missing; the combined "name" is still saved so the lead list and email alerts keep working).
NOT touched on purpose: the LVR forms (rewards sign-up, join-restaurant): that is the rewards/deal side, left alone."""
import re, pathlib
SITE = pathlib.Path('sites/key-technologies')
PAGES = ['index.html','law.html','medical-dental.html','real-estate.html','ecommerce.html','restaurants.html','chiropractors-specialists.html','book.html','key-platform/partners.html']
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
        if a in b and b.replace(a, '', 1).strip() and b.replace(a, '', 1) in s: continue   # inserted text already there (idempotent)
        if s.count(a) == 0:
            print('  (already applied, skipped)', rel, a[:40].replace('\n',' ')); continue
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

# ===================================================================================================================
# PHASE 2 (Shane, 2026-11-06): the BUSINESS NAME is required too, on every lead form; and the same required fields on the
# rewards-side forms (member sign-up, rewards waiting list, restaurant join form). On the rewards side the saved record keeps
# the SAME fields as before (one combined "name", the same phone field); no new fields are added to member records.
# ===================================================================================================================
BIZ = ('<div class="field"><label for="{i}-business">Business name <span class="req" aria-hidden="true">*</span></label>'
       '<input id="{i}-business" name="business" type="text" autocomplete="organization" required maxlength="100"></div>')
ROWRX = re.compile(r'(<div class="name-row"[^>]*>.*?name="lastName"[^>]*></div></div>)', re.S)
for rel in PAGES:
    f = SITE / rel; s = f.read_text(encoding='utf-8'); o = s
    out = []; pos = 0
    for m in ROWRX.finditer(s):
        out.append(s[pos:m.end()]); pos = m.end()
        base = re.search(r'id="([\w-]+)-first"', m.group(1)).group(1)
        tail = s[m.end():m.end() + 700]
        if 'name="business"' in tail:
            continue                      # the form already has its own business field (made required below)
        out.append('\n' + BIZ.format(i=base))
    out.append(s[pos:]); s = ''.join(out)
    if s != o: f.write_text(s, encoding='utf-8')
    print(rel, 'business field added' if s != o else 'business: nothing to add')

edit('index.html', [
 ('<label for="f-business">Business Name</label>\n          <input id="f-business" name="business" type="text" autocomplete="organization">',
  '<label for="f-business">Business Name <span class="req" aria-hidden="true">*</span></label>\n          <input id="f-business" name="business" type="text" autocomplete="organization" required>'),
 ('''      if(!target){
        urlEl.focus();''','''      if(!business){
        businessEl.focus();
        status.textContent = "Please enter your business name.";
        status.className = "form-status err";
        return;
      }
      if(!target){
        urlEl.focus();'''),
 ('      var phoneEl = document.getElementById("au-phone");\n','      var phoneEl = document.getElementById("au-phone"), businessEl = document.getElementById("au-name-business");\n'),
 ('phone = phoneEl.value.trim();\n','phone = phoneEl.value.trim(), business = businessEl.value.trim();\n'),
 ('          phone: phone,\n          url: target,','          phone: phone,\n          business: business,\n          url: target,'),
])
edit('book.html', [('lastName:f.lastName.value.trim().slice(0,40),email:em,','lastName:f.lastName.value.trim().slice(0,40),business:f.business.value.trim().slice(0,100),email:em,')])

# ---- rewards side ----
edit('rewards.html', [
 ('''            <label for="r-name">Name <span class="req" aria-hidden="true">*</span></label>
            <input id="r-name" name="name" type="text" autocomplete="name" required>''',
  '''            <label for="r-name-first">First name <span class="req" aria-hidden="true">*</span></label>
            <input id="r-name-first" name="firstName" type="text" autocomplete="given-name" required maxlength="40">
          </div>
          <div class="field">
            <label for="r-name-last">Last name <span class="req" aria-hidden="true">*</span></label>
            <input id="r-name-last" name="lastName" type="text" autocomplete="family-name" required maxlength="40">'''),
 ('<label for="r-phone">Phone (optional)</label>','<label for="r-phone">Phone <span class="req" aria-hidden="true">*</span></label>'),
 ('<input id="r-phone" name="phone" type="tel" autocomplete="tel">','<input id="r-phone" name="phone" type="tel" autocomplete="tel" required>'),
 ('    var name = document.getElementById("r-name").value.trim();','    var name = (document.getElementById("r-name-first").value.trim() + " " + document.getElementById("r-name-last").value.trim()).trim();'),
 ('''<div class="field"><label for="w-name">Name</label><input id="w-name" type="text" autocomplete="name"></div>' +''',
  '''<div class="field"><label for="w-first">First name <span class="req" aria-hidden="true">*</span></label><input id="w-first" name="firstName" type="text" autocomplete="given-name" required maxlength="40"></div>' +
      '<div class="field"><label for="w-last">Last name <span class="req" aria-hidden="true">*</span></label><input id="w-last" name="lastName" type="text" autocomplete="family-name" required maxlength="40"></div>' +'''),
 ('''<input id="w-email" type="email" autocomplete="email" required></div>' +''',
  '''<input id="w-email" name="email" type="email" autocomplete="email" required></div>' +
      '<div class="field"><label for="w-phone">Phone <span class="req" aria-hidden="true">*</span></label><input id="w-phone" name="phone" type="tel" autocomplete="tel" required></div>' +'''),
 ('name: document.getElementById("w-name").value.trim(), email: email,','name: (document.getElementById("w-first").value.trim() + " " + document.getElementById("w-last").value.trim()).trim(), phone: document.getElementById("w-phone").value.trim(), email: email,'),
])
edit('join-restaurant.html', [
 ('''            <label for="j-name">Your name <span class="req" aria-hidden="true">*</span></label>
            <input id="j-name" name="name" type="text" autocomplete="name" required>''',
  '''            <label for="j-name-first">First name <span class="req" aria-hidden="true">*</span></label>
            <input id="j-name-first" name="firstName" type="text" autocomplete="given-name" required maxlength="40">
          </div>
          <div class="field">
            <label for="j-name-last">Last name <span class="req" aria-hidden="true">*</span></label>
            <input id="j-name-last" name="lastName" type="text" autocomplete="family-name" required maxlength="40">'''),
 ('<label for="j-phone">Phone <span class="opt">(optional)</span></label>','<label for="j-phone">Phone <span class="req" aria-hidden="true">*</span></label>'),
 ('<input id="j-phone" name="phone" type="tel" autocomplete="tel">','<input id="j-phone" name="phone" type="tel" autocomplete="tel" required>'),
 ('    var name = $("j-name").value.trim();','    var first = $("j-name-first").value.trim(), last = $("j-name-last").value.trim(), name = (first + " " + last).trim();'),
 ('    if (!name) { fail("Please enter your name.", $("j-name")); return; }','    if (!first) { fail("Please enter your first name.", $("j-name-first")); return; }\n    if (!last) { fail("Please enter your last name.", $("j-name-last")); return; }'),
 ('''    if (!/^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/.test(email)) { fail("Please enter a valid email.", $("j-email")); return; }''',
  '''    if (!/^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/.test(email)) { fail("Please enter a valid email.", $("j-email")); return; }
    if (($("j-phone").value.replace(/\\D/g, "")).length < 7 || ($("j-phone").value.replace(/\\D/g, "")).length > 15) { fail("Please enter a phone number we can reach you on (with area code).", $("j-phone")); return; }'''),
 ('      name: name,\n      email: email,\n      phone: $("j-phone").value.trim(),','      name: name,\n      firstName: first,\n      lastName: last,\n      email: email,\n      phone: $("j-phone").value.trim(),'),
])
edit('rewards-privacy.html', [("your name, email address and, if you choose to give it, your phone number","your name, email address and phone number")])
print('phase 2 done')
