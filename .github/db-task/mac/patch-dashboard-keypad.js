// KEYPADMATCH01 v2 (Shane, 2026-11-25: "always make it the one on the left, make it blue, no white"): (1) take the "Johnny Mac's" chip off the PIN page;
// (2) REMOVE the light-keypad block if an earlier run put it there, so the LVR PIN keypad is the blue round one again. The LVR keypad itself is not changed.
// (3) OWNERPIN01: swaps the owner sign-in code (the key at the bottom of the PIN page) for the version with the blue PIN pad, so the owner unlock takes the PIN instead of an email and password.
// (4) DMRESTORE02 (replaces DMRESTORE01 if that was already applied): the restaurant DM goes back to the ORIGINAL wording (the long, friendly version), WITHOUT the introduction paragraph at the top; the signature keeps "Creator of @lasvegas_restaurants" and the contact email (read from the live message, never stored in this file); the cell number stays out.
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
const REPLY = (process.env.REPLY_EMAIL || '').trim();
if (REPLY && !/^[^\s@'"\\<>]+@[^\s@'"\\<>]+\.[^\s@'"\\<>]+$/.test(REPLY)) { console.error('DMRESTORE02: REPLY_EMAIL does not look like an email address - nothing changed'); process.exit(4); }
if (/DMRESTORE02/.test(s)) {
  if (!REPLY) console.log('DMRESTORE02 already present, skipping');
  else {
    const re = /(DMRESTORE02[\s\S]*?'Creator of @lasvegas_restaurants\\n' \+\n    ')[^']+(';)/;
    if (re.test(s)) { s = s.replace(re, (m, a, b) => a + REPLY + b); console.log('DMRESTORE02: contact email updated'); }
  }
}
else {
  const reShort = /  \/\/ DMSHORT01[^\n]*\n  return 'Hi ' \+ n \+ '!\\n\\n' \+[\s\S]*?'Shane\\n' \+\n    '[^']+';/;
  const reOrig = /  return 'Hi ' \+ n \+ ',\\n\\n' \+\n    'My name is Shane Christensen[\s\S]*?'Cell: \([0-9]{3}\) [0-9]{3}-[0-9]{4}';/;
  const reRestored = /  \/\/ DMRESTORE01[^\n]*\n  return 'Hi ' \+ n \+ ',\\n\\n' \+[\s\S]*?'Creator of @lasvegas_restaurants\\n' \+\n    '[^']+';/;
  const m = s.match(reRestored) || s.match(reShort) || s.match(reOrig);
  if (!m) console.log('DMRESTORE01: the restaurant message was not found in the expected shape - left as it is');
  else {
    const em = REPLY ? [REPLY] : m[0].match(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/);
    if (!em) console.log('DMRESTORE01: no contact email found in the current message - left as it is');
    else {
      const L = [
        "  // DMRESTORE02 (2026-11-25): the original restaurant message, without the introduction paragraph and without any claim that we follow them; contact email kept, cell number left out",
        "  return 'Hi ' + n + ',\\n\\n' +",
        "    'We would love the opportunity to work together to help grow your presence and bring even more hungry ' +",
        "    'customers through your doors.\\n\\n' +",
        "    'We offer reposting, features, and promotional campaigns tailored specifically for ' +",
        "    'Las Vegas restaurants like yours. Our engaged community of food lovers, locals, and ' +",
        "    'tourists are always searching for their next great dining experience.\\n\\n' +",
        "    'We think ' + n + ' is exactly the kind of place our audience would love, and we would love to work with you.\\n\\n' +",
        "    'If you are interested, just reply with your phone number and we will contact you.\\n\\n' +",
        "    'Looking forward to hearing from you!\\n\\n' +",
        "    'Sincerely,\\n\\n' +",
        "    'Shane Christensen\\n' +",
        "    'Creator of @lasvegas_restaurants\\n' +",
        "    '" + em[0] + "';"
      ].join('\n');
      s = s.replace(m[0], () => L);
      console.log('DMRESTORE02 applied (restaurant message restored, no introduction paragraph, no claim that we follow them)');
    }
  }
}
// (5) DMRESTORE03 (Shane, 2026-11-26): the restaurant DM ends with the name and "Creator of @lasvegas_restaurants" only - no email address
{
  const reTail = /(DMRESTORE02[\s\S]*?'Creator of @lasvegas_restaurants)\\n' \+\n    '[^']+';/;
  if (reTail.test(s)) { s = s.replace(reTail, (m, a) => a + "';"); console.log('DMRESTORE03: email address removed from the end of the restaurant message'); }
  else console.log('DMRESTORE03: restaurant message already ends without an email (or was not found)');
}
// (6) DMRESTORE04 (Shane, 2026-11-26): "send me a message back with your phone number, and I will contact you" (no ASAP)
{
  const reAsk = /('We think ' \+ n \+ ' is exactly the kind of place our audience would love\.\\n\\n' \+\n)(    'Looking forward to hearing from you!)/;
  if (/send me a message back with your phone number|just reply with your phone number/.test(s)) console.log('DMRESTORE04: contact line already in the restaurant message');
  else if (reAsk.test(s)) { s = s.replace(reAsk, (m, a1, a2) => a1 + "    'If you are interested, just send me a message back with your phone number, and I will contact you.\\n\\n' +\n" + a2); console.log('DMRESTORE04: contact line added to the restaurant message'); }
  else console.log('DMRESTORE04: restaurant message not found in the expected shape - left as it is');
}
// (6b) DMRESTORE05 (Shane, 2026-11-27): "I don't want to put the word quick... there's nothing to be quick... Don't say DM, just reply." The restaurant message no longer asks for "a quick conversation";
// it says we would love to work with them and asks them to just reply with their phone number. Upgrades a page that already has the 2026-11-25/26 wording; a fresh build already has the new wording.
{
  const re5 = /    'Would you be open to a quick conversation about how we can partner together\? ' \+\n    'We think ' \+ n \+ ' is exactly the kind of place our audience would love\.\\n\\n' \+\n(?:    'If you are interested, just send me a message back with your phone number, and I will contact you\.\\n\\n' \+\n)?/;
  if (re5.test(s)) {
    s = s.replace(re5, () => "    'We think ' + n + ' is exactly the kind of place our audience would love, and we would love to work with you.\\n\\n' +\n    'If you are interested, just reply with your phone number and we will contact you.\\n\\n' +\n");
    console.log('DMRESTORE05: the restaurant message no longer says "quick conversation"; it now asks them to just reply');
  } else console.log('DMRESTORE05: restaurant message already has the newest wording (or was not found)');
}
// (6c) DMRESTORE06 (Shane, 2026-11-27: "no such thing as quick conversation"): the golf-experiences email gets the same treatment as the restaurant message.
{
  const oldG = 'Would you be open to a quick conversation about a partnership?';
  const newG = 'We would love to work with you on a partnership. If you are interested, just reply and we will take it from there.';
  if (s.includes(oldG)) { s = s.split(oldG).join(newG); console.log('DMRESTORE06: the golf email no longer says "quick conversation"'); }
  else console.log('DMRESTORE06: golf email already has the newest wording (or was not found)');
}
// (7) the follow-up DM: same signature as the first message, no email address and no cell number (Shane, 2026-11-26)
{
  const reF = /('Creator of @lasvegas_restaurants)\\n' \+\s*\n\s*'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\\n' \+\s*\n\s*'Cell: \([0-9]{3}\) [0-9]{3}-[0-9]{4}';/g;
  const hit = (s.match(reF) || []).length;
  if (hit) { s = s.replace(reF, (m, a1) => a1 + "';"); console.log('DMFOLLOW02: email address and cell number removed from ' + hit + ' message(s)'); }
  else console.log('DMFOLLOW02: no follow-up message with an email or cell number found (nothing to remove)');
}
if (s !== before) fs.writeFileSync(file, s);
console.log('KEYPADMATCH01 ' + (s === before ? 'no change (nothing to remove)' : 'applied'));
