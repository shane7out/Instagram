#!/bin/bash
# Run on the Mac (one command):
#   curl -sL --retry 8 --retry-delay 1 --connect-timeout 15 --speed-limit 3000 --speed-time 6 --max-time 150 "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/owner-password-reset.sh?$(date +%s)" -o /tmp/owner-password-reset.sh && bash /tmp/owner-password-reset.sh
#
# For when you forgot your OWNER email and/or password. It uses your Google sign-in on this Mac (gcloud), so it needs no old password:
#   1. finds your owner login (the saved owner id in ~/.lvr/owner-uid),
#   2. SHOWS YOU the owner email on this screen only (it is not saved, not sent, not written in the report),
#   3. lets you type a NEW owner password (twice, hidden). The password goes only to Google's sign-in service,
#   4. then offers to run the Treasury rules step right away.
# It changes nothing else: no database rules, no data, no PIN.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
cat > /tmp/owner-password-reset.js <<'NODE'
const { execSync } = require('child_process');
const fs = require('fs'), os = require('os'), path = require('path');
const PROJECT = 'lvr-data-a60c1', DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
function ask(q, hidden) {
  const fd = fs.openSync('/dev/tty', 'r'); process.stdout.write(q);
  if (hidden) { try { execSync('stty -echo < /dev/tty'); } catch (e) {} }
  let buf = '', b = Buffer.alloc(1);
  while (fs.readSync(fd, b, 0, 1) > 0) { const c = b.toString(); if (c === '\n') break; buf += c; }
  if (hidden) { try { execSync('stty echo < /dev/tty'); } catch (e) {} process.stdout.write('\n'); }
  fs.closeSync(fd); return buf.replace(/\r/g, '');
}
(async () => {
  let TOKEN = ''; try { TOKEN = execSync('gcloud auth print-access-token', { stdio: ['ignore', 'pipe', 'ignore'] }).toString().trim(); } catch (e) {}
  if (!TOKEN) { console.log('No gcloud login found on this Mac - nothing changed.'); return; }
  const uidFile = path.join(os.homedir(), '.lvr', 'owner-uid');
  if (!fs.existsSync(uidFile)) { console.log('No saved owner id on this Mac (run owner-setup.sh instead) - nothing changed.'); return; }
  const UID = fs.readFileSync(uidFile, 'utf8').trim();
  if (!/^[A-Za-z0-9]{20,40}$/.test(UID)) { console.log('The saved owner id looks wrong - nothing changed.'); return; }
  const H = { Authorization: 'Bearer ' + TOKEN, 'x-goog-user-project': PROJECT, 'Content-Type': 'application/json' };
  const idt = 'https://identitytoolkit.googleapis.com/v1';
  const post = async (url, body) => { try { const r = await fetch(url, { method: 'POST', headers: H, body: JSON.stringify(body) }); const j = await r.json().catch(() => ({})); return { s: r.status, j }; } catch (e) { return { s: 0, j: {} }; } };
  const lk = await post(`${idt}/projects/${PROJECT}/accounts:lookup`, { localId: [UID] });
  const u = lk.s === 200 && lk.j.users && lk.j.users[0];
  if (!u || !u.email) { console.log('Could not find the owner login (HTTP ' + lk.s + ') - nothing changed.'); return; }
  console.log('\nYour OWNER email is:\n\n      ' + u.email + '\n\n(Shown only on this screen. Write it down somewhere safe, not in the chat.)\n');
  const go = ask('Set a NEW owner password now? y/N: ', false).trim();
  if (!/^y/i.test(go)) { console.log('OK - nothing changed. You can use your old password if you remember it.'); return; }
  let p1 = '', ok = false;
  for (let t = 0; t < 3 && !ok; t++) {
    p1 = ask('Type a NEW owner password (at least 10 characters, hidden): ', true);
    const p2 = ask('Type it again: ', true);
    if (p1.length < 10) console.log('Too short - at least 10 characters, please.');
    else if (p1 !== p2) console.log('The two did not match.');
    else ok = true;
  }
  if (!ok) { console.log('Nothing changed.'); return; }
  const up = await post(`${idt}/projects/${PROJECT}/accounts:update`, { localId: UID, password: p1 });
  p1 = '';
  if (up.s !== 200) { console.log('Could not set the password (HTTP ' + up.s + ') - nothing changed.'); return; }
  console.log('The new owner password is set. Use the email above and the password you just typed.');
  const run = ask('\nRun the Treasury rules step now? y/N: ', false).trim();
  if (/^y/i.test(run)) { try { execSync('curl -sL --retry 8 --retry-delay 1 --connect-timeout 15 --speed-limit 3000 --speed-time 6 --max-time 150 "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/deploy-key-rules.sh?$(date +%s)" -o /tmp/deploy-key-rules.sh && bash /tmp/deploy-key-rules.sh', { stdio: 'inherit' }); } catch (e) { console.log('The rules step did not finish - run it again.'); } }
})();
NODE
node /tmp/owner-password-reset.js
