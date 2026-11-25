// KEYPADMATCH01 v2 (Shane, 2026-11-25: "always make it the one on the left, make it blue, no white"): (1) take the "Johnny Mac's" chip off the PIN page;
// (2) REMOVE the light-keypad block if an earlier run put it there, so the LVR PIN keypad is the blue round one again. The LVR keypad itself is not changed.
// Nothing else (no PIN, PIN logic, data or rule) is touched. Safe to run twice.   usage: node patch-dashboard-keypad.js index.html
const fs = require('fs');
const file = process.argv[2];
if (!file) { console.error('usage: node patch-dashboard-keypad.js index.html'); process.exit(1); }
let s = fs.readFileSync(file, 'utf8');
const before = s;
let removed = 0;
s = s.replace(/\s*<!-- JOHNNYMACS-START -->[\s\S]*?<!-- JOHNNYMACS-END -->/g, () => { removed++; return ''; });
s = s.replace(/\s*<a href="\/johnny-macs\.html"[\s\S]*?<\/a>/g, () => { removed++; return ''; });
console.log('Johnny Mac\'s chip blocks removed: ' + removed + ' (left on the page: ' + (s.match(/johnny-macs\.html/g) || []).length + ')');
let lightGone = 0;
s = s.replace(/<!--KEYPADMATCH-START-->[\s\S]*?<!--KEYPADMATCH-END-->\n?/g, () => { lightGone++; return ''; });
console.log('light keypad block removed: ' + lightGone);
if (s !== before) fs.writeFileSync(file, s);
console.log('KEYPADMATCH01 ' + (s === before ? 'no change (nothing to remove)' : 'applied'));
