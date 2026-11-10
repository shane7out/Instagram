#!/usr/bin/env python3
"""Light look for Shane's private owner pages (Shane, 2026-11-10: "I want to use a light background ... change everything that's got a dark background").
Appends ONE override <style id="ktowner-light"> to each owner/admin page: it re-points the page's own colour variables (--bg, --card, --ink ...) to the site's light palette
and fixes the few hard-coded dark colours (top strip, sign-in pill, form fields). Idempotent (replaces its own block). Colours only: no script, text or data is touched.
Run from the repo root. The pages in .github/db-task/mac are put live by Shane's Mac deploy scripts; the site pages deploy with the website."""
import os, re
FILES = ['.github/db-task/mac/kt-crm.html', '.github/db-task/mac/key-leads.html', '.github/db-task/mac/key-advertisers.html', '.github/db-task/mac/key-room.html',
         '.github/db-task/mac/lvr-points-admin.html', '.github/db-task/mac/lvr-coupons-admin.html', '.github/db-task/mac/lvr-invoice.html',
         'sites/key-technologies/key-pageviews.html', 'sites/key-technologies/key-content-studio.html']
CSS = '''<style id="ktowner-light">
:root{--bg:#f4f8fd!important;--bg-2:#ffffff!important;--card:#ffffff!important;--line:#d6e2f2!important;--ink:#0b1b4d!important;--ink-dim:#46598a!important;--key-light:#0a6fb8!important;--key-blue:#0a6fb8!important;--good:#0a6fb8;color-scheme:light;}
html,body{background:#f4f8fd!important;color:#0b1b4d!important;}
#pin-screen{background:#f4f8fd!important;}
.pin-logo{color:#0a6fb8!important;}
#hnav{background:#ffffff!important;border-bottom:1px solid #d6e2f2;}
#hnav .hn-btn{border-color:#cbdaf0!important;background:#fff!important;color:#0b1b4d!important;}
input,select,textarea{background:#ffffff!important;color:#0b1b4d!important;border-color:#c9d9f1!important;}
input::placeholder,textarea::placeholder{color:#8a9bbd!important;}
button,.btn{border-color:#cbdaf0;}
header{background:#ffffff!important;border-bottom-color:#d6e2f2!important;}
table th{color:#46598a!important;}table td,table th{border-color:#dbe6f6!important;}
dialog,.modal,.sheet{background:#ffffff!important;color:#0b1b4d!important;}
dialog::backdrop{background:rgba(8,20,50,.45)!important;}
button[style*="2147482000"]{background:#ffffff!important;color:#0b1b4d!important;border-color:#9cb7dc!important;box-shadow:0 2px 10px rgba(20,60,140,.18)!important;}
div[style*="2147482500"]{background:rgba(8,20,50,.45)!important;}
div[style*="2147482500"] > form{background:#ffffff!important;color:#0b1b4d!important;border-color:#d6e2f2!important;box-shadow:0 20px 50px rgba(10,30,80,.25);}
div[style*="2147482500"] > form p:not(#oaMsg),div[style*="2147482500"] > form label{color:#46598a!important;}
div[style*="2147482500"] > form #oaMsg[style*="9fb3c8"]{color:#46598a!important;}
div[style*="2147482500"] > form #oaNo{color:#0b1b4d!important;border-color:#9cb7dc!important;}
</style>'''
STUDIO = '''<style id="ktowner-light">
:root{--bg:#f4f8fd!important;--bg2:#ffffff!important;--card:#ffffff!important;--card2:#eef4fc!important;--line:#d6e2f2!important;--ink:#0b1b4d!important;--dim:#46598a!important;--blue:#0a6fb8!important;--blue2:#0a8de6!important;--good:#0a7a4a!important;--warn:#a85f00!important;--bad:#b3302a!important;
--s-idea:#5d6f8a;--s-script:#6b57d6;--s-made:#0a6fb8;--s-rev:#a85f00;--s-sched:#c2570f;--s-posted:#0a7a4a;color-scheme:light;}
html,body{background:#f4f8fd!important;color:#0b1b4d!important;}
header.top{background:rgba(255,255,255,.95)!important;}
nav.tabs{background:rgba(255,255,255,.97)!important;border-top:1px solid #d6e2f2!important;}
nav.tabs button[aria-selected=true]{background:rgba(10,111,184,.1)!important;}
input,select,textarea,.chip,.pl,.out{background:#ffffff!important;color:#0b1b4d!important;border-color:#c9d9f1!important;}
.pf{background:#eef4fc!important;}
.wk i{background:#d6e2f2!important;}
.ring .tr{stroke:#d6e2f2!important;}
dialog{background:#ffffff!important;color:#0b1b4d!important;}
dialog::backdrop{background:rgba(8,20,50,.45)!important;}
</style>'''
n = 0
for p in FILES:
    if not os.path.exists(p):
        print('missing', p); continue
    t = open(p, encoding='utf-8').read()
    new = re.sub(r'<style id="ktowner-light">.*?</style>', '', t, flags=re.S)
    if '</head>' not in new:
        print('no </head>', p); continue
    new = new.replace('</head>', (STUDIO if p.endswith('key-content-studio.html') else CSS) + '</head>', 1)
    if new != t:
        open(p, 'w', encoding='utf-8').write(new); n += 1
print('owner light applied to', n, 'pages')
