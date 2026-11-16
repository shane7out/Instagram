// Shorter restaurant DM (Shane, 2026-11-16: "tighten that message up, don't introduce myself at the very beginning; keep the contact details, leave out my phone number").
// Replaces ONLY the restaurant message in _buildOutreachMsg(name) of the LIVE dashboard. The company (SNE) branch, the advertiser, golf and model emails are not touched.
// The email address is READ from the existing message in the live page (so it is never written into this public file); the cell number is not carried over.
// Marker-fenced and idempotent. Does not change any PIN, any data or any rule.
const fs = require('fs');
const file = process.argv[2];
if (!file) { console.error('usage: node patch-dashboard-dm.js <index.html>'); process.exit(1); }
let s = fs.readFileSync(file, 'utf8');
if (/DMSHORT01/.test(s)) { console.log('DMSHORT01 already present, skipping'); process.exit(0); }
fs.writeFileSync(file + '.bak-dmshort', s);
const start = s.indexOf("  return 'Hi ' + n + ',\\n\\n' +\n    'My name is Shane Christensen");
if (start < 0 || s.indexOf("  return 'Hi ' + n + ',\\n\\n' +\n    'My name is Shane Christensen", start + 10) >= 0) { console.error('DMSHORT01: old restaurant message not found exactly once (the live page differs) - nothing changed'); process.exit(1); }
const endMarker = "'Cell: (949) 899-3059';";
const end = s.indexOf(endMarker, start);
if (end < 0 || end - start > 2500) { console.error('DMSHORT01: end of the old message not found - nothing changed'); process.exit(1); }
const old = s.slice(start, end + endMarker.length);
const em = old.match(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/);
if (!em) { console.error('DMSHORT01: no email address in the old message - nothing changed (so no contact line could be kept)'); process.exit(1); }
const replacement =
  "  // DMSHORT01 (2026-11-16): shorter restaurant DM, no introduction up front, email kept, phone left out\n" +
  "  return 'Hi ' + n + '!\\n\\n' +\n" +
  "    'We have been following ' + n + ' and love what you are doing. We run @lasvegas_restaurants and reach a big audience of Las Vegas locals and tourists looking for their next great meal.\\n\\n' +\n" +
  "    'We do reposts, features and promo campaigns for restaurants like yours. Open to a quick chat about working together?\\n\\n' +\n" +
  "    'Shane\\n' +\n" +
  "    '" + em[0] + "';";
s = s.slice(0, start) + replacement + s.slice(end + endMarker.length);
fs.writeFileSync(file, s);
console.log('DMSHORT01 applied (old message ' + old.length + ' characters)');
