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

if (changed) {
  fs.writeFileSync(FILE, html);
  console.log('WROTE ' + FILE);
} else {
  console.log('NO CHANGES (already applied or anchors not found)');
}
