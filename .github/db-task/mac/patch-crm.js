#!/usr/bin/env node
/* CRM fixes for the dashboard.
 *
 * Surgical, idempotent edits to index.html. Every change is fenced by a
 * CRMFIX marker; if the marker is already present the edit is skipped, so
 * running this twice is safe. Run with a path argument, or from the dashboard
 * working copy.
 *
 * What it changes, and why:
 *   1  JSON import replaced the whole customer list with no warning. Now it
 *      asks: merge, replace, or cancel - and says how many are in each.
 *   2  CSV export omitted Avg Spend and Preferred Contact, both of which the
 *      importer reads. Export -> re-import silently zeroed everyone's spend.
 *   3  No duplicate check anywhere. Re-importing a CSV doubled every customer.
 *      Now matches on phone digits / email / instagram handle and skips repeats.
 *   4  One customer with no name blanked the entire list (c.name.split of
 *      undefined). Guarded in both the card builder and the filter.
 *   5  Ids loaded from localStorage were left as strings, so the strict ===
 *      lookups behind every card button silently missed. Normalized on load,
 *      the same way the Firebase and import paths already do it.
 *   6  Points under 50 were drawn in 'transparent' - invisible on the card.
 *   7  Last Visit showed MM/DD with no year, so 2024 and 2026 looked identical.
 *   8  "Lapsed 60d" counted everyone who had never recorded a visit, which on
 *      a fresh import is the whole database. Never-visited is now its own
 *      badge and its own filter.
 *   9  Typing in search reset the filter to All, so you could not search
 *      within VIPs. Search now runs inside the active filter.
 *  10  No sorting at all. Added: recent visit, points, spend, name, newest.
 *  11  The header read "Customer CRM Demo" for everyone, including the owner.
 */
'use strict';
const fs = require('fs');

const FILE = process.argv[2] || 'index.html';
let s = fs.readFileSync(FILE, 'utf8');
const before = s;
const done = [], skipped = [], failed = [];

function edit(id, find, replace) {
  if (s.indexOf('CRMFIX' + id) !== -1) { skipped.push(id + ' (already applied)'); return; }
  const i = s.indexOf(find);
  if (i === -1) { failed.push(id + ' (anchor not found)'); return; }
  if (s.indexOf(find, i + 1) !== -1) { failed.push(id + ' (anchor not unique)'); return; }
  s = s.slice(0, i) + replace + s.slice(i + find.length);
  done.push(id);
}

/* ---- 1. JSON import must not destroy the list without asking ------------ */
edit('01',
  "if (Array.isArray(parsed)) { CRM_CUSTOMERS = parsed;",
  "if (Array.isArray(parsed)) { /*CRMFIX01*/\n" +
  "          var _have = CRM_CUSTOMERS.length, _incoming = parsed.length;\n" +
  "          if (_have > 0) {\n" +
  "            var _ans = prompt('You have ' + _have + ' customers. This file has ' + _incoming + '.\\n\\n' +\n" +
  "              'Type MERGE to add the new ones and keep yours,\\n' +\n" +
  "              'or REPLACE to throw yours away and use the file.\\n\\n' +\n" +
  "              'Anything else cancels.', 'MERGE');\n" +
  "            if (!_ans) { showDMToast('Import cancelled.'); return; }\n" +
  "            _ans = _ans.trim().toUpperCase();\n" +
  "            if (_ans === 'MERGE') {\n" +
  "              var _added = 0, _dupes = 0;\n" +
  "              for (var _pi = 0; _pi < parsed.length; _pi++) {\n" +
  "                if (_crmFindDupe(parsed[_pi])) { _dupes++; continue; }\n" +
  "                var _cp = parsed[_pi]; _cp.id = crmGetNextId(); CRM_CUSTOMERS.push(_cp); _added++;\n" +
  "              }\n" +
  "              CRM_CUSTOMERS.forEach(function(cu){if(!cu.avatarColor)cu.avatarColor=_rwdAvatarColor(cu.name||'');});\n" +
  "              crmSaveCustomers(); _crmDirty=true; crmRender();\n" +
  "              showDMToast('Added ' + _added + (_dupes ? ', skipped ' + _dupes + ' already here' : ''));\n" +
  "              return;\n" +
  "            }\n" +
  "            if (_ans !== 'REPLACE') { showDMToast('Import cancelled.'); return; }\n" +
  "          }\n" +
  "          CRM_CUSTOMERS = parsed;");

/* ---- 2/3. duplicate finder, used by import and by Add ------------------- */
edit('02',
  "function crmGetNextId() {",
  "/*CRMFIX02*/\n" +
  "function _crmKeys(c) {\n" +
  "  if (!c) return {};\n" +
  "  return {\n" +
  "    phone: String(c.phone || '').replace(/\\D/g, ''),\n" +
  "    email: String(c.email || '').trim().toLowerCase(),\n" +
  "    ig:    String(c.instagram || '').trim().toLowerCase().replace(/^@/, ''),\n" +
  "    name:  String(c.name || '').trim().toLowerCase().replace(/\\s+/g, ' ')\n" +
  "  };\n" +
  "}\n" +
  "// A match on phone, email or instagram is the same person. Name alone is not\n" +
  "// enough - two different Maria Garcias are perfectly possible.\n" +
  "function _crmFindDupe(cand, skipId) {\n" +
  "  var k = _crmKeys(cand);\n" +
  "  if (!k.phone && !k.email && !k.ig) return null;\n" +
  "  for (var i = 0; i < CRM_CUSTOMERS.length; i++) {\n" +
  "    var e = CRM_CUSTOMERS[i];\n" +
  "    if (skipId != null && e.id === skipId) continue;\n" +
  "    var ek = _crmKeys(e);\n" +
  "    if (k.phone && ek.phone && k.phone === ek.phone) return e;\n" +
  "    if (k.email && ek.email && k.email === ek.email) return e;\n" +
  "    if (k.ig    && ek.ig    && k.ig    === ek.ig)    return e;\n" +
  "  }\n" +
  "  return null;\n" +
  "}\n" +
  "\nfunction crmGetNextId() {");

/* ---- CSV import: skip customers already on file ------------------------- */
edit('03',
  "      if (!name) continue;",
  "      if (!name) continue;\n" +
  "      /*CRMFIX03*/ // don't add somebody who is already here\n" +
  "      if (_crmFindDupe({ name: name,\n" +
  "            phone: _col(cols,['phone','mobile','cell','telephone']),\n" +
  "            email: _col(cols,['email','e-mail','email address']),\n" +
  "            instagram: _col(cols,['instagram','ig','handle']) })) { _crmSkipped++; continue; }");

/* ---- 4. a missing name must not blank the whole list -------------------- */
edit('04',
  "var initials = c.name.split(' ')",
  "/*CRMFIX04*/ var initials = String(c.name || '?').split(' ')");
edit('05',
  "var nm = c.name.toLowerCase();",
  "/*CRMFIX05*/ var nm = String(c.name || '').toLowerCase();");

/* ---- 5. ids from localStorage come back as strings ---------------------- */
edit('06',
  "_c.forEach(function(cu){ if (!cu.avatarColor) cu.avatarColor = _rwdAvatarColor(cu.name); });",
  "/*CRMFIX06*/ // ids must be numbers - every card button looks its customer up with ===\n" +
  "    (function(){ var _m = 0;\n" +
  "      _c.forEach(function(cu){ var n = parseInt(cu.id, 10); if (!isNaN(n) && n > _m) _m = n; });\n" +
  "      _c.forEach(function(cu){ var n = parseInt(cu.id, 10); cu.id = isNaN(n) ? (++_m) : n; });\n" +
  "    })();\n" +
  "    _c.forEach(function(cu){ if (!cu.avatarColor) cu.avatarColor = _rwdAvatarColor(cu.name || ''); });");

/* ---- 6. points under 50 were invisible ---------------------------------- */
edit('07',
  "var tierColor = c.points>=500?'#FFD600':c.points>=200?'#90CAF9':c.points>=50?'#E65100':'transparent';",
  "/*CRMFIX07*/ var tierColor = c.points>=500?'#F9A825':c.points>=200?'#1565C0':c.points>=50?'#E65100':'#5A6572';");

/* ---- 7. Last Visit needs a year once it isn't this year ----------------- */
edit('08',
  "var lastVisitShort = c.lastVisit ? c.lastVisit.slice(5).replace('-','/') : '—';",
  "/*CRMFIX08*/ // MM/DD reads the same for 2024 and 2026 - show the year unless it's this one\n" +
  "  var lastVisitShort = '—';\n" +
  "  if (c.lastVisit) {\n" +
  "    var _lv = String(c.lastVisit);\n" +
  "    var _lvm = _lv.match(/^(\\d{4})-(\\d{2})-(\\d{2})/);\n" +
  "    if (_lvm) {\n" +
  "      lastVisitShort = _lvm[2] + '/' + _lvm[3];\n" +
  "      if (_lvm[1] !== String(new Date().getFullYear())) lastVisitShort += '/' + _lvm[1].slice(2);\n" +
  "    } else { lastVisitShort = _lv; }\n" +
  "  }");

/* ---- 8. never-visited is not the same as lapsed ------------------------- */
edit('09',
  "function _isLapsed(lastVisit) {\n  if (!lastVisit) return true;",
  "/*CRMFIX09*/ // Someone who has never recorded a visit hasn't lapsed - they've never started.\n" +
  "// Counting them as lapsed made the badge read as the whole database after an import.\n" +
  "function _crmNeverVisited(c) { return !c || !c.lastVisit; }\n" +
  "function _isLapsed(lastVisit) {\n  if (!lastVisit) return false;");

/* ---- 9. search inside the filter you are already looking at ------------- */
edit('10',
  "crmSearch = this.value.toLowerCase().trim();\n        crmFilter = 'all';\n",
  "crmSearch = this.value.toLowerCase().trim();\n        /*CRMFIX10*/ // keep the filter - searching within VIPs is the point\n");

/* ---- 10. sorting ------------------------------------------------------- */
edit('11',
  "function _crmRefilter() {\n  if (!_crmDirty) return; _crmDirty = false; _crmFiltered = [];",
  "/*CRMFIX11*/ var crmSort = 'none';\n" +
  "function crmSetSort(v) { crmSort = v; _crmDirty = true; var sc=document.getElementById('view-crm'); if(sc)sc.scrollTop=0; crmRender(); }\n" +
  "function _crmSortApply(idxs) {\n" +
  "  if (crmSort === 'none') return idxs;\n" +
  "  var C = CRM_CUSTOMERS;\n" +
  "  var cmp = {\n" +
  "    recent: function(a,b){ return String(C[b].lastVisit||'').localeCompare(String(C[a].lastVisit||'')); },\n" +
  "    points: function(a,b){ return (C[b].points||0) - (C[a].points||0); },\n" +
  "    spend:  function(a,b){ return ((C[b].visits||0)*(C[b].avgSpend||0)) - ((C[a].visits||0)*(C[a].avgSpend||0)); },\n" +
  "    name:   function(a,b){ return String(C[a].name||'').localeCompare(String(C[b].name||'')); },\n" +
  "    newest: function(a,b){ return (C[b].id||0) - (C[a].id||0); }\n" +
  "  }[crmSort];\n" +
  "  return cmp ? idxs.slice().sort(cmp) : idxs;\n" +
  "}\n" +
  "function _crmRefilter() {\n  if (!_crmDirty) return; _crmDirty = false; _crmFiltered = [];");

edit('12',
  "    _crmFiltered.push(i);\n  }\n}",
  "    _crmFiltered.push(i);\n  }\n  /*CRMFIX12*/ _crmFiltered = _crmSortApply(_crmFiltered);\n}");

/* the 'never' filter case, alongside the existing ones */
edit('13',
  "    if (crmFilter === 'optout' && !c.optout) continue;",
  "    if (crmFilter === 'optout' && !c.optout) continue;\n" +
  "    /*CRMFIX13*/ if (crmFilter === 'never' && !_crmNeverVisited(c)) continue;");

/* ---- the two new controls in the markup -------------------------------- */
edit('14',
  '<div class="badge b-problem"     onclick="crmSetFilter(\'optout\')">Opt-Out: <span id="cs-optout">0</span></div>',
  '<div class="badge b-problem"     onclick="crmSetFilter(\'optout\')">Opt-Out: <span id="cs-optout">0</span></div>\n' +
  '    <!--CRMFIX14--><div class="badge" style="background:#5A6572;" onclick="crmSetFilter(\'never\')">No visits yet: <span id="cs-never">0</span></div>');

edit('15',
  '<input type="text" id="crm-search" placeholder="Search customers..."',
  '<!--CRMFIX15--><select id="crm-sort" onchange="crmSetSort(this.value)" aria-label="Sort customers" ' +
  'style="flex:0 0 auto;max-width:44%;padding:9px 10px;border:1.5px solid #ccc;border-radius:10px;' +
  'font-size:14px;background:#fff;color:#1B2E4A;">' +
  '<option value="none">Sort: default</option>' +
  '<option value="recent">Recent visit</option>' +
  '<option value="points">Most points</option>' +
  '<option value="spend">Top spend</option>' +
  '<option value="name">Name A&ndash;Z</option>' +
  '<option value="newest">Newest added</option>' +
  '</select>\n    <input type="text" id="crm-search" placeholder="Search customers..."');

/* the new stat has to be counted */
edit('16',
  "    if (c.optout) optout++;\n  }",
  "    if (c.optout) optout++;\n    /*CRMFIX16*/ if (_crmNeverVisited(c)) never++;\n  }");
edit('17',
  "var total=CRM_CUSTOMERS.length, vip=0, bday=0, ann=0, lapsed=0, followup=0, notes=0, optout=0;",
  "/*CRMFIX17*/ var total=CRM_CUSTOMERS.length, vip=0, bday=0, ann=0, lapsed=0, followup=0, notes=0, optout=0, never=0;");
edit('18',
  "  document.getElementById('cs-optout').textContent = optout;",
  "  document.getElementById('cs-optout').textContent = optout;\n" +
  "  /*CRMFIX18*/ var _nv = document.getElementById('cs-never'); if (_nv) _nv.textContent = never;");

/* ---- 2. export the two columns the importer reads ---------------------- */
edit('19',
  "var headers = ['ID','Name','Phone','Email','Instagram','Birthday','Anniversary','First Visit','Last Visit','Visits','Points','VIP','Opt-Out','Follow Up','Source','Tags','Notes'];",
  "/*CRMFIX19*/ // Avg Spend and Preferred Contact are read by the importer but were never\n" +
  "  // written out, so an export/re-import round trip zeroed every customer's spend.\n" +
  "  var headers = ['ID','Name','Phone','Email','Instagram','Birthday','Anniversary','First Visit','Last Visit','Visits','Points','Avg Spend','Preferred Contact','VIP','Opt-Out','Follow Up','Source','Tags','Notes'];");
edit('20',
  "rows.push([c.id,c.name,c.phone,c.email,c.instagram,c.birthday,c.anniversary,c.firstVisit,c.lastVisit,c.visits,c.points,c.vip?'Yes':'No',c.optout?'Yes':'No',c.followup?'Yes':'No',c.source,c.tags,c.notes]);",
  "/*CRMFIX20*/ rows.push([c.id,c.name,c.phone,c.email,c.instagram,c.birthday,c.anniversary,c.firstVisit,c.lastVisit,c.visits,c.points,c.avgSpend,c.preferredContact,c.vip?'Yes':'No',c.optout?'Yes':'No',c.followup?'Yes':'No',c.source,c.tags,c.notes]);");

/* ---- 3b. warn on the Add form too -------------------------------------- */
edit('21',
  "  var name = document.getElementById('crm-f-name').value.trim();\n  if (!name) { alert('Name is required.'); return; }",
  "  var name = document.getElementById('crm-f-name').value.trim();\n  if (!name) { alert('Name is required.'); return; }\n" +
  "  /*CRMFIX21*/ // same phone, email or instagram as somebody already on file\n" +
  "  var _dupe = _crmFindDupe({ name: name,\n" +
  "    phone: document.getElementById('crm-f-phone').value.trim(),\n" +
  "    email: document.getElementById('crm-f-email').value.trim(),\n" +
  "    instagram: document.getElementById('crm-f-instagram').value.trim() }, _crmEditId || null);\n" +
  "  if (_dupe && !confirm(_dupe.name + ' already has that phone, email or Instagram.\\n\\nAdd this one anyway?')) return;");

/* ---- CSV import: report how many were skipped -------------------------- */
edit('22',
  "    var imported = 0;\n    var maxId = crmGetNextId();",
  "    /*CRMFIX22*/ var _crmSkipped = 0;\n    var imported = 0;\n    var maxId = crmGetNextId();");

/* ---- 11. it is not a demo for the owner -------------------------------- */
edit('23',
  '<span id="crm-title" style="color:#fff;font-size:16px;font-weight:800;flex:1;">Customer CRM Demo</span>',
  '<!--CRMFIX23--><span id="crm-title" style="color:#fff;font-size:16px;font-weight:800;flex:1;">Customer CRM</span>');

/* ---- report ------------------------------------------------------------ */
console.log('applied : ' + (done.length ? done.join(', ') : 'none'));
if (skipped.length) console.log('skipped : ' + skipped.join(', '));
if (failed.length)  console.log('FAILED  : ' + failed.join(', '));

if (s !== before) {
  fs.writeFileSync(FILE + '.bak-crm', before);
  fs.writeFileSync(FILE, s);
  console.log('wrote ' + FILE + '  (' + before.length + ' -> ' + s.length + ' bytes)');
} else {
  console.log('no change');
}
process.exit(failed.length ? 1 : 0);
