// Adds a "Key Technologies" pill to the dashboard's PIN screen link row,
// matching the exact style of the existing Deals/CC/Private Chef/Badges
// pills. Links to the Key Technologies site. Idempotent, marker-fenced.
// (Brand renamed KEY -> Key Technology -> Key Technologies, all on
// 2026-10-04, intended domain keytechnologies.si (NOT yet confirmed
// registered - see docs/CLAUDE.md on the claude/key-website branch) -
// this patch was updated to match before ever being deployed, so the
// live dashboard never showed either earlier name.)
//
// NOTE: the URL below (https://shane7out.github.io/Instagram/) only works
// once GitHub Pages is turned on for the claude/key-website branch (Settings
// -> Pages -> branch claude/key-website -> folder /docs). That's a GitHub
// website toggle, not a Mac/Firebase step - can be done from a phone. Until
// it's on, this pill 404s; the moment it's on, the pill just works with no
// further dashboard deploy needed.
const fs = require('fs');
const file = process.argv[2];
if (!file) { console.error('usage: node patch-add-key-pill.js <index.html>'); process.exit(1); }
let s = fs.readFileSync(file, 'utf8');
const before = s;
fs.writeFileSync(file + '.bak-keypill', before);

if (!/KEYPILL01/.test(s)) {
  const anchor = `  <!-- Deals link (private Craigslist deal-finder: cars + land) -->
  <a href="https://classiccarsforsale-co.web.app" target="_blank" rel="noopener"
     style="display:inline-block;text-decoration:none;
            color:rgba(255,255,255,0.55);font-size:14px;letter-spacing:0.01em;
            border:1px solid rgba(255,255,255,0.25);border-radius:10px;
            padding:8px 20px;">Deals</a>`;
  if (!s.includes(anchor)) { console.error('KEYPILL01: anchor not found'); process.exit(1); }
  const insert = `
  <!-- Key Technologies link (AI consulting site, intended domain
       keytechnologies.si, not yet confirmed registered) — KEYPILL01,
       added ` + new Date().toISOString().slice(0,10) + `. URL only resolves once GitHub Pages is
       enabled for claude/key-website (folder /docs) - update to
       https://keytechnologies.si/ once that domain is registered and
       attached there. -->
  <a href="https://shane7out.github.io/Instagram/" target="_blank" rel="noopener"
     style="display:inline-block;text-decoration:none;
            color:rgba(255,255,255,0.55);font-size:14px;letter-spacing:0.01em;
            border:1px solid rgba(255,255,255,0.25);border-radius:10px;
            padding:8px 20px;">Key Technologies</a>`;
  s = s.replace(anchor, anchor + insert);
  console.log('KEYPILL01 applied');
} else console.log('KEYPILL01 already present, skipping');

if (s === before) { console.log('no changes made'); process.exit(0); }
fs.writeFileSync(file, s);
console.log('patch-add-key-pill.js: wrote ' + file + ' (' + s.length + ' bytes, was ' + before.length + ')');
