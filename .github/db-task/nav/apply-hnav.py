#!/usr/bin/env python3
"""Put the Back / Forward arrows on every page. Safe to re-run: the block between the HNAV markers is replaced.
Run from the repo root:  python3 .github/db-task/nav/apply-hnav.py
HOME = where Back goes when a page was opened in a fresh tab (nothing to go back to)."""
import re
SNIP = open('.github/db-task/nav/hnav.snippet.html').read()
MAC = '.github/db-task/mac/'
SITE = 'sites/key-technologies/'
ROOM = 'https://lvr-data-a60c1.web.app/key-room.html'
PAGES = {
  MAC + 'key-room.html': '',
  MAC + 'key-leads.html': ROOM, MAC + 'kt-crm.html': ROOM, MAC + 'key-advertisers.html': ROOM,
  MAC + 'lvr-coupons-admin.html': ROOM, MAC + 'lvr-points-admin.html': ROOM, MAC + 'lvr-invoice.html': ROOM,
  MAC + 'lvr-restaurant-portal.html': '', MAC + 'lvr-rewards.html': '', MAC + 'lvr-coupon.html': '', MAC + 'lvr-wallet.html': '',
  SITE + 'my-account.html': 'index.html', SITE + 'menu.html': 'index.html', SITE + 'rewards.html': 'index.html',
}
for path, home in PAGES.items():
    s = open(path).read()
    block = ("<script>window.HNAV_HOME=%r;</script>\n" % home).replace("'", '"') + SNIP if home else SNIP
    s = re.sub(r'\n?<!--HNAV-START-->.*?<!--HNAV-END-->\n?', '\n', s, flags=re.S)
    s = re.sub(r'<script>window\.HNAV_HOME=[^<]*</script>\n?', '', s)
    assert s.count('</body>') == 1, path
    s = s.replace('</body>', block + '</body>')
    open(path, 'w').write(s)
    print('ok', path, 'home=' + (home or '-'))
