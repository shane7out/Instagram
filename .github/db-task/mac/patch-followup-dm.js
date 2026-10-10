// Idempotent, marker-fenced patch: adds an automatic "Needs Follow-Up" queue to
// the restaurant dashboard — any restaurant DM'd FOLLOWUP_AFTER_DAYS ago with no
// 👍/👎 response gets a distinct follow-up message + a "Needs Follow-Up" stat
// badge/filter, mirroring the existing DM flow (copy message -> open Instagram ->
// stamp sent). Does NOT touch the existing manual "Follow Up" bookmark button —
// that's a separate, unrelated feature and is left completely alone.
// Usage: node patch-followup-dm.js <path-to-dashboard-html>
'use strict';
const fs = require('fs');
const file = process.argv[2];
if (!file) { console.log('usage: node patch-followup-dm.js <file>'); process.exit(1); }
let src = fs.readFileSync(file, 'utf8');

if (src.indexOf('openFollowupDM') !== -1) {
  console.log('patch-followup-dm: already applied (found openFollowupDM) - skipping, no changes made');
  process.exit(0);
}

let editsApplied = 0;
function edit(name, anchor, build) {
  const count = src.split(anchor).length - 1;
  if (count !== 1) {
    console.log('FAIL [' + name + ']: anchor occurs ' + count + ' time(s), expected exactly 1');
    process.exit(1);
  }
  src = src.replace(anchor, build(anchor));
  editsApplied++;
  console.log('ok   [' + name + ']');
}

// 1) LS key constant
edit('ls-const',
  "var LS_FOLLOWUP       = 'lv_outreach_followup_v1';",
  (a) => a + "\nvar LS_FOLLOWUPSENT   = 'lv_outreach_followupsent_v1';"
);

// 2) load/save functions
edit('load-save-fns',
  "function loadFollowup()     { try { return JSON.parse(localStorage.getItem(LS_FOLLOWUP))      || {}; } catch(e) { return {}; } }\nfunction saveFollowup()     { try { localStorage.setItem(LS_FOLLOWUP, JSON.stringify(followupMap)); } catch(e) {} lsSaved(); }",
  (a) => a + "\nfunction loadFollowupSent() { try { return JSON.parse(localStorage.getItem(LS_FOLLOWUPSENT)) || {}; } catch(e) { return {}; } }\nfunction saveFollowupSent() { try { localStorage.setItem(LS_FOLLOWUPSENT, JSON.stringify(followupSentMap)); } catch(e) {} lsSaved(); }"
);

// 3) var + init + constant + qualification function
edit('var-init-and-logic',
  "var followupMap     = loadFollowup();",
  (a) => a + "\nvar followupSentMap = loadFollowupSent();\n" +
    "var FOLLOWUP_AFTER_DAYS = 4; // days after a DM with no response before \"Needs Follow-Up\" lights up\n" +
    "function _needsFollowup(num) {\n" +
    "  var d = dmMap[num];\n" +
    "  if (!d || d === 'pending') return false;\n" +
    "  if (followupSentMap[num]) return false;\n" +
    "  if (interestedMap[num] || notInterestedMap[num]) return false;\n" +
    "  var t = Date.parse(d);\n" +
    "  if (!t || isNaN(t)) return false;\n" +
    "  return (Date.now() - t) >= FOLLOWUP_AFTER_DAYS * 86400000;\n" +
    "}"
);

// 4) follow-up message template (right after the first-DM template)
edit('followup-message-template',
  "'Shane@LasVegasRestaurants.net\\n' +\n    'Cell: (949) 899-3059';\n}",
  (a) => a + "\n\nfunction _buildFollowupMsg(name) {\n" +
    "  var n = name || 'Team';\n" +
    "  return 'Hi ' + n + ',\\n\\n' +\n" +
    "    'Just wanted to follow up on my message from a few days ago! I\\'m Shane, the creator of ' +\n" +
    "    '@lasvegas_restaurants \\u2014 we would love to help put ' + n + ' in front of more hungry ' +\n" +
    "    'locals and tourists here in Vegas.\\n\\n' +\n" +
    "    'No worries at all if now isn\\'t the right time \\u2014 just let me know if you would like to ' +\n" +
    "    'chat, or if you\\'d rather I check back another time.\\n\\n' +\n" +
    "    'Thanks so much!\\n\\n' +\n" +
    "    'Shane Christensen\\n' +\n" +
    "    'Creator of @lasvegas_restaurants\\n' +\n" +
    "    'Shane@LasVegasRestaurants.net\\n' +\n" +
    "    'Cell: (949) 899-3059';\n" +
    "}"
);

// 5) copy/open/unmark functions (right after openDM() closes)
edit('followup-dm-actions',
  "if (typeof showDMToast==='function') showDMToast(\"✓ Timestamped — tap ✓ Flag DM'd to file it\");\n}\n\nfunction openEmail(num) {",
  (a) => "if (typeof showDMToast==='function') showDMToast(\"✓ Timestamped — tap ✓ Flag DM'd to file it\");\n}\n\n" +
    "function copyFollowupDM(num) {\n" +
    "  var r = getR(num);\n" +
    "  if (!r) return;\n" +
    "  if (badIGMap[num]) { showDMToast('Bad IG flagged — fix handle before DMing'); return; }\n" +
    "  var msg = _buildFollowupMsg(r.name);\n" +
    "  if (navigator.clipboard && navigator.clipboard.writeText) {\n" +
    "    navigator.clipboard.writeText(msg).then(function() { showDMToast('Follow-up copied!'); }).catch(function() { showDMToast('Copy failed — try again'); });\n" +
    "  } else {\n" +
    "    var ta = document.createElement('textarea');\n" +
    "    ta.value = msg; ta.style.position = 'fixed'; ta.style.opacity = '0';\n" +
    "    document.body.appendChild(ta); ta.focus(); ta.select();\n" +
    "    var _copyOk = false;\n" +
    "    try { _copyOk = document.execCommand('copy'); } catch(e) {}\n" +
    "    document.body.removeChild(ta);\n" +
    "    showDMToast(_copyOk ? 'Follow-up copied!' : 'Copy failed — try again');\n" +
    "  }\n" +
    "}\n" +
    "// Mirrors openDM(): copies the follow-up message, opens the IG thread, and stamps\n" +
    "// followupSentMap immediately (lower-stakes than the first DM, so no separate\n" +
    "// draft/flag step — \"Undo\" below covers the \"didn't actually send\" case).\n" +
    "function openFollowupDM(num) {\n" +
    "  var r = getR(num);\n" +
    "  if (!r) return;\n" +
    "  if (badIGMap[num]) { showDMToast('Bad IG flagged — fix the handle first'); return; }\n" +
    "  if (!r.igHandle) { showDMToast('No Instagram handle — use Edit IG to add one'); return; }\n" +
    "  if (!(typeof isFriend!=='undefined' && isFriend)) { try { copyFollowupDM(num); } catch(e) {} }\n" +
    "  followupSentMap[num] = nowStr();\n" +
    "  saveFollowupSent();\n" +
    "  _fbPatch('followupsent/'+num, followupSentMap[num]);\n" +
    "  fbSave();\n" +
    "  window.open('https://ig.me/m/' + encodeURIComponent(r.igHandle), '_blank');\n" +
    "  _dashDirty = true;\n" +
    "  try { dashRefreshCard(num); dashUpdateStats(); } catch(e) {}\n" +
    "  showDMToast('Follow-up copied — opening @' + r.igHandle);\n" +
    "}\n" +
    "function unmarkFollowupSent(num) {\n" +
    "  if (!confirm(\"Remove the follow-up stamp?\\n(Use this if it didn't actually send.)\")) return;\n" +
    "  delete followupSentMap[num];\n" +
    "  saveFollowupSent();\n" +
    "  _fbPatch('followupsent/'+num, null);\n" +
    "  fbSave();\n" +
    "  _dashDirty = true;\n" +
    "  dashRefreshCard(num); dashUpdateStats();\n" +
    "}\n\n" +
    "function openEmail(num) {"
);

// 6) card button — appears right after the "✓ DM'd <date>" stamp
edit('card-button',
  "title=\"Tap to remove the DM stamp\">✓ DM\\'d '+_esc(dmDate)+'</button>'",
  (a) => a + "+((followupSentMap[r.num])?'<button onclick=\"unmarkFollowupSent('+r.num+')\" class=\"btn btn-dm marked\" style=\"background:#00695C;\" title=\"Tap to remove the follow-up stamp\">✓ Followed up '+_esc(followupSentMap[r.num])+'</button>':(_needsFollowup(r.num)?'<button onclick=\"openFollowupDM('+r.num+')\" class=\"btn btn-dm\" style=\"background:#00695C;\">🔁 Follow-Up DM</button>':''))"
);

// 7) stats badge HTML
edit('badge-html',
  "<div class=\"badge b-followup\" onclick=\"dashSetFilter('followup')\">Follow Up: <span id=\"s-followup\">0</span></div>",
  (a) => a + "\n    <div class=\"badge b-needsfollowup\" onclick=\"dashSetFilter('needsfollowup')\" style=\"background:#00695C;color:#fff;\">🔁 Needs Follow-Up: <span id=\"s-needsfollowup\">0</span></div>"
);

// 8) _getStatEls cache entry
edit('stat-els',
  "follow:  document.getElementById('s-followup'),",
  (a) => a + "\n    needsfollowup: document.getElementById('s-needsfollowup'),"
);

// 9) dashUpdateStats: var + count + assignment
edit('stats-var-list',
  "notes=0,followup=0,problem=0,foodtrade=0",
  (a) => "notes=0,followup=0,needsfollowup=0,problem=0,foodtrade=0"
);
edit('stats-count-line',
  "if(followupMap[r.num])followup++;",
  (a) => a + "\n    if(_needsFollowup(r.num))needsfollowup++;"
);
edit('stats-assign-line',
  "el.notes.textContent=notes; el.follow.textContent=followup; el.problem.textContent=problem;",
  (a) => a + " if(el.needsfollowup)el.needsfollowup.textContent=needsfollowup;"
);

// 10) dashSetFilter's badge map + _refilter case
edit('bmap-filter',
  "notes:'.b-notes',followup:'.b-followup',problem:'.b-problem'",
  (a) => "notes:'.b-notes',followup:'.b-followup',needsfollowup:'.b-needsfollowup',problem:'.b-problem'"
);
edit('refilter-case',
  "if(f==='followup' &&!followupMap[r.num])       continue;",
  (a) => a + "\n    if(f==='needsfollowup' &&!_needsFollowup(r.num))      continue;"
);

// 11) Firebase: payload field, fetch, merge-on-write, real-time apply
edit('fb-payload-field',
  "var _pushTs = Date.now();\n  var payload = {\n    status:        statusMap,\n    attempts:      attemptsMap,\n    dm:            dmMap,\n    badig:         badIGMap,\n    igovr:         igOverrideMap,\n    usernotes:     userNotesMap,\n    nameoverride:  nameOverrideMap,\n    followup:      followupMap,",
  (a) => a + "\n    followupsent:  followupSentMap,"
);
edit('fb-fetch-array',
  "fetch(FB_URL.replace('.json','/sunny.json'),         {cache:'no-store'}).then(function(r){ return r.ok ? r.json() : null; }).catch(function(){ return null; })\n  ]).then(function(_res){",
  (a) => "fetch(FB_URL.replace('.json','/sunny.json'),         {cache:'no-store'}).then(function(r){ return r.ok ? r.json() : null; }).catch(function(){ return null; }),\n    fetch(FB_URL.replace('.json','/followupsent.json'),  {cache:'no-store'}).then(function(r){ return r.ok ? r.json() : null; }).catch(function(){ return null; })\n  ]).then(function(_res){"
);
edit('fb-merge-flag',
  "_mergeFlag(sunnyMap, _res[18], 'sunny');",
  (a) => a + "\n      _mergeFlag(followupSentMap, _res[19], 'followupsent');"
);
edit('fb-realtime-apply',
  "{ followupMap      = rec.followup      || {}; try { localStorage.setItem(LS_FOLLOWUP,       JSON.stringify(followupMap)); } catch(e) {} }",
  (a) => a + "\n      { followupSentMap  = rec.followupsent  || {}; try { localStorage.setItem(LS_FOLLOWUPSENT,   JSON.stringify(followupSentMap)); } catch(e) {} }"
);

fs.writeFileSync(file, src);
console.log('patch-followup-dm: ' + editsApplied + ' edit(s) applied successfully');
