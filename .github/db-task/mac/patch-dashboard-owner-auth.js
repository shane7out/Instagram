// Dashboard patch (MEMBER DATA PROTECTION step 4 + DASHBOARD OWNER LOCK part 1). Run by deploy-dashboard-owner-auth.sh on the LIVE dashboard copy.
//  OWNERAUTH01: adds the owner sign-in snippet (same one the Leads / CRM / Rewards admin pages use, with the quick-unlock PIN) right after <head>.
//               Once Shane signs in, every database call this page makes carries his token. Until then nothing changes (the snippet stays dormant).
//  OWNERAUTH02: the Rewards list on the dashboard also reads the hidden record spot (lvr_member_private) and puts phone/email/birthday/anniversary/token
//               back onto each member in memory ONLY (the page never writes them back: its only member write is the points number).
// Marker-fenced and idempotent. Does NOT touch any PIN, any data, or any database rule.
const fs = require('fs');
const file = process.argv[2], snipFile = process.argv[3];
if (!file || !snipFile) { console.error('usage: node patch-dashboard-owner-auth.js <index.html> <owner-auth.snippet.html>'); process.exit(1); }
let s = fs.readFileSync(file, 'utf8');
fs.writeFileSync(file + '.bak-ownerauth', s);
const snip = fs.readFileSync(snipFile, 'utf8').trim();
if (!/<!--OWNER-AUTH-START-->[\s\S]*<!--OWNER-AUTH-END-->/.test(snip)) { console.error('OWNERAUTH01: snippet file has no start/end markers'); process.exit(1); }

if (/<!--OWNER-AUTH-START-->/.test(s)) {
  s = s.replace(/<!--OWNER-AUTH-START-->[\s\S]*?<!--OWNER-AUTH-END-->/, () => snip);
  console.log('OWNERAUTH01 refreshed (snippet already present)');
} else {
  if ((s.match(/<head>/g) || []).length !== 1) { console.error('OWNERAUTH01: expected exactly one <head>'); process.exit(1); }
  s = s.replace('<head>', () => '<head>\n' + snip);
  console.log('OWNERAUTH01 applied');
}

if (/OWNERAUTH02/.test(s)) console.log('OWNERAUTH02 already present, skipping');
else {
  const anchor = `  fetch(_rwdFbUrl())
    .then(function(r) { return r.ok ? r.json() : null; })
    .then(function(data) {
      _rewardsFbData = data || Object.create(null);`;
  if (s.split(anchor).length !== 2) { console.error('OWNERAUTH02: anchor not found exactly once (the live page differs)'); process.exit(1); }
  const repl = `  fetch(_rwdFbUrl())
    .then(function(r) { return r.ok ? r.json() : null; })
    .then(function(data) { // OWNERAUTH02: also read the hidden member spot (owner only) and merge phone/email/birthday/anniversary/token in memory
      if (!data || (typeof isFriend!=='undefined' && isFriend)) return data;
      return fetch('https://lvr-data-a60c1-default-rtdb.firebaseio.com/lvr_member_private.json').then(function(r) { return r.ok ? r.json() : null; }).catch(function() { return null; }).then(function(p) {
        if (p && typeof p === 'object') Object.keys(p).forEach(function(t) { var v = p[t] || {}, m = v.memberKey && data[v.memberKey]; if (m && typeof m === 'object') { ['phone', 'email', 'birthday', 'anniversary'].forEach(function(f) { if (m[f] == null && v[f] != null) m[f] = v[f]; }); if (m.token == null) m.token = t; } });
        return data;
      });
    })
    .then(function(data) {
      _rewardsFbData = data || Object.create(null);`;
  s = s.replace(anchor, () => repl);
  console.log('OWNERAUTH02 applied');
}
fs.writeFileSync(file, s);
