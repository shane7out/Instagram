// KEYPADMATCH01 v2 (Shane, 2026-11-25: "always make it the one on the left, make it blue, no white"): (1) take the "Johnny Mac's" chip off the PIN page;
// (2) REMOVE the light-keypad block if an earlier run put it there, so the LVR PIN keypad is the blue round one again. The LVR keypad itself is not changed.
// (3) OWNERPIN01: swaps the owner sign-in code (the key at the bottom of the PIN page) for the version with the blue PIN pad, so the owner unlock takes the PIN instead of an email and password.
// Nothing else (no PIN number, PIN logic, data or rule) is touched. Safe to run twice.   usage: node patch-dashboard-keypad.js index.html [owner-auth.snippet.html]
const fs = require('fs');
const file = process.argv[2];
if (!file) { console.error('usage: node patch-dashboard-keypad.js index.html'); process.exit(1); }
let s = fs.readFileSync(file, 'utf8');
const before = s;
const snipFile = process.argv[3];
let removed = 0;
s = s.replace(/\s*<!-- JOHNNYMACS-START -->[\s\S]*?<!-- JOHNNYMACS-END -->/g, () => { removed++; return ''; });
s = s.replace(/\s*<a href="\/johnny-macs\.html"[\s\S]*?<\/a>/g, () => { removed++; return ''; });
console.log('Johnny Mac\'s chip blocks removed: ' + removed + ' (left on the page: ' + (s.match(/johnny-macs\.html/g) || []).length + ')');
let lightGone = 0;
s = s.replace(/<!--KEYPADMATCH-START-->[\s\S]*?<!--KEYPADMATCH-END-->\n?/g, () => { lightGone++; return ''; });
console.log('light keypad block removed: ' + lightGone);
if (snipFile) {
  const snip = fs.readFileSync(snipFile, 'utf8').trim();
  if (!/<!--OWNER-AUTH-START-->[\s\S]*<!--OWNER-AUTH-END-->/.test(snip) || snip.indexOf('OWNERPIN01') < 0) { console.error('OWNERPIN01: the snippet file is not the PIN version - nothing changed'); process.exit(4); }
  if (!/<!--OWNER-AUTH-START-->[\s\S]*?<!--OWNER-AUTH-END-->/.test(s)) { console.error('OWNERPIN01: the owner sign-in is not on the dashboard yet (run deploy-dashboard-owner-auth.sh first) - nothing changed'); process.exit(5); }
  s = s.replace(/<!--OWNER-AUTH-START-->[\s\S]*?<!--OWNER-AUTH-END-->/, () => snip);
  console.log('owner sign-in swapped for the PIN pad version');
}
if (s !== before) fs.writeFileSync(file, s);
console.log('KEYPADMATCH01 ' + (s === before ? 'no change (nothing to remove)' : 'applied'));
