// Dashboard PIN page: turn the big "Owner sign-in" button (it covered the "Dating" chip bottom right) into a small key icon centered at the bottom.
//  OWNERBTN01: adds a style block (after the owner sign-in snippet) that shrinks the button to a 36px key icon, bottom center, out of the way of the chips.
//              The button is a key when signed out and a padlock when signed in; it still opens the same sign-in / unlock / menu. Pure styling.
//  Also refreshes the owner sign-in snippet to the current version (adds an accessible name to the button).
// Marker-fenced and idempotent. Does not change any PIN, any data or any rule.
const fs = require('fs');
const file = process.argv[2], snipFile = process.argv[3];
if (!file || !snipFile) { console.error('usage: node patch-dashboard-owner-btn.js <index.html> <owner-auth.snippet.html>'); process.exit(1); }
let s = fs.readFileSync(file, 'utf8');
const hadStyle = /<!--OWNERBTN-START-->/.test(s);
if (!hadStyle) fs.writeFileSync(file + '.bak-ownerbtn', s);
const snip = fs.readFileSync(snipFile, 'utf8').trim();
if (!/<!--OWNER-AUTH-START-->[\s\S]*<!--OWNER-AUTH-END-->/.test(snip)) { console.error('OWNERBTN01: snippet file has no markers'); process.exit(1); }
if (!/<!--OWNER-AUTH-START-->[\s\S]*?<!--OWNER-AUTH-END-->/.test(s)) { console.error('OWNERBTN01: the owner sign-in is not on this page yet (run deploy-dashboard-owner-auth.sh first) - nothing changed'); process.exit(1); }
s = s.replace(/<!--OWNER-AUTH-START-->[\s\S]*?<!--OWNER-AUTH-END-->/, () => snip);
const css = `<!--OWNERBTN-START--><style id="ownerBtnStyle">
/* OWNERBTN01: small key at the bottom center instead of a big button bottom right (it covered the last chip on the PIN page) */
#ownerAuthBtn{font-size:0!important;line-height:0!important;padding:0!important;width:38px!important;height:38px!important;min-width:38px!important;left:50%!important;right:auto!important;bottom:6px!important;transform:translateX(-50%)!important;display:flex!important;align-items:center!important;justify-content:center!important;border-radius:50%!important;background:rgba(13,29,51,.78)!important;border:1px solid rgba(255,255,255,.35)!important;opacity:.85;}
#ownerAuthBtn::before{content:"\\1F511";font-size:19px;line-height:1;}
#ownerAuthBtn[style*="0f5d34"]::before{content:"\\1F512";}
/* leave room under the chips so the key never sits on a chip (also when more chips are added) */
div[style*="max-width:360px"][style*="flex-wrap"]{margin-bottom:60px!important;}
/* short windows: the chips already reach the bottom edge, so the key goes to the top-right corner instead */
@media (max-height:760px){#ownerAuthBtn{left:auto!important;right:10px!important;bottom:auto!important;top:10px!important;transform:none!important;}}
#ownerAuthBtn:hover,#ownerAuthBtn:focus-visible{opacity:1;border-color:#fff!important;}
</style><!--OWNERBTN-END-->`;
if (hadStyle) s = s.replace(/<!--OWNERBTN-START-->[\s\S]*?<!--OWNERBTN-END-->/, () => css);
else s = s.replace('<!--OWNER-AUTH-END-->', () => '<!--OWNER-AUTH-END-->\n' + css);
fs.writeFileSync(file, s);
console.log('OWNERBTN01 ' + (hadStyle ? 'refreshed' : 'applied'));
