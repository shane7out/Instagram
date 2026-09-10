#!/usr/bin/env node
/* Bad IG: show a suggested handle on the card, and let the owner accept it.
 *
 * Suggestions are written to Firebase at dashboard/igsuggest/<num> as
 *   { ig, conf, src, note, ts }
 * where conf is high|medium|low and src is where it came from (a website, a
 * search result, an obvious typo correction). Nothing is applied automatically -
 * every suggestion waits for a person.
 *
 * Accept  -> writes igOverrideMap[num], clears the Bad IG flag, drops the
 *            suggestion. That is the same path the manual IG edit already uses,
 *            so the handle propagates exactly the way a typed one does.
 * Dismiss -> drops the suggestion and leaves the Bad IG flag alone.
 *
 * Idempotent, marker-fenced.
 */
'use strict';
const fs = require('fs');

const FILE = process.argv[2] || 'index.html';
let s = fs.readFileSync(FILE, 'utf8');
const before = s;
const done = [], skipped = [], failed = [];

function edit(id, find, replace) {
  if (s.indexOf('IGSUG' + id) !== -1) { skipped.push(id + ' (already applied)'); return; }
  const i = s.indexOf(find);
  if (i === -1) { failed.push(id + ' (anchor not found)'); return; }
  if (s.indexOf(find, i + 1) !== -1) { failed.push(id + ' (anchor not unique)'); return; }
  s = s.slice(0, i) + replace + s.slice(i + find.length);
  done.push(id);
}

/* ---- 1. the store, the loader, and the two actions --------------------- */
edit('01',
  "function toggleBadIG(num) {",
  `/*IGSUG01*/
// ── Suggested Instagram handles for Bad IG records ───────────────────────
// Filled in from research and parked in Firebase; the owner accepts or
// dismisses each one. Nothing here changes a record on its own.
var IG_SUGGEST = Object.create(null);
var IG_SUGGEST_URL = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com/dashboard/igsuggest';

function igSuggestLoad() {
  if (typeof isDemo !== 'undefined' && isDemo) return;
  fetch(IG_SUGGEST_URL + '.json').then(function (r) { return r.json(); }).then(function (d) {
    IG_SUGGEST = Object.create(null);
    if (d && typeof d === 'object') {
      Object.keys(d).forEach(function (k) {
        var v = d[k];
        if (v && typeof v === 'object' && v.ig) IG_SUGGEST[parseInt(k, 10)] = v;
      });
    }
    if (typeof _dashDirty !== 'undefined') _dashDirty = true;
    if (typeof igSuggestUpdateCount === 'function') igSuggestUpdateCount();
    if (typeof rsRender === 'function') rsRender();
  }).catch(function () {});
}

function igSuggestCount() {
  var n = 0;
  for (var k in IG_SUGGEST) { if (badIGMap[k]) n++; }
  return n;
}

function igSuggestUpdateCount() {
  var el = document.getElementById('s-badig-sug');
  if (el) el.textContent = igSuggestCount();
}

function _igSuggestDrop(num) {
  delete IG_SUGGEST[num];
  try {
    fetch(IG_SUGGEST_URL + '/' + num + '.json', { method: 'DELETE' });
  } catch (e) {}
}

function igSuggestAccept(num) {
  var sug = IG_SUGGEST[num];
  if (!sug || !sug.ig) return;
  var val = String(sug.ig).trim();
  if (val.charAt(0) !== '@') val = '@' + val;
  if (!confirm('Set ' + val + ' as the Instagram handle and clear the Bad IG flag?')) return;

  igOverrideMap[num] = val;
  try { localStorage.setItem(LS_IG_OVERRIDE, JSON.stringify(igOverrideMap)); } catch (e) {}
  if (typeof _fbPatch === 'function') _fbPatch('igovr/' + num, val);

  if (badIGMap[num]) {
    delete badIGMap[num];
    if (typeof saveBadIG === 'function') saveBadIG();
    if (typeof _fbPatch === 'function') _fbPatch('badig/' + num, null);
  }
  _igSuggestDrop(num);
  if (typeof fbSave === 'function') fbSave();
  if (typeof _invalidatePending === 'function') _invalidatePending();
  _dashDirty = true;
  if (typeof dashRefreshCard === 'function') dashRefreshCard(num);
  if (typeof dashUpdateStats === 'function') dashUpdateStats();
  igSuggestUpdateCount();
  if (typeof showDMToast === 'function') showDMToast('Set to ' + val);
}

function igSuggestReject(num) {
  if (!IG_SUGGEST[num]) return;
  _igSuggestDrop(num);
  _dashDirty = true;
  if (typeof dashRefreshCard === 'function') dashRefreshCard(num);
  igSuggestUpdateCount();
  if (typeof showDMToast === 'function') showDMToast('Suggestion dismissed');
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', function () { setTimeout(igSuggestLoad, 1500); });
} else {
  setTimeout(igSuggestLoad, 1500);
}

function toggleBadIG(num) {`);

/* ---- 2. the strip on the card ------------------------------------------ */
edit('02',
  "    +((!_hideCoEd&&userNotesMap[r.num])?'<div class=\"note-preview\">'+_esc((userNotesMap[r.num].trim().split('\\n')[0]||userNotesMap[r.num].trim()).slice(0,80))+'</div>':'')\n    +'</div>';\n  return html;",
  `    +((!_hideCoEd&&userNotesMap[r.num])?'<div class="note-preview">'+_esc((userNotesMap[r.num].trim().split('\\n')[0]||userNotesMap[r.num].trim()).slice(0,80))+'</div>':'')
    /*IGSUG02*/
    +((!_hideCoEd && isBadIG && typeof IG_SUGGEST!=='undefined' && IG_SUGGEST[r.num]) ? (function(_g){
        var _c = _g.conf==='high' ? '#2E7D32' : (_g.conf==='low' ? '#8D6E63' : '#E65100');
        return '<div class="ig-suggest" style="margin-top:8px;padding:9px 11px;border:1px solid '+_c+
          ';border-left-width:4px;border-radius:9px;background:rgba(46,125,50,0.05);">'
          +'<div style="font-size:11px;letter-spacing:.09em;text-transform:uppercase;color:'+_c+
            ';font-weight:800;margin-bottom:3px;">Suggested handle &middot; '+_esc(_g.conf||'')+'</div>'
          +'<div style="font-size:15px;font-weight:800;color:#1B2E4A;word-break:break-all;">'
          +'<a href="https://instagram.com/'+encodeURIComponent(String(_g.ig).replace(/^@/,''))+
            '" target="_blank" rel="noopener" style="color:#1565C0;text-decoration:none;">@'
          +_esc(String(_g.ig).replace(/^@/,''))+'</a></div>'
          +(_g.note?'<div style="font-size:12px;color:#5A6572;margin-top:3px;">'+_esc(_g.note)+'</div>':'')
          +(_g.src?'<div style="font-size:11px;color:#8D8578;margin-top:2px;word-break:break-all;">'+_esc(_g.src)+'</div>':'')
          +'<div style="display:flex;gap:6px;margin-top:8px;">'
          +'<button onclick="igSuggestAccept('+r.num+')" class="btn" style="background:#2E7D32;color:#fff;">Use this</button>'
          +'<button onclick="igSuggestReject('+r.num+')" class="btn" style="background:#78909C;color:#fff;">Not it</button>'
          +'</div></div>';
      })(IG_SUGGEST[r.num]) : '')
    +'</div>';
  return html;`);

/* ---- 3. a count badge next to the other dashboard stats ---------------- */
edit('03',
  '<div class="badge b-rs-priority" onclick="dashSetFilter(\'rspriority\')">⭐ Priority: <span id="s-rs-priority">0</span></div>',
  '<div class="badge b-rs-priority" onclick="dashSetFilter(\'rspriority\')">⭐ Priority: <span id="s-rs-priority">0</span></div>\n' +
  '      <!--IGSUG03--><div class="badge" style="background:#2E7D32;" onclick="dashSetFilter(\'igsuggest\')">IG found: <span id="s-badig-sug">0</span></div>');


/* ---- 4. the filter behind that badge ----------------------------------- */
edit('04',
  "if(f==='badig' &&!badIGMap[r.num])      continue;",
  "if(f==='badig' &&!badIGMap[r.num])      continue;\n" +
  "      /*IGSUG04*/ if(f==='igsuggest' && !(typeof IG_SUGGEST!=='undefined' && IG_SUGGEST[r.num])) continue;");

/* ---- report ------------------------------------------------------------ */
console.log('applied : ' + (done.length ? done.join(', ') : 'none'));
if (skipped.length) console.log('skipped : ' + skipped.join(', '));
if (failed.length)  console.log('FAILED  : ' + failed.join(', '));

if (s !== before) {
  fs.writeFileSync(FILE + '.bak-igsug', before);
  fs.writeFileSync(FILE, s);
  console.log('wrote ' + FILE + '  (' + before.length + ' -> ' + s.length + ' bytes)');
} else {
  console.log('no change');
}
process.exit(failed.length ? 1 : 0);
