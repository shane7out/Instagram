#!/usr/bin/env python3
# Puts the owner sign-in snippet into the owner tools (idempotent). Run from the repo root:
#   python3 .github/db-task/owner-auth/apply-owner-auth.py
import re, sys
SNIP = open('.github/db-task/owner-auth/owner-auth.snippet.html').read().strip()
FILES = ['.github/db-task/mac/lvr-points-admin.html', '.github/db-task/mac/key-room.html']
for f in FILES:
    s = open(f).read()
    if '<!--OWNER-AUTH-START-->' in s:
        s = re.sub(r'<!--OWNER-AUTH-START-->.*?<!--OWNER-AUTH-END-->', lambda m: SNIP, s, flags=re.S)
    else:
        assert s.count('<head>') == 1, f
        s = s.replace('<head>', '<head>\n' + SNIP, 1)
    open(f, 'w').write(s)
    print('ok', f)
