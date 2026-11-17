// FACEID01: puts a Face ID / Touch ID key on the LVR dashboard PIN pad (bottom-left, where the empty key is) and switches the dashboard's own
// Face ID code back on. The PIN still works exactly as before; Face ID is a second way in. Usage: node patch-dashboard-faceid.js <live index.html>
// All-or-nothing: every anchor must be found exactly once or NOTHING is written. Idempotent (marker FACEID01). Backup is written once.
const fs = require('fs');
const f = process.argv[2];
let s = fs.readFileSync(f, 'utf8');
if (s.indexOf('FACEID01') >= 0) { console.log('FACEID01 already applied - nothing to do.'); process.exit(0); }
const orig = s;
const bad = m => { console.error('FACEID01: ' + m + ' - nothing changed.'); process.exit(1); };

// 1) stop wiping registered Face ID credentials on every load
const wipe = /[ \t]*try \{ localStorage\.removeItem\('lv_biometric_cred_v2'\); \} catch\(e\) \{\}[^\n]*\n/;
if (!wipe.test(s)) bad('wipe line not found');
s = s.replace(wipe, '');

// 2) Face ID available again (https + WebAuthn)
const avail = /[ \t]*return false; \/\/ FACE LOGIN REMOVED 2026-07-17 \(owner\)[^\n]*\n/;
if (!avail.test(s)) bad('_bioAvailable early return not found');
s = s.replace(avail, '');

// 3) the pad key
const emptyKey = /<div class="pin-key" style="visibility:hidden;pointer-events:none;"><\/div><!-- face login removed 2026-07-17[^>]*-->/;
if (!emptyKey.test(s)) bad('empty pad key not found');
const FACE = '<svg class="face-ico" viewBox="0 0 32 32" width="34" height="34" aria-hidden="true" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M4 11V8a4 4 0 0 1 4-4h3M21 4h3a4 4 0 0 1 4 4v3M28 21v3a4 4 0 0 1-4 4h-3M11 28H8a4 4 0 0 1-4-4v-3"/><path d="M12 12.5v2.2M20 12.5v2.2M16 12.5v5.2h-1.7M12 21.2c2.4 2 5.6 2 8 0"/><path class="face-scan" d="M7 9h18" stroke-width="1.4"/></svg>';
s = s.replace(emptyKey, '<button class="pin-key faceKey off" id="pin-face-btn" aria-label="Face ID or Touch ID" onclick="pinBio()" ontouchstart="event.preventDefault();pinBio();this.classList.add(\'pressed\')" ontouchend="this.classList.remove(\'pressed\')" ontouchcancel="this.classList.remove(\'pressed\')">' + FACE + '</button><!-- FACEID01 -->');

// 4) the key's behaviour
const pinBio = /function pinBio\(\) \{[\s\S]*?\n\}\n(?=\s*\/\/ Toggle between bio view and PIN view)/;
if (!pinBio.test(s)) bad('pinBio() not found');
s = s.replace(pinBio, `function pinBio() {
  var msg = document.getElementById('pin-msg'), btn = document.getElementById('pin-face-btn');
  function say(t) { if (msg) { msg.textContent = t; setTimeout(function(){ if (msg) msg.textContent = ''; }, 2600); } }
  if (!_bioAvailable()) { say('Face ID is not available in this browser. Use your PIN.'); return; }
  if (!_bioRegistered()) { say('Enter your PIN once to turn on Face ID.'); return; }
  if (btn) btn.classList.add('busy');
  _bioAuthenticate().then(function(ok) {
    if (btn) btn.classList.remove('busy');
    if (ok) _bioUnlock(); else say('Face ID did not work. Use your PIN.');
  }).catch(function() { if (btn) btn.classList.remove('busy'); });
}
`);

// 5) repaint the key whenever the pad is shown
const show = 'function _bioShowState() {';
if (s.split(show).length !== 2) bad('_bioShowState not found exactly once');
s = s.replace(show, show + "\n  try { if (typeof _faceIdPaint === 'function') _faceIdPaint(); } catch(e) {}");

// 6) style + the small script that lights the key
const CSS = `<!--FACEID-START--><style id="faceidStyle">
/* FACEID01: Face ID key on the PIN pad */
#pin-screen .faceKey{position:relative;color:#fff;} #pin-screen .faceKey .face-ico{display:block;margin:0 auto;} #pin-screen .faceKey .face-scan{opacity:0;}
#pin-screen .faceKey.off{opacity:.5;}
#pin-screen .faceKey.ready{background:rgba(20,147,255,.30)!important;box-shadow:0 0 0 1.5px rgba(20,147,255,.65),0 0 22px rgba(20,147,255,.45)!important;animation:fidpulse 2.6s ease-in-out infinite;}
#pin-screen .faceKey.ready .face-scan{opacity:.95;animation:fidscan 2s ease-in-out infinite;}
#pin-screen .faceKey.busy{opacity:.6;}
@keyframes fidscan{0%,100%{transform:translateY(0)}50%{transform:translateY(14px)}}
@keyframes fidpulse{0%,100%{box-shadow:0 0 0 1.5px rgba(20,147,255,.65),0 0 14px rgba(20,147,255,.30)}50%{box-shadow:0 0 0 1.5px rgba(20,147,255,.9),0 0 28px rgba(20,147,255,.6)}}
@media (prefers-reduced-motion:reduce){#pin-screen .faceKey.ready,#pin-screen .faceKey.ready .face-scan{animation:none!important;}}
</style><!--FACEID-END-->`;
const JS = `<!--FACEID-JS-START--><script>/* FACEID01 */
function _faceIdPaint() {
  var b = document.getElementById('pin-face-btn'); if (!b) return;
  var ok = false; try { ok = !!(_bioAvailable() && _bioRegistered()); } catch (e) {}
  b.classList.toggle('ready', ok); b.classList.toggle('off', !ok);
}
(function () {
  var o = window._bioRegister;
  if (typeof o === 'function') window._bioRegister = function () { return o.apply(this, arguments).then(function (ok) { try { _faceIdPaint(); } catch (e) {} return ok; }); };
  setTimeout(_faceIdPaint, 300); setTimeout(_faceIdPaint, 1500);
})();
</script><!--FACEID-JS-END-->`;
if (s.indexOf('</head>') < 0 || s.lastIndexOf('</body>') < 0) bad('head/body end not found');
s = s.replace('</head>', CSS + '</head>');
const k = s.lastIndexOf('</body>'); s = s.slice(0, k) + JS + s.slice(k);
if (s === orig) bad('no change produced');
if (!fs.existsSync(f + '.bak-faceid')) fs.writeFileSync(f + '.bak-faceid', orig);
fs.writeFileSync(f, s);
console.log('FACEID01 applied (' + (s.length - orig.length) + ' bytes added).');
