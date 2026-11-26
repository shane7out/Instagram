#!/bin/bash
# Run on the Mac (one command):
#   curl -sL --retry 8 --retry-delay 1 --connect-timeout 15 --speed-limit 3000 --speed-time 6 --max-time 150 "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/viewer-pin-setup.sh?$(date +%s)" -o /tmp/viewer-pin-setup.sh && bash /tmp/viewer-pin-setup.sh
#
# Lets you open the Owner visitor report (keytechnologies.si/key-pageviews.html) with just a PIN. How it works:
#   * you type a 6-digit PIN here (the report page has the same round PIN pad as the dashboard); it is never saved or sent anywhere,
#   * the PIN is turned into the password of ONE extra, READ-ONLY sign-in account (it can read the page-view counts and nothing else:
#     no leads, no CRM, no members, and it cannot change anything). The report page does the same conversion in the browser.
#   * then the key-technologies database rules are updated so that account (and you, as owner) can read the page views.
# Run it again any time to CHANGE the PIN. Your owner email and password are asked only by the rules step, like before.
# It does not touch member data, restaurants, points or any PIN of the dashboards.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
cat > /tmp/viewer-pin-setup.js <<'NODE'
const { execSync } = require('child_process');
const fs = require('fs'), os = require('os'), path = require('path'), crypto = require('crypto');
const PROJECT = 'lvr-data-a60c1', DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const EMAIL = 'report-viewer@kt-report.invalid', SALT = 'kt-report-viewer-v1';
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
async function report() { try { await fetch(DB + '/_debug/viewerpin.json', { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(out.join('\n').slice(0, 5000)) }); console.log('\nSENT report - tell Claude done'); } catch (e) { console.log('(could not send the report: ' + e.message + ')'); } }
const status = async (url, opts) => { try { return (await fetch(url, opts)).status; } catch (e) { return 'err'; } };
const derive = pin => crypto.pbkdf2Sync(pin, SALT, 150000, 32, 'sha256').toString('base64url');   // same as the report page
(async () => {
  let TOKEN = ''; try { TOKEN = execSync('gcloud auth print-access-token', { stdio: ['ignore', 'pipe', 'ignore'] }).toString().trim(); } catch (e) {}
  if (!TOKEN) { log('No gcloud login found - nothing changed.'); return report(); }
  const apiKey = await (await fetch(DB + '/ownerAuth/apiKey.json')).json().catch(() => null);
  if (!apiKey) { log('The sign-in key is not stored yet (run owner-setup.sh first) - nothing changed.'); return report(); }
  const p1 = ask('Type your 6-digit PIN for the report (hidden). You can use the same one as your LVR dashboard: ', true).trim();
  if (!/^[0-9]{6}$/.test(p1)) { log('The PIN must be exactly 6 digits, numbers only - nothing changed.'); return report(); }
  const p2 = ask('Type it again: ', true).trim();
  if (p1 !== p2) { log('The two PINs did not match - nothing changed.'); return report(); }
  const PW = derive(p1);
  const H = { Authorization: 'Bearer ' + TOKEN, 'x-goog-user-project': PROJECT, 'Content-Type': 'application/json' };
  const idt = 'https://identitytoolkit.googleapis.com/v1';
  const post = async (url, body, headers) => { try { const r = await fetch(url, { method: 'POST', headers: headers || H, body: JSON.stringify(body) }); const j = await r.json().catch(() => ({})); return { s: r.status, j }; } catch (e) { return { s: 0, j: { error: { message: e.message } } }; } };
  // 1) make (or update) the read-only account, with the PIN-derived password
  let made = false;
  const lk = await post(`${idt}/projects/${PROJECT}/accounts:lookup`, { email: [EMAIL] });
  const existing = lk.s === 200 && lk.j.users && lk.j.users[0];
  if (existing) {
    const up = await post(`${idt}/projects/${PROJECT}/accounts:update`, { localId: existing.localId, password: PW });
    made = up.s === 200; log('Report account already existed; PIN update -> HTTP ' + up.s + (made ? '' : ' ' + JSON.stringify(up.j).slice(0, 200)));
  } else {
    const cr = await post(`${idt}/projects/${PROJECT}/accounts`, { email: EMAIL, password: PW, emailVerified: false });
    made = cr.s === 200; log('Created the read-only report account -> HTTP ' + cr.s + (made ? '' : ' ' + JSON.stringify(cr.j).slice(0, 200)));
  }
  if (!made) {
    console.log('\nThe script could not create the account by itself. Do this ONE thing in the browser, then come back here:');
    console.log('  1. Open https://console.firebase.google.com/project/' + PROJECT + '/authentication/users');
    console.log('  2. Click "Add user"; Email:  ' + EMAIL);
    console.log('     Password (this is made from your PIN, it is not your PIN):  ' + PW);
    console.log('  3. Click "Add user", then come back to this window.\n');
    ask('Press Return after you added the user (or Ctrl-C to stop): ', false);
  }
  // 2) prove the PIN opens it, and learn its id
  const si = await post(`${idt}/accounts:signInWithPassword?key=${encodeURIComponent(apiKey)}`, { email: EMAIL, password: PW, returnSecureToken: true }, { 'Content-Type': 'application/json' });
  if (si.s !== 200 || !si.j.idToken) { log('Could not sign in to the report account with that PIN (HTTP ' + si.s + ' ' + (si.j.error && si.j.error.message) + ') - nothing else changed.'); return report(); }
  const ID = si.j.idToken, VUID = si.j.localId;
  if (!/^[A-Za-z0-9]{20,40}$/.test(VUID)) { log('The report account id looks wrong - stopping.'); return report(); }
  fs.mkdirSync(path.join(os.homedir(), '.lvr'), { recursive: true });
  fs.writeFileSync(path.join(os.homedir(), '.lvr', 'viewer-uid'), VUID + '\n');
  log('The PIN works for the report account. Saved its id on this Mac (~/.lvr/viewer-uid).');
  // 3) the page-view rules (asks for your owner email + password, backs up, checks, rolls back by itself)
  console.log('\nNow the database rules step. It asks for your OWNER email and password (typed here only).\n');
  const rc = (() => { try { execSync('curl -sL --retry 8 --retry-delay 1 --connect-timeout 15 --speed-limit 3000 --speed-time 6 --max-time 150 "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/deploy-key-rules.sh?$(date +%s)" -o /tmp/deploy-key-rules.sh && bash /tmp/deploy-key-rules.sh', { stdio: 'inherit' }); return 0; } catch (e) { return 1; } })();
  // 4) final check, as the report account would see it
  await new Promise(r => setTimeout(r, 3000));
  const a = await status(`${DB}/key_pageviews/hits.json?shallow=true`);
  const v = await status(`${DB}/key_pageviews/hits.json?shallow=true&auth=${encodeURIComponent(ID)}`);
  const l = await status(`${DB}/key_leads/leads.json?shallow=true&auth=${encodeURIComponent(ID)}`);
  const w = await status(`${DB}/key_pageviews/hits/zz_probe.json?auth=${encodeURIComponent(ID)}`, { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: '1' });
  const probes = [['a stranger cannot read the page views', a, 401], ['the PIN account CAN read the page views', v, 200], ['the PIN account cannot read the leads', l, 401], ['the PIN account cannot change the page views', w, 401]];
  let ok = true;
  for (const [name, got, want] of probes) { const good = got === want || (want === 401 && got === 403); if (!good) ok = false; log((good ? 'OK   ' : 'FAIL ') + name + ' (HTTP ' + got + ')'); }
  log(ok ? 'ALL CHECKS PASSED. Open keytechnologies.si/key-pageviews.html, type your PIN on the pad, and say yes to Face ID when it asks.' : 'A check failed - tell Claude; nothing is lost (the rules step rolls itself back if it fails).');
  await report();
})();
NODE
node /tmp/viewer-pin-setup.js
