#!/bin/bash
# Show what the owner's email domain is used for in the live dashboard page.
# The address itself is masked - this repo's logs are public.
set -e
node <<'NODE'
const https = require('https');
const get = url => new Promise(res => https.get(url, { timeout: 20000 }, r => { let d=''; r.on('data', c => d += c); r.on('end', () => res(d)); }).on('error', () => res('')));
const mask = s => s.replace(/[A-Za-z0-9._%+-]+@lasvegasrestaurants\.net/gi, '[OWNER-EMAIL]');
(async () => {
  const b = await get('https://lvr-data-a60c1.web.app/');
  const re = /lasvegasrestaurants\.net/gi; let m, n = 0;
  while ((m = re.exec(b))) { n++; console.log('--- mention', n, '(char', m.index + ') ---'); console.log(mask(b.slice(Math.max(0, m.index - 220), m.index + 120)).replace(/\s+/g, ' ')); }
  console.log('=== mailto contexts (emails masked) ===');
  const re2 = /mailto:/gi; let k = 0;
  while ((m = re2.exec(b)) && k < 9) { k++; console.log(k + ')', mask(b.slice(Math.max(0, m.index - 60), m.index + 70)).replace(/\s+/g, ' ')); }
})();
NODE
