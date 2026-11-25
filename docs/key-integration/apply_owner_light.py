#!/usr/bin/env python3
"""Light look for Shane's private owner pages (Shane, 2026-11-10: "I want to use a light background ... change everything that's got a dark background").
Appends ONE override <style id="ktowner-light"> to each owner/admin page: it re-points the page's own colour variables (--bg, --card, --ink ...) to the site's light palette
and fixes the few hard-coded dark colours (top strip, sign-in pill, form fields). Idempotent (replaces its own block). Colours only: no script, text or data is touched.
Run from the repo root. The pages in .github/db-task/mac are put live by Shane's Mac deploy scripts; the site pages deploy with the website."""
import os, re
FILES = ['.github/db-task/mac/kt-crm.html', '.github/db-task/mac/kt-outreach.html', '.github/db-task/mac/key-leads.html', '.github/db-task/mac/key-advertisers.html', '.github/db-task/mac/key-room.html',
         '.github/db-task/mac/lvr-points-admin.html', '.github/db-task/mac/lvr-coupons-admin.html', '.github/db-task/mac/lvr-invoice.html',
         ]
# Shane, 2026-11-17: the two owner pages that are part of the public website (Owner report, Content Studio) use the site's dark look with the bright blue,
# like the rest of keytechnologies.si; the light override is REMOVED from them. (2026-11-25: the Mac-deployed owner tools now get the LVR PIN blue instead of the light look: "I do not want to ever see white again".)
SITE_DARK = ['sites/key-technologies/key-pageviews.html', 'sites/key-technologies/key-content-studio.html']
CSS = '''<style id="ktowner-light">
/* OWNERBLUE01 (Shane, 2026-11-25: "I don't want to ever see white again... make everything the same color as the LVR pin"). Same id as the old light block so the deploy script swaps it. */
:root{--bg:#07142b!important;--bg-2:#0e2347!important;--card:rgba(255,255,255,.07)!important;--line:rgba(255,255,255,.18)!important;--ink:#ffffff!important;--ink-dim:rgba(255,255,255,.66)!important;--key-light:#90CAF9!important;--key-blue:#1493FF!important;--good:#4fd1a5;color-scheme:dark;}
html,body{background:radial-gradient(ellipse 90% 70% at 50% 30%,rgba(14,72,168,.55) 0%,transparent 65%),radial-gradient(ellipse 60% 52% at 15% 80%,rgba(0,105,230,.30) 0%,transparent 58%),radial-gradient(ellipse 55% 48% at 85% 18%,rgba(36,12,140,.35) 0%,transparent 56%),radial-gradient(ellipse 45% 38% at 68% 68%,rgba(0,180,255,.16) 0%,transparent 50%),#050b16!important;background-attachment:fixed!important;color:#ffffff!important;}
#pin-screen{background:radial-gradient(ellipse 90% 70% at 50% 30%,rgba(14,72,168,.55) 0%,transparent 65%),radial-gradient(ellipse 60% 52% at 15% 80%,rgba(0,105,230,.30) 0%,transparent 58%),radial-gradient(ellipse 55% 48% at 85% 18%,rgba(36,12,140,.35) 0%,transparent 56%),radial-gradient(ellipse 45% 38% at 68% 68%,rgba(0,180,255,.16) 0%,transparent 50%),#050b16!important;}
.pin-logo{color:#90CAF9!important;}
.pin-sub{color:rgba(255,255,255,.55)!important;}
.pin-dots{gap:20px!important;margin-bottom:44px!important;}
.pin-dot{width:14px!important;height:14px!important;border-radius:50%!important;border:1.5px solid rgba(255,255,255,.6)!important;background:transparent!important;box-shadow:none!important;}
.pin-dot.filled{background:#ffffff!important;border-color:#ffffff!important;transform:scale(1.05);}
.pin-dot.error{background:#FF453A!important;border-color:#FF453A!important;}
.pin-grid{display:grid!important;grid-template-columns:repeat(3,78px)!important;gap:14px 20px!important;width:auto!important;}
.pin-key{width:78px!important;height:78px!important;border-radius:50%!important;background:rgba(255,255,255,.175)!important;backdrop-filter:blur(20px) saturate(180%)!important;-webkit-backdrop-filter:blur(20px) saturate(180%)!important;border:none!important;box-shadow:none!important;color:#ffffff!important;font-size:34px!important;font-weight:300!important;line-height:1!important;padding:0!important;}
.pin-key:active{background:rgba(255,255,255,.58)!important;color:#000!important;}
.pin-key.empty{background:transparent!important;backdrop-filter:none!important;-webkit-backdrop-filter:none!important;}
.pin-msg{color:#FF453A!important;}
#hnav{background:rgba(5,11,22,.85)!important;border-bottom:1px solid rgba(255,255,255,.14)!important;}
#hnav .hn-btn{border-color:rgba(255,255,255,.25)!important;background:rgba(255,255,255,.08)!important;color:#ffffff!important;}
input,select,textarea{background:rgba(255,255,255,.08)!important;color:#ffffff!important;border-color:rgba(255,255,255,.22)!important;}
input::placeholder,textarea::placeholder{color:rgba(255,255,255,.45)!important;}
option{background:#0e2347!important;color:#ffffff!important;}
button,.btn{border-color:rgba(255,255,255,.25);}
header{background:rgba(5,11,22,.6)!important;border-bottom-color:rgba(255,255,255,.14)!important;}
table th{color:rgba(255,255,255,.66)!important;}table td,table th{border-color:rgba(255,255,255,.12)!important;}
.tabs button[aria-selected=true]{color:#fff!important;}
#gate button{color:#fff!important;}
#gateMsg{color:#ffcf8a!important;}
dialog,.modal,.sheet{background:#0e2347!important;color:#ffffff!important;}
dialog::backdrop{background:rgba(0,0,0,.6)!important;}
button[style*="2147482000"]{background:rgba(13,29,51,.92)!important;color:#ffffff!important;border-color:rgba(255,255,255,.35)!important;}
div[style*="2147482500"]{background:rgba(0,0,0,.65)!important;}
div[style*="2147482500"] > form{background:#0e2347!important;color:#ffffff!important;border-color:rgba(255,255,255,.2)!important;}
div[style*="2147482500"] > form p:not(#oaMsg),div[style*="2147482500"] > form label{color:rgba(255,255,255,.66)!important;}
div[style*="2147482500"] > form #oaNo{color:#ffffff!important;border-color:rgba(255,255,255,.3)!important;}
</style>'''
STUDIO = '''<style id="ktowner-light">
:root{--bg:#f4f8fd!important;--bg2:#ffffff!important;--card:#ffffff!important;--card2:#eef4fc!important;--line:#d6e2f2!important;--ink:#0b1b4d!important;--dim:#46598a!important;--blue:#0a6fb8!important;--blue2:#0a6fb8!important;--good:#0a7a4a!important;--warn:#a85f00!important;--bad:#b3302a!important;
--s-idea:#5d6f8a;--s-script:#6b57d6;--s-made:#0a6fb8;--s-rev:#a85f00;--s-sched:#c2570f;--s-posted:#0a7a4a;color-scheme:light;}
html,body{background:#f4f8fd!important;color:#0b1b4d!important;}
header.top{background:rgba(255,255,255,.95)!important;}
nav.tabs{background:rgba(255,255,255,.97)!important;border-top:1px solid #d6e2f2!important;}
nav.tabs button[aria-selected=true]{background:rgba(10,111,184,.1)!important;}
input,select,textarea,.chip,.pl,.out{background:#ffffff!important;color:#0b1b4d!important;border-color:#c9d9f1!important;}
.badge{color:color-mix(in srgb,var(--c) 55%,#000)!important;}
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
for p in SITE_DARK:
    t = open(p, encoding='utf-8').read()
    new = re.sub(r'<style id="ktowner-light">.*?</style>', '', t, flags=re.S)
    if new != t:
        open(p, 'w', encoding='utf-8').write(new); n += 1
print('owner light applied/removed on', n, 'pages')
