#!/bin/bash
# Run on the Mac (one command):
#   curl -sL "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/rr-pin-setup.sh?$(date +%s)" -o /tmp/rr-pin-setup.sh && bash /tmp/rr-pin-setup.sh
#
# Makes the PINs for the Restaurant Rewards Treasury. It asks "who is this PIN for?":
#   * press Return  -> YOUR Treasury PIN (6 digits). It opens keytechnologies.si/restaurant-rewards-treasury.html and lets that
#                      page save every wallet and every move permanently in the database. After that it also runs the database-rules
#                      step (asks for your OWNER email + password, saves a backup first, rolls itself back if a check fails).
#   * type a wallet ID (shown on the restaurant's wallet screen, like w1) -> that restaurant's PIN. A restaurant PIN can ONLY open
#                      keytechnologies.si/restaurant-confirm.html and confirm or decline payments sent to that one restaurant.
# PINs are typed here only (hidden). They are never saved, never sent anywhere and never written in the code. Run it again any time to
# CHANGE a PIN. It does not touch members, points, leads or any other PIN.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
cat > /tmp/rr-pin-setup.js <<'NODE'
const { execSync } = require('child_process');
const fs = require('fs'), os = require('os'), path = require('path'), crypto = require('crypto');
const PROJECT = 'lvr-data-a60c1', DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
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
async function report() { try { await fetch(DB + '/_debug/rrpin.json', { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(out.join('\n').slice(0, 5000)) }); console.log('\nSENT report - tell Claude done'); } catch (e) { console.log('(could not send the report: ' + e.message + ')'); } }
const status = async (url, opts) => { try { return (await fetch(url, opts)).status; } catch (e) { return 'err'; } };
const derive = (pin, salt) => crypto.pbkdf2Sync(pin, salt, 150000, 32, 'sha256').toString('base64url');   // same as the Treasury and confirm pages
(async () => {
  let TOKEN = ''; try { TOKEN = execSync('gcloud auth print-access-token', { stdio: ['ignore', 'pipe', 'ignore'] }).toString().trim(); } catch (e) {}
  if (!TOKEN) { log('No gcloud login found - nothing changed.'); return report(); }
  const apiKey = await (await fetch(DB + '/ownerAuth/apiKey.json')).json().catch(() => null);
  if (!apiKey) { log('The sign-in key is not stored yet (run owner-setup.sh first) - nothing changed.'); return report(); }
  const H = { Authorization: 'Bearer ' + TOKEN, 'x-goog-user-project': PROJECT, 'Content-Type': 'application/json' };
  const idt = 'https://identitytoolkit.googleapis.com/v1';
  const post = async (url, body, headers) => { try { const r = await fetch(url, { method: 'POST', headers: headers || H, body: JSON.stringify(body) }); const j = await r.json().catch(() => ({})); return { s: r.status, j }; } catch (e) { return { s: 0, j: { error: { message: e.message } } }; } };
  let didTreasurer = false, again = true;
  while (again) {
    const who = ask('\nWho is this PIN for? Press Return for YOUR Treasury PIN, or type a restaurant wallet ID (like w1): ', false).trim().toLowerCase();
    const isT = who === '';
    if (!isT && !/^[a-z][a-z0-9]{0,19}$/.test(who)) { log('That wallet ID does not look right (letters and numbers, like w1) - skipped.'); }
    else {
      const EMAIL = isT ? 'treasurer@kt-rr.invalid' : 'rr-' + who + '@kt-rr.invalid', SALT = isT ? 'kt-rr-treasurer-v1' : 'kt-rr-restaurant-v1:' + who;
      const p1 = ask('Type the 6-digit PIN for ' + (isT ? 'the Treasury' : 'wallet ' + who) + ' (hidden): ', true).trim();
      if (!/^[0-9]{6}$/.test(p1)) { log('The PIN must be exactly 6 digits, numbers only - skipped.'); }
      else {
        const p2 = ask('Type it again: ', true).trim();
        if (p1 !== p2) { log('The two PINs did not match - skipped.'); }
        else {
          const PW = derive(p1, SALT);
          let made = false;
          const lk = await post(`${idt}/projects/${PROJECT}/accounts:lookup`, { email: [EMAIL] });
          const existing = lk.s === 200 && lk.j.users && lk.j.users[0];
          if (existing) { const up = await post(`${idt}/projects/${PROJECT}/accounts:update`, { localId: existing.localId, password: PW }); made = up.s === 200; log('Account already existed; PIN update -> HTTP ' + up.s + (made ? '' : ' ' + JSON.stringify(up.j).slice(0, 200))); }
          else { const cr = await post(`${idt}/projects/${PROJECT}/accounts`, { email: EMAIL, password: PW, emailVerified: false }); made = cr.s === 200; log('Created the account -> HTTP ' + cr.s + (made ? '' : ' ' + JSON.stringify(cr.j).slice(0, 200))); }
          if (!made) {
            console.log('\nThe script could not create the account by itself. Do this ONE thing in the browser, then come back here:');
            console.log('  1. Open https://console.firebase.google.com/project/' + PROJECT + '/authentication/users');
            console.log('  2. Click "Add user"; Email:  ' + EMAIL);
            console.log('     Password (made from your PIN, it is not your PIN):  ' + PW);
            console.log('  3. Click "Add user", then come back to this window.\n');
            ask('Press Return after you added the user (or Ctrl-C to stop): ', false);
          }
          const si = await post(`${idt}/accounts:signInWithPassword?key=${encodeURIComponent(apiKey)}`, { email: EMAIL, password: PW, returnSecureToken: true }, { 'Content-Type': 'application/json' });
          if (si.s !== 200 || !si.j.idToken) { log('Could not sign in with that PIN (HTTP ' + si.s + ' ' + (si.j.error && si.j.error.message) + ').'); }
          else {
            log('The PIN works for ' + (isT ? 'the Treasury.' : 'wallet ' + who + '.'));
            if (isT) {
              const UID = si.j.localId;
              if (!/^[A-Za-z0-9]{20,40}$/.test(UID)) { log('The account id looks wrong - stopping.'); return report(); }
              fs.mkdirSync(path.join(os.homedir(), '.lvr'), { recursive: true });
              fs.writeFileSync(path.join(os.homedir(), '.lvr', 'treasurer-uid'), UID + '\n');
              log('Saved the Treasury account id on this Mac (~/.lvr/treasurer-uid).');
              didTreasurer = true;
            }
          }
        }
      }
    }
    again = /^y/i.test(ask('Make another PIN (for a restaurant, or change one)? y/N: ', false).trim());
  }
  if (didTreasurer) {
    console.log('\nNow the database rules step. It asks for your OWNER email and password (typed here only).\n');
    try { execSync('curl -sL "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/deploy-key-rules.sh?$(date +%s)" -o /tmp/deploy-key-rules.sh && bash /tmp/deploy-key-rules.sh', { stdio: 'inherit' }); } catch (e) { log('The rules step did not finish - run it again.'); }
    await new Promise(r => setTimeout(r, 2000));
    const a = await status(`${DB}/rr_ledger.json?shallow=true`);
    log((a === 401 || a === 403 ? 'OK   ' : 'FAIL ') + 'a stranger cannot read the Restaurant Rewards ledger (HTTP ' + a + ')');
  }
  log('Done. Treasury: keytechnologies.si/restaurant-rewards-treasury.html  Restaurants confirm at: keytechnologies.si/restaurant-confirm.html');
  await report();
})();
NODE
node /tmp/rr-pin-setup.js
