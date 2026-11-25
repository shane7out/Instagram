// KEYPADMATCH01 (Shane, 2026-11-25): (1) take the "Johnny Mac's" chip off the PIN page; (2) make the PIN keypad look like the Key Tech Room keypad
// (light page, white rounded keys, thin dots). CSS ONLY: no PIN, no PIN logic, no data and no rule is touched. Safe to run twice.
// usage: node patch-dashboard-keypad.js index.html
const fs = require('fs');
const file = process.argv[2];
if (!file) { console.error('usage: node patch-dashboard-keypad.js index.html'); process.exit(1); }
let s = fs.readFileSync(file, 'utf8');
const before = s;

// 1) the Johnny Mac's chip (marked block first; else the single link). The site page itself (johnny-macs.html) is left where it is.
let removed = 0;
s = s.replace(/\s*<!-- JOHNNYMACS-START -->[\s\S]*?<!-- JOHNNYMACS-END -->/g, () => { removed++; return ''; });
s = s.replace(/\s*<a href="\/johnny-macs\.html"[\s\S]*?<\/a>/g, () => { removed++; return ''; });
console.log('Johnny Mac\'s chip blocks removed: ' + removed + ' (left on the page: ' + (s.match(/johnny-macs\.html/g) || []).length + ')');

// 2) the keypad look (same numbers as the Key Tech Room keypad: 14px dots, 230px grid, 58px keys, 12px corners, white keys, blue fill)
const CSS = `<!--KEYPADMATCH-START--><style id="keypadMatchStyle">
/* KEYPADMATCH01: the LVR keypad now looks exactly like the Key Tech Room keypad */
#pin-screen{background:#f4f8fd!important;}
#pin-screen #pin-version{color:#46598a!important;}
#pin-screen .pin-dots{display:flex!important;gap:12px!important;margin-bottom:26px!important;}
#pin-screen .pin-dot{width:14px!important;height:14px!important;border-radius:50%!important;border:2px solid #d6e2f2!important;background:transparent!important;box-shadow:none!important;transform:none!important;}
#pin-screen .pin-dot.filled{background:#0a6fb8!important;border-color:#0a6fb8!important;}
#pin-screen .pin-dot.error{background:#ff6b6b!important;border-color:#ff6b6b!important;}
#pin-screen .pin-grid{display:grid!important;grid-template-columns:repeat(3,1fr)!important;gap:10px!important;width:230px!important;}
#pin-screen .pin-key{width:auto!important;height:58px!important;border-radius:12px!important;background:#ffffff!important;border:1px solid #d6e2f2!important;color:#0b1b4d!important;font-size:20px!important;font-weight:700!important;box-shadow:none!important;backdrop-filter:none!important;-webkit-backdrop-filter:none!important;}
#pin-screen .pin-key:active,#pin-screen .pin-key.pressed{background:#d6e2f2!important;color:#0b1b4d!important;}
#pin-screen .pin-key .pkl{display:none!important;}
#pin-screen .pin-key,#pin-screen .pin-key *:not(svg):not(path){font-size:20px!important;font-weight:700!important;line-height:1.2!important;}
#pin-screen .pin-key.del{font-size:20px!important;font-weight:700!important;color:#0b1b4d!important;}
#pin-screen .pin-key.del svg,#pin-screen .pin-key.del svg *{stroke:#0b1b4d!important;}
#pin-screen .pin-msg{color:#ff6b6b!important;font-size:13px!important;font-weight:600!important;margin-top:16px!important;}
/* the site chips under the pad, in the same light look */
#pin-screen a[target="_blank"]{color:#46598a!important;background:#ffffff!important;border:1px solid #cbdaf0!important;}
#pin-screen #bio-offer{background:#ffffff!important;border-color:#d6e2f2!important;}
#pin-screen #bio-offer div{color:#0b1b4d!important;}
#ownerAuthBtn{background:#ffffff!important;border:1px solid #cbdaf0!important;}
</style><!--KEYPADMATCH-END-->`;
if (/<!--KEYPADMATCH-START-->[\s\S]*?<!--KEYPADMATCH-END-->/.test(s)) s = s.replace(/<!--KEYPADMATCH-START-->[\s\S]*?<!--KEYPADMATCH-END-->/, () => CSS);
else if (s.indexOf('</head>') >= 0) s = s.replace('</head>', () => CSS + '\n</head>');
else { console.error('KEYPADMATCH01: no </head> found - nothing changed'); process.exit(3); }
fs.writeFileSync(file, s);
console.log('KEYPADMATCH01 ' + (s === before ? 'no change' : 'applied'));
