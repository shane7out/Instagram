// Points the dashboard's "Key" / "Key Technologies" pill (PIN-screen link row) at the Key Tech room
// (key-room.html) instead of the old demo link, and labels it "Key Tech". Idempotent, marker-fenced
// as KEYPILL03. Never fails the deploy: if the pill is not found it says so and exits 0.
const fs = require('fs');
const file = process.argv[2];
if (!file) { console.error('usage: node patch-key-pill-to-room.js <index.html>'); process.exit(1); }
let s = fs.readFileSync(file, 'utf8');
if (/KEYPILL03/.test(s)) { console.log('KEYPILL03 already present, skipping'); process.exit(0); }
const before = s;
const variants = [
  // after patch-rename-key-pill.js (KEYPILL02): "Key" -> demo artifact link
  /(<a href=")https:\/\/claude\.ai\/artifact\/4ie6rEf6q1eSmaxNW84HGP("[^>]*>)<!-- KEYPILL02 -->Key(<\/a>)/,
  // original pill from patch-add-key-pill.js: "Key Technologies" -> GitHub Pages link
  /(<a href=")https:\/\/shane7out\.github\.io\/Instagram\/("[^>]*>)(?:<!--[^>]*-->)?Key Technologies(<\/a>)/,
  // after the domain went live: "Key Technologies" -> keytechnologies.si
  /(<a href=")https:\/\/keytechnologies\.si\/?("[^>]*>)(?:<!--[^>]*-->)?Key(?: Technologies)?(<\/a>)/
];
let hit = false;
for (const re of variants) {
  if (re.test(s)) { s = s.replace(re, '$1/key-room.html$2<!-- KEYPILL03 -->&#128273; Key Tech$3'); hit = true; break; }
}
if (!hit) { console.log('KEYPILL03: Key pill not found (nothing changed). The Key Tech pill inside the dashboard still opens the room.'); process.exit(0); }
fs.writeFileSync(file + '.bak-keypill03', before);
fs.writeFileSync(file, s);
console.log('KEYPILL03 applied: the Key pill now opens the Key Tech room');
