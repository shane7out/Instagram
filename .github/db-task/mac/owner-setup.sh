#!/bin/bash
# Run on the Mac:   curl -sL "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/owner-setup.sh?$(date +%s)" -o /tmp/owner-setup.sh && bash /tmp/owner-setup.sh
#
# Creates YOUR owner login for the Points admin (Firebase sign-in, free plan) and prepares the database to accept it.
# It changes NO database rules and NO member data. It:
#   1. turns on email + password sign-in for the project,
#   2. creates your owner account (you type the email and a password; they go only to Google's sign-in service),
#   3. turns off public sign-ups so nobody else can make an account,
#   4. saves your owner id (a random code, not your email) on this Mac in ~/.lvr/owner-uid,
#   5. stores the project's public web key in the database (ownerAuth/apiKey) so the admin page can show "Owner sign-in".
# Nothing is printed or sent anywhere that contains your email or password.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
cat > /tmp/owner-setup.js <<'NODE'
const { execSync } = require('child_process');
const fs = require('fs'), os = require('os'), path = require('path');
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
async function report() { try { await fetch(DB + '/_debug/ownersetup.json', { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(out.join('\n').slice(0, 4000)) }); console.log('\nSENT result - tell Claude it is done'); } catch (e) {} }
(async () => {
  let TOKEN = '';
  try { TOKEN = execSync('gcloud auth print-access-token', { stdio: ['ignore', 'pipe', 'ignore'] }).toString().trim(); } catch (e) {}
  if (!TOKEN) { log('No gcloud login found - nothing changed.'); return report(); }
  const H = { Authorization: 'Bearer ' + TOKEN, 'x-goog-user-project': PROJECT, 'Content-Type': 'application/json' };
  const call = async (method, url, body, headers) => { try { const r = await fetch(url, { method, headers: headers || H, body: body ? JSON.stringify(body) : undefined }); const t = await r.text(); let j = null; try { j = JSON.parse(t); } catch (e) {} return { s: r.status, j, t }; } catch (e) { return { s: 0, j: null, t: String(e) }; } };
  // 1. try to turn on email + password sign-in by script. On the free plan this is refused (the script API needs billing),
  //    so the fallback is one click in the Firebase console.
  let r = await call('POST', `https://identitytoolkit.googleapis.com/v2/projects/${PROJECT}/identityPlatform:initializeAuth`, {});
  const needsBilling = r.s === 400 && /BILLING_NOT_ENABLED/.test(JSON.stringify(r.j || r.t));
  log('Set up sign-in service by script -> HTTP ' + r.s + (r.s === 200 ? '' : needsBilling ? ' (needs the paid plan; using the free console route instead)' : ' (' + mask((r.j && r.j.error && r.j.error.message) || r.t).slice(0, 120) + ')'));
  let viaApi = false;
  if (!needsBilling) {
    r = await call('PATCH', `https://identitytoolkit.googleapis.com/admin/v2/projects/${PROJECT}/config?updateMask=signIn.email.enabled,signIn.email.passwordRequired`, { signIn: { email: { enabled: true, passwordRequired: true } } });
    log('Turn on email + password sign-in -> HTTP ' + r.s + (r.s === 200 ? '' : ' (' + mask((r.j && r.j.error && r.j.error.message) || r.t).slice(0, 160) + ')'));
    viaApi = r.s === 200;
  }
  if (!viaApi) {
    console.log('\n==== ONE QUICK STEP IN YOUR BROWSER (free, about 1 minute) ====');
    console.log('1. Open https://console.firebase.google.com/project/' + PROJECT + '/authentication');
    console.log('2. If you see "Get started", click it.');
    console.log('3. Click the "Sign-in method" tab, click "Email/Password", switch on the FIRST switch (Email/Password), and click Save.');
    console.log('   (Leave "Email link" off. You do NOT need to add a user there: this script makes your owner account.)');
    ask('When that is saved, press Return here to continue: ', false);
  }
  // 2. the project's public web key
  let KEY = '';
  r = await call('GET', `https://firebase.googleapis.com/v1beta1/projects/${PROJECT}/webApps`);
  const apps = (r.j && r.j.apps) || [];
  if (!apps.length) {
    log('No web app found; creating one for the admin sign-in');
    const c = await call('POST', `https://firebase.googleapis.com/v1beta1/projects/${PROJECT}/webApps`, { displayName: 'LVR Admin' });
    log('Create web app -> HTTP ' + c.s);
    await new Promise(res => setTimeout(res, 6000));
    r = await call('GET', `https://firebase.googleapis.com/v1beta1/projects/${PROJECT}/webApps`);
  }
  const app = ((r.j && r.j.apps) || [])[0];
  if (app) { const cfg = await call('GET', `https://firebase.googleapis.com/v1beta1/${app.name}/config`); KEY = (cfg.j && cfg.j.apiKey) || ''; log('Read the project web key -> ' + (KEY ? 'found' : 'not found (HTTP ' + cfg.s + ')')); }
  if (!KEY) { KEY = ask('I could not read the web key by myself. Paste the "Web API Key" from Firebase console > Project settings > General, then press Return: ', false).trim(); }
  if (!/^AIza[0-9A-Za-z_-]{30,}$/.test(KEY)) { log('That does not look like a web key, so I stopped. Nothing else changed.'); return report(); }
  // 3. your owner account
  const email = ask('Owner email (the one you will sign in with): ', false).trim().toLowerCase();
  const pw = ask('Choose a long password (at least 12 characters, hidden): ', true);
  const pw2 = ask('Type it again: ', true);
  if (pw !== pw2 || pw.length < 12 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) { log('The email or password did not match the rules (12+ characters, typed twice). Nothing changed.'); return report(); }
  const idt = 'https://identitytoolkit.googleapis.com/v1/accounts';
  let su = await call('POST', `${idt}:signInWithPassword?key=${KEY}`, { email, password: pw, returnSecureToken: true }, { 'Content-Type': 'application/json' });
  let uid = su.j && su.j.localId;
  if (uid) log('Signed in with your existing owner account -> HTTP ' + su.s);
  else {
    const em = (su.j && su.j.error && su.j.error.message) || '';
    if (/INVALID_PASSWORD|INVALID_LOGIN_CREDENTIALS/.test(em) && !/EMAIL_NOT_FOUND/.test(em)) { /* could be a wrong password for an existing account, or no account yet: try to create */ }
    su = await call('POST', `${idt}:signUp?key=${KEY}`, { email, password: pw, returnSecureToken: true }, { 'Content-Type': 'application/json' });
    uid = su.j && su.j.localId;
    log('Create owner account -> HTTP ' + su.s + (uid ? '' : ' (' + mask((su.j && su.j.error && su.j.error.message) || su.t).slice(0, 140) + ')'));
    if (!uid && su.j && su.j.error && /EMAIL_EXISTS/.test(su.j.error.message || '')) log('That email already has an account but the password did not match. Run the script again with the right password.');
    if (!uid && su.j && su.j.error && /OPERATION_NOT_ALLOWED|CONFIGURATION_NOT_FOUND/.test(su.j.error.message || '')) log('Email/Password sign-in is not switched on yet (the browser step). Switch it on, then run this script again.');
  }
  // 4. close public sign-ups
  r = await call('PATCH', `https://identitytoolkit.googleapis.com/admin/v2/projects/${PROJECT}/config?updateMask=client.permissions.disabledUserSignup`, { client: { permissions: { disabledUserSignup: true } } });
  log('Close public sign-ups -> HTTP ' + r.s + (r.s === 200 ? '' : ' (' + mask((r.j && r.j.error && r.j.error.message) || r.t).slice(0, 120) + ') - not critical, rules only trust your owner id'));
  // 5. save the owner id here and the public key in the database
  const dir = path.join(os.homedir(), '.lvr'); fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, 'owner-uid'), uid + '\n', { mode: 0o600 });
  log('Saved your owner id on this Mac (' + path.join(dir, 'owner-uid') + ')');
  const w = await fetch(`${DB}/ownerAuth/apiKey.json?access_token=${encodeURIComponent(TOKEN)}`, { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(KEY) });
  log('Store the web key for the admin page -> HTTP ' + w.status);
  log(w.status === 200 ? 'OWNER SETUP DONE. Open the Points admin: you will see an "Owner sign-in" button at the bottom right.' : 'Owner account is ready, but the web key was not stored. Tell Claude.');
  await report();
})();
NODE
node /tmp/owner-setup.js
