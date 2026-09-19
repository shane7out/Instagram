#!/usr/bin/env node
/* Dating site: skip the sign-up screen, land straight on the swipe deck.
 *
 * Today the page checks localStorage for a saved profile (S.me). If one
 * exists it goes straight to Discover; if not - a fresh browser, a new
 * phone, private mode, cleared storage - it shows the onboarding form
 * (name, gender, seeking, age range, birthday, terms) before anything else.
 * That is the "instant sign-up" the owner wants gone: opening the page to
 * show someone should always drop straight into swipe left / swipe right.
 *
 * Fix: when there is no saved profile, silently create a default one (the
 * same fields onboarding itself would have written) and proceed exactly as
 * if it were already there. The onboarding screen and its code are left in
 * place - just never reached automatically - so nothing else about the app
 * changes.
 *
 * Idempotent, marker-fenced.
 */
'use strict';
const fs = require('fs');

const FILE = process.argv[2] || 'dating.html';
let s = fs.readFileSync(FILE, 'utf8');
const before = s;
const done = [], skipped = [], failed = [];

function edit(id, find, replace) {
  if (s.indexOf('DATEQS' + id) !== -1) { skipped.push(id + ' (already applied)'); return; }
  const i = s.indexOf(find);
  if (i === -1) { failed.push(id + ' (anchor not found)'); return; }
  if (s.indexOf(find, i + 1) !== -1) { failed.push(id + ' (anchor not unique)'); return; }
  s = s.slice(0, i) + replace + s.slice(i + find.length);
  done.push(id);
}

edit('01',
  'initOnb();\nif(S && S.me){ if(!S.order)buildOrder(); renderAll(); go("discover"); _activityCatchUp();\n  try{ if(localStorage.getItem("spark_price_note2")!=="1"){ localStorage.setItem("spark_price_note2","1"); setTimeout(function(){ toast("🎉 60 days FREE — no credit card needed · then $9.99/mo"); },1800); } }catch(e){}\n}\nelse { $("onb").classList.remove("hidden"); }',
  'initOnb();\n' +
  '/*DATEQS01*/ // No saved profile (new browser/device, private mode, cleared storage) -\n' +
  '// skip the sign-up screen entirely and drop straight into the swipe deck.\n' +
  'if(!(S && S.me)){\n' +
  '  S=fresh();\n' +
  '  S.me={ name:"Guest", username:"guest_"+Date.now().toString(36), bday:"1996-06-15",\n' +
  '    age:calcAge("1996-06-15")||29, tosAccepted:Date.now(), country:"United States",\n' +
  '    gender:"f", seek:"all", min:18, max:70, maxDist:50, city:"Your City",\n' +
  '    bio:"Instant demo profile — swipe away.", interests:["Coffee","Travel","Music"],\n' +
  '    photo:PHOTO("w",92) };\n' +
  '  buildOrder(); save();\n' +
  '}\n' +
  'if(!S.order)buildOrder(); renderAll(); go("discover"); _activityCatchUp();\n' +
  '  try{ if(localStorage.getItem("spark_price_note2")!=="1"){ localStorage.setItem("spark_price_note2","1"); setTimeout(function(){ toast("🎉 60 days FREE — no credit card needed · then $9.99/mo"); },1800); } }catch(e){}');

console.log('applied : ' + (done.length ? done.join(', ') : 'none'));
if (skipped.length) console.log('skipped : ' + skipped.join(', '));
if (failed.length)  console.log('FAILED  : ' + failed.join(', '));

if (s !== before) {
  fs.writeFileSync(FILE + '.bak-dateqs', before);
  fs.writeFileSync(FILE, s);
  console.log('wrote ' + FILE + '  (' + before.length + ' -> ' + s.length + ' bytes)');
} else {
  console.log('no change');
}
process.exit(failed.length ? 1 : 0);
