// Idempotent, marker-fenced patch to the live LVR dashboard
// (lvr-data-a60c1.web.app). Adds two things, both additive:
//
// 1. A "lv_owner_session" timestamp written to localStorage the moment the
//    OWNER PIN (dynamic, default 137900) succeeds — not the co-editor/
//    friend/guest/influencer PINs, owner only. This is a same-origin,
//    shared-across-tabs flag every other lvr-data-a60c1.web.app page can
//    check to recognize "this browser is already logged in as the owner"
//    without asking for another PIN. Valid for 24h from the stamp.
//
// 2. A "🔑 Key Tech" pill in the main dashboard view's tab row (next to
//    the existing Teams pill), opening the new key-room.html hub page in
//    a new tab.
//
// Together with the matching bypass check added to key-leads.html,
// kt-crm.html, key-advertisers.html, lvr-coupons-admin.html, and
// key-room.html itself, this is what makes "log in once with your master
// PIN, then every tool just opens" actually work — per Shane's explicit
// request not to have to remember another PIN for each new tool.
//
// Run against a local copy of the live dashboard HTML. Safe to re-run —
// every block below is marker-guarded.
const fs = require('fs');

const FILE = process.argv[2] || 'index.html';
let html = fs.readFileSync(FILE, 'utf8');
let changed = false;

function applyOnce(markerStart, patchFn) {
  if (html.indexOf(markerStart) !== -1) {
    console.log('already applied: ' + markerStart);
    return;
  }
  const before = html;
  html = patchFn(html);
  if (html === before) {
    console.log('ANCHOR NOT FOUND for: ' + markerStart);
    return;
  }
  changed = true;
  console.log('applied: ' + markerStart);
}

// ---------------------------------------------------------------------------
// 1) Stamp lv_owner_session on owner-PIN success. Anchored right at the top
//    of the owner-PIN branch (not near _bioUnlock()/the wrong-PIN "} else {"
//    - that region is also touched by patch-dashboard-keytech.js, so this
//    uses an independent, earlier anchor to stay safe regardless of patch
//    order).
// ---------------------------------------------------------------------------
applyOnce('/* KEYROOM-SESSION-v1 */', function (s) {
  const anchor =
    '    // Owner PIN. (Co-editor PIN is 232323 — handled in its own branch above.)\n' +
    '    _coEditor = false;';
  if (s.indexOf(anchor) === -1) return s;
  const insert =
    '    // Owner PIN. (Co-editor PIN is 232323 — handled in its own branch above.)\n' +
    '    /* KEYROOM-SESSION-v1 */\n' +
    '    try { localStorage.setItem(\'lv_owner_session\', String(Date.now())); } catch(e) {}\n' +
    '    /* /KEYROOM-SESSION-v1 */\n' +
    '    _coEditor = false;';
  return s.replace(anchor, insert);
});

// ---------------------------------------------------------------------------
// 2) "Key Tech" pill next to the Teams pill in the main dashboard header.
// ---------------------------------------------------------------------------
applyOnce('<!-- KEYROOM-PILL-v1 -->', function (s) {
  const anchor =
    '<button id="teams-tab-btn" onclick="window.open(\'https://lvr-data-a60c1.web.app/lvr-teams.html\',\'_blank\')" style="background:#F97316;color:#fff;border:none;border-radius:7px;padding:5px 9px;font-size:12px;font-weight:700;cursor:pointer;white-space:nowrap;">🍽 Teams</button>';
  if (s.indexOf(anchor) === -1) return s;
  const insert =
    '<!-- KEYROOM-PILL-v1 -->' +
    '<button id="keyroom-tab-btn" onclick="window.open(\'https://lvr-data-a60c1.web.app/key-room.html\',\'_blank\')" style="background:#0F766E;color:#fff;border:none;border-radius:7px;padding:5px 9px;font-size:12px;font-weight:700;cursor:pointer;white-space:nowrap;">🔑 Key Tech</button>' +
    '<!-- /KEYROOM-PILL-v1 -->';
  return s.replace(anchor, anchor + insert);
});

// ---------------------------------------------------------------------------
// 3) "Member Link" box in the expanded Rewards member card - lets Shane
//    copy a member's personal account link (my-account.html?t=<token> on
//    keytechnologies.si) to text/DM to them. This is literally the answer
//    to "I'm gonna also need a demo for them to see what they see" - that
//    link IS what they see. Falls back to generating a token on the spot
//    for any legacy member that somehow doesn't have one yet.
// ---------------------------------------------------------------------------
applyOnce('/* KEYROOM-MEMBERLINK-v1 */', function (s) {
  const anchor =
    "          '</div>' +\n" +
    "          // token award section\n" +
    "          '<div style=\"background:rgba(255,214,0,0.07);border:1.5px solid rgba(255,214,0,0.25);border-radius:12px;padding:16px;\">' +";
  if (s.indexOf(anchor) === -1) return s;
  const insert =
    "          '</div>' +\n" +
    "          /* KEYROOM-MEMBERLINK-v1 */\n" +
    "          '<div style=\"background:rgba(94,181,255,0.07);border:1.5px solid rgba(94,181,255,0.3);border-radius:12px;padding:14px 16px;margin-bottom:14px;\">' +\n" +
    "            '<div style=\"font-size:11px;font-weight:800;letter-spacing:0.15em;color:#7EB8FF;text-transform:uppercase;margin-bottom:8px;\">Member Link</div>' +\n" +
    "            '<div style=\"font-size:12px;color:rgba(255,255,255,0.5);margin-bottom:10px;line-height:1.5;\">This is what they see — their balance and what they can redeem. No password.</div>' +\n" +
    "            (m.token ?\n" +
    "              '<button onclick=\"event.stopPropagation();_rewardsCopyLink(\\'' + key + '\\')\" style=\"background:#168fff;color:#fff;border:none;border-radius:9px;padding:10px 16px;font-size:13px;font-weight:700;cursor:pointer;\">Copy Their Link</button>' :\n" +
    "              '<button onclick=\"event.stopPropagation();_rewardsMakeLink(\\'' + key + '\\')\" style=\"background:#168fff;color:#fff;border:none;border-radius:9px;padding:10px 16px;font-size:13px;font-weight:700;cursor:pointer;\">Generate Link</button>'\n" +
    "            ) +\n" +
    "            '<span id=\"rwd-link-msg-' + key + '\" style=\"margin-left:10px;font-size:12px;color:#4ADE80;\"></span>' +\n" +
    "          '</div>' +\n" +
    "          /* /KEYROOM-MEMBERLINK-v1 */\n" +
    "          // token award section\n" +
    "          '<div style=\"background:rgba(255,214,0,0.07);border:1.5px solid rgba(255,214,0,0.25);border-radius:12px;padding:16px;\">' +";
  return s.replace(anchor, insert);
});

applyOnce('/* KEYROOM-MEMBERLINK-FNS-v1 */', function (s) {
  const anchor = 'function _rewardsAdd(key, delta) {';
  if (s.indexOf(anchor) === -1) return s;
  const insert =
    '/* KEYROOM-MEMBERLINK-FNS-v1 */\n' +
    "function _rewardsAcctUrl(token) { return 'https://keytechnologies.si/my-account.html?t=' + token; }\n" +
    'function _rewardsCopyLink(key) {\n' +
    '  var m = _rewardsFbData[key]; if (!m || !m.token) return;\n' +
    '  var url = _rewardsAcctUrl(m.token);\n' +
    "  var msg = document.getElementById('rwd-link-msg-' + key);\n" +
    '  if (navigator.clipboard) { navigator.clipboard.writeText(url).then(function(){ if (msg) msg.textContent = "Copied!"; }); }\n' +
    '  else if (msg) { msg.textContent = url; }\n' +
    '}\n' +
    'function _rewardsMakeLink(key) {\n' +
    '  var m = _rewardsFbData[key]; if (!m) return;\n' +
    "  if (typeof isDemo !== 'undefined' && isDemo) { showDMToast('View only in demo mode'); return; }\n" +
    "  if (typeof isFriend !== 'undefined' && isFriend) { showDMToast('Owner only'); return; }\n" +
    '  var bytes = new Uint8Array(16);\n' +
    '  (window.crypto || window.msCrypto).getRandomValues(bytes);\n' +
    "  var token = Array.prototype.map.call(bytes, function(b){ return b.toString(16).padStart(2, '0'); }).join('');\n" +
    "  var msg = document.getElementById('rwd-link-msg-' + key);\n" +
    "  if (msg) msg.textContent = 'Generating…';\n" +
    '  fetch(_rwdFbBase() + key + \'.json\', { method: \'PATCH\', headers: {\'Content-Type\':\'application/json\'}, body: JSON.stringify({ token: token }) })\n' +
    "    .then(function(r){ if (!r.ok) throw new Error('HTTP ' + r.status); m.token = token; _rewardsRender(); })\n" +
    "    .catch(function(){ if (msg) msg.textContent = 'Failed — try again'; });\n" +
    '}\n' +
    anchor;
  return s.replace(anchor, insert);
});

// ---------------------------------------------------------------------------
// 4) Wording: this program is just called "points" (not "tokens") everywhere
//    a member or the owner reads it. Label-only; no data fields change.
// ---------------------------------------------------------------------------
applyOnce('/* KEYROOM-POINTS-LABELS-v1 */', function (s) {
  var out = s;
  var pairs = [
    ["'<div style=\"font-size:11px;font-weight:800;letter-spacing:0.2em;color:#FFD600;text-transform:uppercase;margin-bottom:13px;\">Award Tokens</div>' +",
     "/* KEYROOM-POINTS-LABELS-v1 */ '<div style=\"font-size:11px;font-weight:800;letter-spacing:0.2em;color:#FFD600;text-transform:uppercase;margin-bottom:13px;\">Award Points</div>' +"],
    ['text-transform:uppercase;margin-bottom:3px;">Tokens</div>', 'text-transform:uppercase;margin-bottom:3px;">Points</div>'],
    ['title="Say a number to add tokens"', 'title="Say a number to add points"']
  ];
  for (var i = 0; i < pairs.length; i++) {
    if (out.indexOf(pairs[i][0]) === -1) return s; // all-or-nothing
    out = out.replace(pairs[i][0], pairs[i][1]);
  }
  return out;
});

if (changed) {
  fs.writeFileSync(FILE, html);
  console.log('WROTE ' + FILE);
} else {
  console.log('NO CHANGES (already applied or anchors not found)');
}
