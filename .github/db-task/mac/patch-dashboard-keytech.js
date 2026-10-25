// Idempotent, marker-fenced patch to the live LVR dashboard (lvr-data-a60c1.web.app).
// Adds three things, all additive — nothing existing is removed or altered:
//
// 1. PIN 137901 on the same login screen redirects to the new key-advertisers.html
//    tool instead of unlocking the dashboard. Owner PIN (dynamic, default 137900),
//    FRIEND_PIN, GUEST10_PIN etc. are completely untouched.
//
// 2. A "Flag for Review" button on advertiser cards, shown ONLY in friend/co-editor
//    mode. This is a NEW, separate mechanism from the existing "Problem" button —
//    checked the existing one first: _advFbPatch() deliberately no-ops for friend
//    sessions (a real, intentional guard against a co-editor writing arbitrary
//    paths into the owner's main data), so a friend's "Problem" toggle never
//    actually reaches the owner, only their own browser. This new button writes
//    directly to a dedicated dashboard/adv_flag_queue/<num> node instead, which
//    the owner reviews via #3.
//
// 3. An owner-only "Flagged N" button + review modal. Confirm sends the record to
//    Bad Records via the EXISTING advMainToNeedFixed() (already correctly
//    owner-only, already correctly removes it from every view) — no new deletion
//    logic, just reusing what's already proven. Dismiss clears the flag, record
//    stays live.
//
// Run against a local copy of the live dashboard HTML. Safe to re-run — every
// block below is marker-guarded.
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
// 1) PIN 137901 -> redirect to key-advertisers.html
// ---------------------------------------------------------------------------
applyOnce('/* KEYTECH-PIN-REDIRECT-v1 */', function (s) {
  const anchor = '  if (_pinEntry === GUEST10_PIN) {';
  const insert =
    '  /* KEYTECH-PIN-REDIRECT-v1 */\n' +
    "  if (_pinEntry === '137901') {\n" +
    "    window.location.href = 'key-advertisers.html';\n" +
    '    return;\n' +
    '  }\n' +
    '  /* /KEYTECH-PIN-REDIRECT-v1 */\n' +
    anchor;
  return s.replace(anchor, insert);
});

// ---------------------------------------------------------------------------
// 2) "Flag for Review" button on advertiser cards, friend-mode only
// ---------------------------------------------------------------------------
applyOnce('/* KEYTECH-FLAG-BTN-v1 */', function (s) {
  const anchor =
    "  btns+='<button class=\"btn btn-problem'+(advProblemMap[a.num]?' flagged':'')+'\" onclick=\"advToggleProblem('+a.num+')\">Problem</button>';\n";
  if (s.indexOf(anchor) === -1) return s;
  const insert =
    anchor +
    '  /* KEYTECH-FLAG-BTN-v1 */\n' +
    "  if(typeof isFriend!=='undefined'&&isFriend){btns+='<button class=\"btn\" style=\"background:#D84315;color:#fff;font-size:13px;padding:8px 13px;\" onclick=\"advFlagForReview('+a.num+')\">\\uD83D\\uDEA9 Flag for Review</button>';}\n" +
    '  /* /KEYTECH-FLAG-BTN-v1 */\n';
  return s.replace(anchor, insert);
});

// ---------------------------------------------------------------------------
// 3) Supporting JS: advFlagForReview, owner review modal + its functions
// ---------------------------------------------------------------------------
applyOnce('/* KEYTECH-FLAGQUEUE-JS-v1 */', function (s) {
  const anchor = 'function advShowDupesModal(){';
  if (s.indexOf(anchor) === -1) return s;
  const js =
    '/* KEYTECH-FLAGQUEUE-JS-v1 */\n' +
    'var KEYTECH_DB = "https://lvr-data-a60c1-default-rtdb.firebaseio.com";\n' +
    'function advFlagForReview(num){\n' +
    '  fetch(KEYTECH_DB+"/dashboard/adv_flag_queue/"+num+".json",{method:"PUT",headers:{"Content-Type":"application/json"},\n' +
    '    body:JSON.stringify({flaggedAt:Date.now(),flaggedBy:(typeof isFriend!=="undefined"&&isFriend)?"friend":"unknown"})}\n' +
    '  ).then(function(){ if(typeof showDMToast==="function")showDMToast("\\uD83D\\uDEA9 Flagged for review"); }).catch(function(){});\n' +
    '}\n' +
    'function advRefreshFlagQueueCount(){\n' +
    '  if(typeof isFriend!=="undefined"&&isFriend) return;\n' +
    '  fetch(KEYTECH_DB+"/dashboard/adv_flag_queue.json").then(function(r){return r.json();}).then(function(data){\n' +
    '    var n=data?Object.keys(data).length:0;\n' +
    '    var el=document.getElementById("adv-cnt-flagqueue");\n' +
    '    if(el)el.textContent=n;\n' +
    '  }).catch(function(){});\n' +
    '}\n' +
    'function advShowFlagQueueModal(){\n' +
    '  if(typeof isFriend!=="undefined"&&isFriend) return;\n' +
    '  fetch(KEYTECH_DB+"/dashboard/adv_flag_queue.json").then(function(r){return r.json();}).then(function(data){\n' +
    '    var queue=data||{};\n' +
    '    var nums=Object.keys(queue).map(function(k){return parseInt(k,10);}).filter(function(n){return !isNaN(n);});\n' +
    '    var html="";\n' +
    '    if(!nums.length){\n' +
    '      html=\'<p style="color:#90A4AE;text-align:center;padding:20px;">No flagged records waiting for review.</p>\';\n' +
    '    } else {\n' +
    '      nums.forEach(function(num){\n' +
    '        var rec = ADVERTISERS_BASE.find(function(a){return a.num===num;}) || ADVERTISERS_STAGING.find(function(a){return a.num===num;});\n' +
    '        var name = rec ? (advNameOverrideMap[rec.num]||rec.name) : ("#"+num+" (not found \\u2014 may already be removed)");\n' +
    '        var who = queue[num] && queue[num].flaggedBy ? queue[num].flaggedBy : "unknown";\n' +
    '        var when = queue[num] && queue[num].flaggedAt ? new Date(queue[num].flaggedAt).toLocaleString() : "";\n' +
    '        html+=\'<div style="background:#0d1929;border-radius:8px;padding:14px;margin-bottom:10px;">\';\n' +
    '        html+=\'<div style="color:#fff;font-weight:700;font-size:14px;">\'+_esc(name)+\'</div>\';\n' +
    '        html+=\'<div style="color:#78909C;font-size:11px;margin-bottom:8px;">#\'+num+\' &bull; flagged by \'+_esc(who)+(when?\' &bull; \'+_esc(when):"")+\'</div>\';\n' +
    '        html+=\'<div style="display:flex;gap:8px;flex-wrap:wrap;">\';\n' +
    '        html+=\'<button onclick="advFlagQueueConfirmBad(\'+num+\')" style="background:#C62828;color:#fff;border:none;border-radius:6px;padding:6px 12px;font-size:12px;cursor:pointer;">Confirm \\u2014 send to Bad Records</button>\';\n' +
    '        html+=\'<button onclick="advFlagQueueDismiss(\'+num+\')" style="background:#455A64;color:#fff;border:none;border-radius:6px;padding:6px 12px;font-size:12px;cursor:pointer;">Dismiss \\u2014 keep record</button>\';\n' +
    '        html+="</div></div>";\n' +
    '      });\n' +
    '    }\n' +
    '    document.getElementById("adv-flagqueue-content").innerHTML=html;\n' +
    '    document.getElementById("adv-flagqueue-modal").style.display="flex";\n' +
    '  }).catch(function(){});\n' +
    '}\n' +
    'function advCloseFlagQueueModal(){ document.getElementById("adv-flagqueue-modal").style.display="none"; }\n' +
    'function advFlagQueueDismiss(num){\n' +
    '  fetch(KEYTECH_DB+"/dashboard/adv_flag_queue/"+num+".json",{method:"DELETE"}).then(function(){ advShowFlagQueueModal(); advRefreshFlagQueueCount(); }).catch(function(){});\n' +
    '}\n' +
    'function advFlagQueueConfirmBad(num){\n' +
    '  if(typeof advMainToNeedFixed==="function") advMainToNeedFixed(num,true);\n' +
    '  fetch(KEYTECH_DB+"/dashboard/adv_flag_queue/"+num+".json",{method:"DELETE"}).then(function(){\n' +
    '    advShowFlagQueueModal(); advRefreshFlagQueueCount();\n' +
    '    if(typeof advRender==="function")advRender();\n' +
    '  }).catch(function(){});\n' +
    '}\n' +
    '/* /KEYTECH-FLAGQUEUE-JS-v1 */\n';
  return s.replace(anchor, js + anchor);
});

// ---------------------------------------------------------------------------
// 4) "Flagged N" button next to the existing Dupes filter button, owner-only
// ---------------------------------------------------------------------------
applyOnce('<!-- KEYTECH-FLAGQUEUE-BTN-v1 -->', function (s) {
  const anchor =
    '<button onclick="advShowDupesModal()" id="adv-filter-dupes" class="adv-fbtn" style="background:#6A1B9A;color:#fff;border:none;border-radius:6px;padding:6px 12px;font-size:12px;font-weight:700;cursor:pointer;">Dupes</button>';
  if (s.indexOf(anchor) === -1) return s;
  const insert =
    anchor +
    '<!-- KEYTECH-FLAGQUEUE-BTN-v1 -->' +
    '<button onclick="advShowFlagQueueModal()" id="adv-filter-flagqueue" class="adv-fbtn" style="background:#D84315;color:#fff;border:none;border-radius:6px;padding:6px 12px;font-size:12px;font-weight:700;cursor:pointer;">🚩 Flagged <span id="adv-cnt-flagqueue">0</span></button>' +
    '<!-- /KEYTECH-FLAGQUEUE-BTN-v1 -->';
  return s.replace(anchor, insert);
});

// ---------------------------------------------------------------------------
// 5) The modal shell itself, appended just before </body>
// ---------------------------------------------------------------------------
applyOnce('<!-- KEYTECH-FLAGQUEUE-MODAL-v1 -->', function (s) {
  const anchor = '</body>';
  if (s.indexOf(anchor) === -1) return s;
  const modal =
    '<!-- KEYTECH-FLAGQUEUE-MODAL-v1 -->\n' +
    '<div id="adv-flagqueue-modal" style="display:none;position:fixed;inset:0;background:rgba(0,0,0,.6);z-index:9999;align-items:center;justify-content:center;padding:20px;">\n' +
    '  <div style="background:#0A1628;border-radius:14px;max-width:520px;width:100%;max-height:80vh;overflow-y:auto;padding:20px;">\n' +
    '    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px;">\n' +
    '      <h3 style="color:#fff;margin:0;font-size:16px;">🚩 Flagged for Review</h3>\n' +
    '      <button onclick="advCloseFlagQueueModal()" style="background:none;border:none;color:#78909C;font-size:22px;cursor:pointer;line-height:1;">&times;</button>\n' +
    '    </div>\n' +
    '    <div id="adv-flagqueue-content"></div>\n' +
    '  </div>\n' +
    '</div>\n' +
    '<!-- /KEYTECH-FLAGQUEUE-MODAL-v1 -->\n';
  return s.replace(anchor, modal + anchor);
});

// ---------------------------------------------------------------------------
// 6) Refresh the flag-queue count once the owner successfully logs in
// ---------------------------------------------------------------------------
applyOnce('/* KEYTECH-FLAGQUEUE-REFRESH-ON-LOGIN-v1 */', function (s) {
  const anchor = '    _bioUnlock();\n  }\n} else {\n    // Wrong — increment attempts';
  // Looser anchor: the owner-PIN success branch's _bioUnlock() call right before the
  // "else" of the wrong-PIN branch. Fall back to a simpler unique anchor if the exact
  // whitespace doesn't match (minified/reformatted live copies vary).
  const anchor2 = '    _bioUnlock();\n  } else {';
  if (s.indexOf(anchor2) !== -1) {
    const insert =
      '    _bioUnlock();\n' +
      '    /* KEYTECH-FLAGQUEUE-REFRESH-ON-LOGIN-v1 */\n' +
      '    if (typeof advRefreshFlagQueueCount === "function") advRefreshFlagQueueCount();\n' +
      '    /* /KEYTECH-FLAGQUEUE-REFRESH-ON-LOGIN-v1 */\n' +
      '  } else {';
    return s.replace(anchor2, insert);
  }
  return s;
});

if (changed) {
  fs.writeFileSync(FILE, html);
  console.log('WROTE ' + FILE);
} else {
  console.log('NO CHANGES (already applied or anchors not found)');
}
