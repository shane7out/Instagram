#!/usr/bin/env python3
"""Replaces the PIN keypad on the Key Technologies owner tools with the real owner sign-in (idempotent).
Run from the repo root AFTER apply-owner-auth.py:   python3 .github/db-task/owner-auth/apply-owner-gate.py

What changes on each page (kt-crm.html, key-leads.html, key-advertisers.html):
  * the PIN keypad screen becomes an "Owner sign-in required" screen with one button (it opens the sign-in box from
    owner-auth.snippet.html),
  * the PIN value is removed from the page's source,
  * the old "lv_owner_session" / sessionStorage "unlocked" shortcuts are removed (anyone could set those by hand),
  * the page unlocks only while OWNER_AUTH says the owner is signed in, and locks again on sign-out.
The page's own load function is called after sign-in. The database rules (key-rules-owner.json) are what actually keep strangers
out of the data; this screen only decides what the owner sees.
"""
import re, sys

PAGES = {
    '.github/db-task/mac/kt-crm.html':          ('loadProspects', 'kt_crm_unlocked'),
    '.github/db-task/mac/key-leads.html':       ('loadLeads', 'key_leads_unlocked'),
    '.github/db-task/mac/key-advertisers.html': ('loadAll', 'key_adv_unlocked'),
}
MARK = '/*OWNER-SIGNIN-GATE*/'

def balanced_div(s, start):
    """index just past the </div> that closes the <div> starting at `start`"""
    depth, i = 0, start
    for m in re.finditer(r'<div\b|</div>', s[start:]):
        depth += 1 if m.group(0).startswith('<div') else -1
        if depth == 0:
            return start + m.end()
    raise SystemExit('unbalanced div')

for f, (loader, unlocked_key) in PAGES.items():
    s = open(f, encoding='utf-8').read()
    if MARK in s:
        print('already done', f); continue
    # 1. the keypad screen -> sign-in screen
    a = s.index('<div id="pin-screen">')
    b = balanced_div(s, a)
    old = s[a:b]
    logo = re.search(r'<div class="pin-logo">.*?</div>', old, re.S).group(0)
    sub = re.search(r'<div class="pin-sub">(.*?)</div>', old, re.S).group(1)
    sub = re.sub(r'Enter PIN to view', 'Sign in to view', sub)
    if 'Sign in' not in sub:
        sub = sub + ' (owner sign-in)'
    new = ('<div id="pin-screen">\n  ' + logo + '\n  <div class="pin-sub">' + sub + '</div>\n'
           '  <p style="max-width:300px;text-align:center;font-size:14px;line-height:1.5;color:var(--ink-dim);margin:0 0 18px;">'
           'This page opens only when you are signed in as the owner.</p>\n'
           '  <button type="button" id="ownerSignInBtn" style="padding:14px 24px;border-radius:12px;border:1px solid var(--key-blue);'
           'background:transparent;color:var(--ink);font-weight:700;font-size:16px;font-family:inherit;cursor:pointer;">Sign in as owner</button>\n'
           '  <div class="pin-msg" id="pin-msg" role="status"></div>\n</div>')
    s = s[:a] + new + s[b:]
    # 2. the PIN value
    s, n = re.subn(r"  var PIN = '[0-9]+';[^\n]*\n", '', s)
    assert n == 1, (f, 'PIN line', n)
    # 3. the PIN logic block (up to the DATA marker) -> owner sign-in logic
    i = s.index('  // ================= PIN LOGIC =================')
    j = s.index('  // ================= DATA =================')
    logic = ('  // ================= OWNER SIGN-IN ================= ' + MARK + '\n'
             '  // No PIN. The database itself only answers the signed-in owner (rules: key-rules-owner.json), and this page opens\n'
             '  // only while the owner is signed in (the sign-in box comes from owner-auth.snippet.html at the top of this file).\n'
             '  var _unlocked = false;\n'
             '  function _ownerState(){\n'
             '    var on = !!(window.OWNER_AUTH && window.OWNER_AUTH.signedIn());\n'
             "    if (on && !_unlocked) {\n"
             '      _unlocked = true;\n'
             "      document.getElementById('pin-screen').classList.add('hidden');\n"
             "      document.getElementById('app').classList.add('visible');\n"
             '      ' + loader + '();\n'
             '    } else if (!on && _unlocked) {\n'
             '      _unlocked = false;\n'
             "      document.getElementById('app').classList.remove('visible');\n"
             "      document.getElementById('pin-screen').classList.remove('hidden');\n"
             '    }\n'
             '  }\n'
             "  document.getElementById('ownerSignInBtn').addEventListener('click', function(){\n"
             "    var m = document.getElementById('pin-msg');\n"
             '    if (window.OWNER_AUTH) { m.textContent = \'\'; window.OWNER_AUTH.dialog(); }\n'
             "    else m.textContent = 'Owner sign-in is not available on this page.';\n"
             '  });\n'
             '  if (window.OWNER_AUTH) window.OWNER_AUTH.onChange(_ownerState);\n'
             '  setTimeout(_ownerState, 0); // after the rest of the script has set up its variables\n\n')
    s = s[:i] + logic + s[j:]
    open(f, 'w', encoding='utf-8').write(s)
    print('ok', f)
