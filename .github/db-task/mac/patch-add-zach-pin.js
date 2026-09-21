// Adds a new full co-editor PIN (223344) for Zach — same live restaurant
// database access as the owner (minus owner-only controls), same DM/email
// tooling as the existing friend co-editor PIN (232323). Idempotent:
// marker-fenced, safe to re-run.
//
// NOTE: this shares the SAME coeditor_dm node as the 232323 friend PIN —
// the dashboard only has two DM pools (co-editor vs guest10), not one per
// PIN. If someone else is actively using 232323, Zach's DM/email activity
// will be visible to and mixed with theirs. That's an existing limitation
// of the app, not something this patch changes.
const fs = require('fs');
const file = process.argv[2];
if (!file) { console.error('usage: node patch-add-zach-pin.js <index.html>'); process.exit(1); }
let s = fs.readFileSync(file, 'utf8');
const before = s;
fs.writeFileSync(file + '.bak-zachpin', before);

// ZACHPIN01: declare the new PIN constant right after FRIEND_PIN
if (!/ZACHPIN01/.test(s)) {
  const anchor = "var FRIEND_PIN = '232323'; // co-editor re-enabled 2026-07-17 with a fresh PIN (12312 retired 7/09)";
  if (!s.includes(anchor)) { console.error('ZACHPIN01: anchor not found'); process.exit(1); }
  s = s.replace(anchor, anchor + "\nvar ZACH_PIN = '223344'; // ZACHPIN01: full co-editor PIN for Zach, added " + new Date().toISOString().slice(0,10));
  console.log('ZACHPIN01 applied');
} else console.log('ZACHPIN01 already present, skipping');

// ZACHPIN02: login branch, mirrors FRIEND_PIN's co-editor branch exactly
if (!/ZACHPIN02/.test(s)) {
  const anchor = `  if (_pinEntry === FRIEND_PIN) {
    // Co-editor re-enabled 2026-07-17 (owner request) under new PIN 232323. Same live data as the
    // owner; private DM tracking via the coeditor_dm node; owner-only controls hidden by _applyCoEditorUI.
    _coEditor = true;
    try { sessionStorage.setItem('lv_coeditor','1'); sessionStorage.removeItem('lv_inflonly'); } catch(e) {}
    _applyCoEditorDmKey();
    _pinAttempts = 0; _pinEntry = ''; _pinUpdateDots(false);
    _bioUnlock();
    _coeDmLoad();
    return;
  }`;
  if (!s.includes(anchor)) { console.error('ZACHPIN02: anchor not found'); process.exit(1); }
  const insert = `
  if (_pinEntry === ZACH_PIN) {
    // ZACHPIN02: Zach's full co-editor PIN (223344), added ` + new Date().toISOString().slice(0,10) + `.
    // Same behavior as FRIEND_PIN (232323) — full live data, shared coeditor_dm node.
    _coEditor = true;
    try { sessionStorage.setItem('lv_coeditor','1'); sessionStorage.removeItem('lv_inflonly'); } catch(e) {}
    _applyCoEditorDmKey();
    _pinAttempts = 0; _pinEntry = ''; _pinUpdateDots(false);
    _bioUnlock();
    _coeDmLoad();
    return;
  }`;
  s = s.replace(anchor, anchor + insert);
  console.log('ZACHPIN02 applied');
} else console.log('ZACHPIN02 already present, skipping');

// ZACHPIN03: reserve the PIN so the owner can't accidentally reassign it
if (!/ZACHPIN03/.test(s)) {
  const anchor = "  if (nw === INFL_PIN)      { msg.textContent = 'Cannot use that PIN — it is reserved.'; return; }";
  if (!s.includes(anchor)) { console.error('ZACHPIN03: anchor not found'); process.exit(1); }
  s = s.replace(anchor, anchor + "\n  if (nw === ZACH_PIN)      { msg.textContent = 'Cannot use that PIN — it is reserved.'; return; } // ZACHPIN03");
  console.log('ZACHPIN03 applied');
} else console.log('ZACHPIN03 already present, skipping');

if (s === before) { console.log('no changes made'); process.exit(0); }
fs.writeFileSync(file, s);
console.log('patch-add-zach-pin.js: wrote ' + file + ' (' + s.length + ' bytes, was ' + before.length + ')');
