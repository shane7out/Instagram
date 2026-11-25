// KEYPADMATCH01 v2 (Shane, 2026-11-25: "always make it the one on the left, make it blue, no white"): (1) take the "Johnny Mac's" chip off the PIN page;
// (2) REMOVE the light-keypad block if an earlier run put it there, so the LVR PIN keypad is the blue round one again. The LVR keypad itself is not changed.
// (3) OWNERPIN01: swaps the owner sign-in code (the key at the bottom of the PIN page) for the version with the blue PIN pad, so the owner unlock takes the PIN instead of an email and password.
// (4) DMRESTORE01: the restaurant DM goes back to the ORIGINAL wording (the long, friendly version), WITHOUT the introduction paragraph at the top; the signature keeps "Creator of @lasvegas_restaurants" and the contact email (read from the live message, never stored in this file); the cell number stays out.
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

// (4) the restaurant DM
if (/DMRESTORE01/.test(s)) console.log('DMRESTORE01 already present, skipping');
else {
  const reShort = /  \/\/ DMSHORT01[^\n]*\n  return 'Hi ' \+ n \+ '!\\n\\n' \+[\s\S]*?'Shane\\n' \+\n    '[^']+';/;
  const reOrig = /  return 'Hi ' \+ n \+ ',\\n\\n' \+\n    'My name is Shane Christensen[\s\S]*?'Cell: \([0-9]{3}\) [0-9]{3}-[0-9]{4}';/;
  const m = s.match(reShort) || s.match(reOrig);
  if (!m) console.log('DMRESTORE01: the restaurant message was not found in the expected shape - left as it is');
  else {
    const em = m[0].match(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/);
    if (!em) console.log('DMRESTORE01: no contact email found in the current message - left as it is');
    else {
      const L = [
        "  // DMRESTORE01 (2026-11-25): the original restaurant message, without the introduction paragraph; contact email kept, cell number left out",
        "  return 'Hi ' + n + ',\\n\\n' +",
        "    'We have been following ' + n + ' and love what you are doing. We would love the ' +",
        "    'opportunity to work together to help grow your presence and bring even more hungry ' +",
        "    'customers through your doors.\\n\\n' +",
        "    'We offer reposting, features, and promotional campaigns tailored specifically for ' +",
        "    'Las Vegas restaurants like yours. Our engaged community of food lovers, locals, and ' +",
        "    'tourists are always searching for their next great dining experience.\\n\\n' +",
        "    'Would you be open to a quick conversation about how we can partner together? ' +",
        "    'We think ' + n + ' is exactly the kind of place our audience would love.\\n\\n' +",
        "    'Looking forward to hearing from you!\\n\\n' +",
        "    'Sincerely,\\n\\n' +",
        "    'Shane Christensen\\n' +",
        "    'Creator of @lasvegas_restaurants\\n' +",
        "    '" + em[0] + "';"
      ].join('\n');
      s = s.replace(m[0], () => L);
      console.log('DMRESTORE01 applied (restaurant message restored, no introduction paragraph)');
    }
  }
}
if (s !== before) fs.writeFileSync(file, s);
console.log('KEYPADMATCH01 ' + (s === before ? 'no change (nothing to remove)' : 'applied'));
