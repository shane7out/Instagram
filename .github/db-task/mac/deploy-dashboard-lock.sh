#!/bin/bash
# Run on the Mac (after owner-setup.sh):
#   curl -sL --retry 8 --retry-delay 1 --connect-timeout 15 --speed-limit 3000 --speed-time 6 --max-time 150 "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/deploy-dashboard-lock.sh?$(date +%s)" -o /tmp/deploy-dashboard-lock.sh && bash /tmp/deploy-dashboard-lock.sh
#
# DASHBOARD OWNER LOCK, STEP 3 of 3. Locks the restaurant CRM lists (dashboard, dashboard_*, company_dashboard, customrecords, staging_*, records)
# so that ONLY you, signed in as owner, can read or change them. Everyone else, including anyone who finds the database address, is refused.
# It REFUSES TO RUN (changes nothing) unless: (1) a database backup made in the last 8 days exists in ~/lvr-backups (step 2, backup-setup.sh),
# (2) the live dashboard already has the sign-in bridge (step 1, deploy-dashboard-sdk-auth.sh), (3) your owner login works, and
# (4) the live catch-all rule is exactly the one this was tested against. It saves your current rules first, reads the result back, and PUTS
# YOUR OLD RULES BACK AUTOMATICALLY if any check fails. To undo by hand later:  bash undo-dashboard-lock.sh
# NOT covered on purpose (still open as before, decide later): the friend/helper variants (dashboard_friend, guest10_dm, coeditor_*, lvr_staff_apps, lvr_rewards_friend).
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
cat > /tmp/deploy-dashboard-lock.js <<'NODE'
const { execSync } = require('child_process');
const fs = require('fs'), os = require('os'), path = require('path');
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const FRAG = 'https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/rules/dashboard-lock-rules.json?cb=' + Date.now();
const OLD_WRITE = "newData.exists() && (!data.child('customrecords').exists() || newData.child('customrecords').exists()) && (!data.child('staging_approved').exists() || newData.child('staging_approved').exists()) && (!data.child('staging_added').exists() || newData.child('staging_added').exists()) && (!data.child('records').exists() || newData.child('records').exists())";
const mask = s => String(s).replace(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g, '[EMAIL]').replace(/AIza[0-9A-Za-z_-]{20,}/g, '[KEY]').replace(/ya29\.[0-9A-Za-z._-]+/g, '[TOKEN]');
const out = [], log = s => { const m = mask(s); out.push(m); console.log(m); };
function ask(q, hidden) {
  const fd = fs.openSync('/dev/tty', 'r'); process.stdout.write(q);
  if (hidden) { try { execSync('stty -echo < /dev/tty'); } catch (e) {} }
  let buf = '', b = Buffer.alloc(1);
  while (fs.readSync(fd, b, 0, 1) > 0) { const c = b.toString(); if (c === '\n') break; buf += c; }
  if (hidden) { try { execSync('stty echo < /dev/tty'); } catch (e) {} process.stdout.write('\n'); }
  fs.closeSync(fd); return buf.replace(/\r/g, '');
}
async function report() { try { await fetch(DB + '/_debug/dashlock.json', { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(out.join('\n').slice(0, 6000)) }); console.log('\nSENT result - tell Claude it is done'); } catch (e) {} }
const status = async (url, opts) => { try { return (await fetch(url, opts)).status; } catch (e) { return 'err'; } };
(async () => {
  let TOKEN = ''; try { TOKEN = execSync('gcloud auth print-access-token', { stdio: ['ignore', 'pipe', 'ignore'] }).toString().trim(); } catch (e) {}
  if (!TOKEN) { log('No gcloud login found - nothing changed.'); return report(); }
  // 1) a recent backup (a dated folder that contains the restaurant list and the main dashboard list) must exist
  const bdir = path.join(os.homedir(), 'lvr-backups'); let newest = 0;
  try { for (const d of fs.readdirSync(bdir)) { const dd = path.join(bdir, d); if (fs.existsSync(path.join(dd, 'dashboard_crec.json.gz')) && fs.existsSync(path.join(dd, 'dashboard.json.gz'))) { const m = fs.statSync(dd).mtimeMs; if (m > newest) newest = m; } } } catch (e) {}
  if (!newest || Date.now() - newest > 8 * 86400000) { log('No database backup from the last 8 days (with the restaurant lists) in ~/lvr-backups. Run backup-setup.sh first - nothing changed.'); return report(); }
  log('Backup found (' + Math.round((Date.now() - newest) / 3600000) + ' hours old).');
  // 2) the live dashboard must already have the sign-in bridge
  let live_html = ''; try { live_html = await (await fetch('https://lvr-data-a60c1.web.app/?cb=' + Date.now())).text(); } catch (e) {}
  if (live_html.indexOf('DASHSDK01') < 0 || live_html.indexOf('OWNER_AUTH_SDK') < 0) { log('The live dashboard does not have the sign-in bridge yet. Run deploy-dashboard-sdk-auth.sh first - nothing changed.'); return report(); }
  log('Live dashboard has the sign-in bridge.');
  const uidFile = path.join(os.homedir(), '.lvr', 'owner-uid');
  if (!fs.existsSync(uidFile)) { log('No owner id found. Run owner-setup.sh first - nothing changed.'); return report(); }
  const UID = fs.readFileSync(uidFile, 'utf8').trim();
  if (!/^[A-Za-z0-9]{20,40}$/.test(UID)) { log('The saved owner id looks wrong - nothing changed.'); return report(); }
  const apiKey = await (await fetch(DB + '/ownerAuth/apiKey.json')).json();
  if (!apiKey) { log('The admin sign-in key is not stored yet. Run owner-setup.sh first - nothing changed.'); return report(); }
  // 3) prove the owner login works BEFORE anything is uploaded
  const email = ask('Owner email: ', false).trim().toLowerCase(), pw = ask('Owner password (hidden): ', true);
  const si = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${encodeURIComponent(apiKey)}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, password: pw, returnSecureToken: true }) });
  const sj = await si.json().catch(() => ({}));
  if (!si.ok || !sj.idToken) { log('Owner sign-in failed (HTTP ' + si.status + ') - nothing changed.'); return report(); }
  if (sj.localId !== UID) { log('Signed in, but the owner id does not match the saved one - nothing changed.'); return report(); }
  const ID = sj.idToken; log('Owner sign-in works.');
  const rulesUrl = `${DB}/.settings/rules.json?access_token=${encodeURIComponent(TOKEN)}`;
  const put = body => fetch(rulesUrl, { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body });
  const liveText = await (await fetch(rulesUrl)).text();
  let live; try { live = JSON.parse(liveText); } catch (e) { log('Could not read current rules - nothing changed.'); return report(); }
  // 4) the live catch-all must be exactly the tested one
  const cur = live.rules && live.rules['$rest'];
  if (!cur || cur['.read'] !== true || cur['.write'] !== OLD_WRITE || Object.keys(cur).length !== 2) { log('The live catch-all rule is not the one this was tested against - nothing changed. Tell Claude.'); return report(); }
  const dir = path.join(os.homedir(), 'lvr-rules-backups'); fs.mkdirSync(dir, { recursive: true });
  const stamp = new Date().toISOString().replace(/[:.]/g, '-');
  fs.writeFileSync(path.join(dir, `rules-before-dashlock-${stamp}.json`), liveText); fs.writeFileSync(path.join(dir, 'LATEST-BEFORE-DASHLOCK.json'), liveText);
  log('Saved a copy of your current rules on this Mac (~/lvr-rules-backups/LATEST-BEFORE-DASHLOCK.json).');
  let fragText = await (await fetch(FRAG)).text();
  if (fragText.indexOf('__OWNER_UID__') < 0) { log('The lock rules file has no owner placeholder - nothing changed.'); return report(); }
  fragText = fragText.split('__OWNER_UID__').join(UID);
  let frag; try { frag = JSON.parse(fragText); } catch (e) { log('Could not read the lock rules file - nothing changed.'); return report(); }
  if (!frag['$rest'] || !frag['$rest']['.read'] || !frag['$rest']['.write']) { log('Lock rules file is missing the catch-all - nothing changed.'); return report(); }
  const merged = JSON.parse(liveText); merged.rules['$rest'] = frag['$rest'];
  const o1 = Object.keys(live.rules).sort().join(','), o2 = Object.keys(merged.rules).sort().join(',');
  if (o1 !== o2) { log('Safety check failed (other sections changed) - nothing changed.'); return report(); }
  const pr = await put(JSON.stringify(merged)); log('Upload of the lock -> HTTP ' + pr.status + (pr.status === 200 ? '' : ' ' + mask(await pr.text()).slice(0, 300)));
  if (pr.status !== 200) { log('Rejected by Firebase; your old rules are still in place.'); return report(); }
  // 5) verify: owner still works, a stranger cannot, everything else still answers
  const J = { 'Content-Type': 'application/json' }, A = encodeURIComponent(ID);
  const probes = [
    ['a stranger cannot read the restaurant list', await status(`${DB}/dashboard_crec.json?shallow=true`), 401],
    ['a stranger cannot read the main dashboard list', await status(`${DB}/dashboard.json?shallow=true`), 401],
    ['a stranger cannot change the restaurant list', await status(`${DB}/dashboard_crec/zz_probe.json`, { method: 'PUT', headers: J, body: '{"name":"x"}' }), 401],
    ['a stranger cannot read the staging lists', await status(`${DB}/staging_approved.json?shallow=true`), 401],
    ['YOU can read the restaurant list', await status(`${DB}/dashboard_crec.json?shallow=true&auth=${A}`), 200],
    ['YOU can change the restaurant list', await status(`${DB}/dashboard_crec/zz_probe.json?auth=${A}`, { method: 'PUT', headers: J, body: '{"name":"probe"}' }), 200],
    ['members still readable (public pages)', await status(`${DB}/lvr_rewards.json?shallow=true`), 200],
    ['owner sign-in key still readable', await status(`${DB}/ownerAuth/apiKey.json`), 200],
    ['friend dashboard still readable (not locked)', await status(`${DB}/dashboard_friend.json?shallow=true`), 200],
    ['the log area still writable (_debug)', await status(`${DB}/_debug/zz_probe.json`, { method: 'PUT', headers: J, body: '"ok"' }), 200],
  ];
  await status(`${DB}/dashboard_crec/zz_probe.json?auth=${A}`, { method: 'DELETE' });
  await status(`${DB}/_debug/zz_probe.json`, { method: 'DELETE' });
  let ok = true;
  for (const [name, got, want] of probes) { const good = got === want || (want === 401 && got === 403); if (!good) ok = false; log((good ? 'OK   ' : 'FAIL ') + name + ' (HTTP ' + got + ')'); }
  if (!ok) { const rb = await put(liveText); log('A check failed - put your old rules back automatically -> HTTP ' + rb.status); return report(); }
  log('ALL CHECKS PASSED. The restaurant lists are now owner-only. On the dashboard: tap the key icon, sign in as owner (email + password) - the page reloads once - then use your PIN as usual. To undo: bash undo-dashboard-lock.sh');
  await report();
})();
NODE
node /tmp/deploy-dashboard-lock.js
