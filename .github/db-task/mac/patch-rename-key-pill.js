// Renames the "Key Technologies" pill (added by patch-add-key-pill.js,
// KEYPILL01) to just "Key", and points it at the live demo artifact link
// instead of the GitHub Pages URL (which still 404s - GitHub Pages hasn't
// been turned on yet, domain still being set up). Idempotent, marker-fenced
// as KEYPILL02. Once GitHub Pages/DNS is actually live, swap the href back
// to https://keytechnologies.si/ with a follow-up patch - this is a stopgap.
const fs = require('fs');
const file = process.argv[2];
if (!file) { console.error('usage: node patch-rename-key-pill.js <index.html>'); process.exit(1); }
let s = fs.readFileSync(file, 'utf8');
const before = s;
fs.writeFileSync(file + '.bak-keyrename', before);

if (!/KEYPILL02/.test(s)) {
  const re = /(<a href=")https:\/\/shane7out\.github\.io\/Instagram\/("[^>]*>)Key Technologies(<\/a>)/;
  const m = s.match(re);
  if (!m) { console.error('KEYPILL02: original Key Technologies pill not found (already renamed, or KEYPILL01 never applied?)'); process.exit(1); }
  s = s.replace(re, '$1https://claude.ai/artifact/4ie6rEf6q1eSmaxNW84HGP$2<!-- KEYPILL02 -->Key$3');
  console.log('KEYPILL02 applied: renamed pill to "Key", pointed at demo link');
} else console.log('KEYPILL02 already present, skipping');

if (s === before) { console.log('no changes made'); process.exit(0); }
fs.writeFileSync(file, s);
console.log('patch-rename-key-pill.js: wrote ' + file + ' (' + s.length + ' bytes, was ' + before.length + ')');
