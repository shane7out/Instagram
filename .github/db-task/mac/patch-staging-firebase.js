#!/usr/bin/env node
/* Make the restaurant staging queue fillable from outside the browser.
 *
 * Today RESTAURANTS_STAGING is a static list baked into seed-data.js, so the
 * only way to add to it is to edit that file and redeploy from the Mac. The
 * advertiser staging, by contrast, lives in Firebase, which is why advertisers
 * can be queued from anywhere.
 *
 * This adds the same for restaurants: a plain REST read of
 *   dashboard_rest_stg_crec
 * merged into the queue on load and whenever the Staging tab is opened. Records
 * already dismissed (dashboard/rsremoved) stay dismissed, so nothing a person
 * cleared can come back.
 *
 * The merge goes into RESTAURANTS_STAGING_MASTER as well as the working array,
 * because several code paths reset the working array from MASTER (login, logout,
 * mode switch, Firebase poll). Merging into MASTER is what makes remote records
 * survive those resets.
 *
 * Expected record shape, matching the seeded ones:
 *   { num, name, ig, phone, email, cuisine, address, defaultStatus }
 *
 * Deliberately skipped in demo mode - demo must not show real prospects.
 * Idempotent, marker-fenced.
 */
'use strict';
const fs = require('fs');

const FILE = process.argv[2] || 'index.html';
let s = fs.readFileSync(FILE, 'utf8');
const before = s;
const done = [], skipped = [], failed = [];

function edit(id, find, replace) {
  if (s.indexOf('RSFB' + id) !== -1) { skipped.push(id + ' (already applied)'); return; }
  const i = s.indexOf(find);
  if (i === -1) { failed.push(id + ' (anchor not found)'); return; }
  if (s.indexOf(find, i + 1) !== -1) { failed.push(id + ' (anchor not unique)'); return; }
  s = s.slice(0, i) + replace + s.slice(i + find.length);
  done.push(id);
}

/* ---- the loader ------------------------------------------------------- */
edit('01',
  "function _rsRegisterStaging() {",
  `/*RSFB01*/
// ── Restaurant staging, remote half ──────────────────────────────────────
// Seeded staging lives in seed-data.js; this pulls anything queued into
// Firebase since, so restaurants can be staged without a redeploy.
var RS_STG_FB_URL = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com/dashboard_rest_stg_crec.json';
var _rsFbLoaded = false, _rsFbInFlight = false;

function _rsRemovedMap() {
  try { return JSON.parse(localStorage.getItem(LS_RS_REMOVED)) || {}; } catch (e) { return {}; }
}

// Fold a batch of remote records into both the working list and the master copy.
// Returns how many were newly added.
function _rsMergeRemote(rows) {
  if (!rows || !rows.length) return 0;
  var rm = _rsRemovedMap();
  var seen = Object.create(null);
  var i;
  for (i = 0; i < RESTAURANTS_STAGING_MASTER.length; i++) seen[RESTAURANTS_STAGING_MASTER[i].num] = true;
  var added = 0;
  for (i = 0; i < rows.length; i++) {
    var r = rows[i];
    if (!r || r.num == null) continue;
    var n = parseInt(r.num, 10);
    if (isNaN(n) || seen[n]) continue;
    var rec = {
      num: n,
      name: String(r.name || ''),
      ig: String(r.ig || r.instagram || '').replace(/^@/, ''),
      phone: String(r.phone || ''),
      email: String(r.email || ''),
      cuisine: String(r.cuisine || ''),
      address: String(r.address || ''),
      defaultStatus: String(r.defaultStatus || 'pending')
    };
    if (!rec.name) continue;
    seen[n] = true;
    RESTAURANTS_STAGING_MASTER.push(rec);
    if (!rm[n]) { RESTAURANTS_STAGING.push(rec); added++; }
  }
  return added;
}

function rsLoadFirebaseStaging(cb) {
  // demo must never show real prospects
  if (typeof isDemo !== 'undefined' && isDemo) { if (cb) cb(0); return; }
  if (_rsFbInFlight) { if (cb) cb(0); return; }
  _rsFbInFlight = true;
  fetch(RS_STG_FB_URL).then(function (r) { return r.json(); }).then(function (data) {
    _rsFbInFlight = false;
    _rsFbLoaded = true;
    if (!data) { if (cb) cb(0); return; }
    var rows = [];
    if (Array.isArray(data)) {
      rows = data.filter(Boolean);
    } else {
      Object.keys(data).forEach(function (k) {
        var v = data[k];
        if (v && typeof v === 'object') { if (v.num == null) v.num = parseInt(k, 10); rows.push(v); }
      });
    }
    var n = _rsMergeRemote(rows);
    if (typeof _rsUpdateCount === 'function') _rsUpdateCount();
    if (n && typeof _rsIsStaging !== 'undefined' && _rsIsStaging && typeof rsRender === 'function') rsRender();
    if (cb) cb(n);
  }).catch(function () {
    _rsFbInFlight = false;
    if (cb) cb(0);
  });
}

// pull once the page is up, then again whenever the Staging tab is opened
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', function () { setTimeout(rsLoadFirebaseStaging, 1200); });
} else {
  setTimeout(rsLoadFirebaseStaging, 1200);
}

function _rsRegisterStaging() {`);

/* ---- refresh when the tab is opened ------------------------------------ */
edit('02',
  "function rsShowStaging() {\n  _rsIsStaging = true;",
  "function rsShowStaging() {\n  /*RSFB02*/ if (typeof rsLoadFirebaseStaging === 'function') rsLoadFirebaseStaging();\n  _rsIsStaging = true;");

/* ---- report ------------------------------------------------------------ */
console.log('applied : ' + (done.length ? done.join(', ') : 'none'));
if (skipped.length) console.log('skipped : ' + skipped.join(', '));
if (failed.length)  console.log('FAILED  : ' + failed.join(', '));

if (s !== before) {
  fs.writeFileSync(FILE + '.bak-rsfb', before);
  fs.writeFileSync(FILE, s);
  console.log('wrote ' + FILE + '  (' + before.length + ' -> ' + s.length + ' bytes)');
} else {
  console.log('no change');
}
process.exit(failed.length ? 1 : 0);
