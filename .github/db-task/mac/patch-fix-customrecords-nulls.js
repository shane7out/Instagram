// Fixes the dashboard Total (Shane, 2026-11-09). dashboard/customrecords in the cloud has three EMPTY slots (index 1117, 1125, 1229). The page's rebuild loop reads
// customRecords[i].num with no null check, throws at the first empty slot, and so 196 restaurants (num 50802 and up, incl. everything added since 2026-09-10) never reach the
// list or the Total. This patch cleans the list the moment it is loaded (cloud copy or saved copy): empty slots are dropped, every real record is kept.
// Code only: no database data is touched by the patch itself. Idempotent (marker CRNULL01), keeps a .bak-crnull backup next to index.html.
const fs = require('fs');
const file = process.argv[2];
if (!file) { console.error('usage: node patch-fix-customrecords-nulls.js <index.html>'); process.exit(1); }
let s = fs.readFileSync(file, 'utf8');
fs.writeFileSync(file + '.bak-crnull', s);
if (/CRNULL01/.test(s)) { console.log('CRNULL01 already present, nothing to do'); process.exit(0); }

// 1) the cleaner (a function declaration, so it is available everywhere in the page script)
const loadFn = /function loadCustomRecords\(\)\s*\{[^\n]*\n/;
const m = s.match(loadFn);
if (!m) { console.error('CRNULL01: loadCustomRecords() not found'); process.exit(1); }
const helper = "/* CRNULL01 */ function _crClean(a){ try{ var arr=Array.isArray(a)?a:(a&&typeof a==='object'?Object.keys(a).map(function(k){return a[k];}):[]); return arr.filter(function(x){return x&&typeof x==='object';}); }catch(e){ return Array.isArray(a)?a:[]; } }\n";
s = s.replace(loadFn, m[0] + helper);

// 2) use it everywhere customRecords is assigned from the cloud copy or from saved storage
let n = 0;
s = s.replace(/customRecords(\s*)=(\s*)rec\.customrecords;/g, (all, a, b) => { n++; return 'customRecords' + a + '=' + b + '_crClean(rec.customrecords); /* CRNULL01 */'; });
s = s.replace(/customRecords(\s*)=(\s*)loadCustomRecords\(\);/g, (all, a, b) => { n++; return 'customRecords' + a + '=' + b + '_crClean(loadCustomRecords()); /* CRNULL01 */'; });
console.log('CRNULL01 assignments patched: ' + n);
if (n < 4) { console.error('CRNULL01: expected at least 4 assignments (cloud x2, saved x3), found ' + n + ' - not writing'); fs.writeFileSync(file, fs.readFileSync(file + '.bak-crnull', 'utf8')); process.exit(1); }
fs.writeFileSync(file, s);
console.log('CRNULL01 applied');
