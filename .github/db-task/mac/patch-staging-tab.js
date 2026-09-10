#!/usr/bin/env node
/* Bring back the Restaurant Staging tab.
 *
 * The whole staging pipeline is already built and working - RESTAURANTS_STAGING
 * (487 restaurants, every one with an IG handle, plus phone/email/cuisine/
 * address), rsShowStaging(), rsApprove() to promote into the main list,
 * rsRemove(), a duplicate detector, and owner-only guards. Only the tab that
 * reaches it was taken out, and the source says so:
 *
 *   "Outreach/Staging tab row removed per owner request (dashboard defaults to
 *    the outreach view). To restore: re-add the #main-tab-row div with the
 *    #mtab-outreach and #mtab-staging buttons."
 *
 * That is exactly what this does. Visibility of #main-tab-row is already
 * handled elsewhere (showRestaurantsView sets it to flex, every other view
 * sets it to none), so the div only needed its buttons back.
 *
 * Idempotent - marker-fenced, safe to run twice.
 */
'use strict';
const fs = require('fs');

const FILE = process.argv[2] || 'index.html';
let s = fs.readFileSync(FILE, 'utf8');
const before = s;
const done = [], skipped = [], failed = [];

function edit(id, find, replace) {
  if (s.indexOf('STGTAB' + id) !== -1) { skipped.push(id + ' (already applied)'); return; }
  const i = s.indexOf(find);
  if (i === -1) { failed.push(id + ' (anchor not found)'); return; }
  if (s.indexOf(find, i + 1) !== -1) { failed.push(id + ' (anchor not unique)'); return; }
  s = s.slice(0, i) + replace + s.slice(i + find.length);
  done.push(id);
}

/* ---- 1. the tab row itself -------------------------------------------- */
edit('01',
  '<div id="main-tab-row" style="display:none;"></div>',
  '<!--STGTAB01--><div id="main-tab-row" style="display:flex;overflow-x:auto;gap:2px;' +
  'border-bottom:1px solid rgba(20,147,255,0.12);padding:0 8px;">\n' +
  '      <button class="main-tab active" id="mtab-outreach" type="button" onclick="rsShowMain()">Outreach</button>\n' +
  '      <button class="main-tab" id="mtab-staging" type="button" onclick="rsShowStaging()">Staging' +
  ' <span id="mtab-stg-cnt" style="background:rgba(20,147,255,0.16);border-radius:5px;' +
  'padding:1px 7px;margin-left:4px;font-size:12px;">0</span></button>\n' +
  '    </div>');

/* ---- 2. keep the tab's count in step with the queue -------------------- */
edit('02',
  "function _rsUpdateCount() {\n  var el = document.getElementById('rs-stg-cnt');\n  if (el) el.textContent = RESTAURANTS_STAGING.length;",
  "function _rsUpdateCount() {\n  var el = document.getElementById('rs-stg-cnt');\n  if (el) el.textContent = RESTAURANTS_STAGING.length;\n" +
  "  /*STGTAB02*/ var _mt = document.getElementById('mtab-stg-cnt');\n" +
  "  if (_mt) _mt.textContent = RESTAURANTS_STAGING.length;");

/* ---- 3. and set it once on load, before anything is filtered ----------- */
edit('03',
  "  var extras = document.getElementById('rs-staging-extras');\n  if (extras) extras.style.display = (tab === 'staging') ? '' : 'none';",
  "  var extras = document.getElementById('rs-staging-extras');\n  if (extras) extras.style.display = (tab === 'staging') ? '' : 'none';\n" +
  "  /*STGTAB03*/ if (typeof _rsUpdateCount === 'function') _rsUpdateCount();");

/* ---- report ------------------------------------------------------------ */
console.log('applied : ' + (done.length ? done.join(', ') : 'none'));
if (skipped.length) console.log('skipped : ' + skipped.join(', '));
if (failed.length)  console.log('FAILED  : ' + failed.join(', '));

if (s !== before) {
  fs.writeFileSync(FILE + '.bak-stgtab', before);
  fs.writeFileSync(FILE, s);
  console.log('wrote ' + FILE + '  (' + before.length + ' -> ' + s.length + ' bytes)');
} else {
  console.log('no change');
}
process.exit(failed.length ? 1 : 0);
