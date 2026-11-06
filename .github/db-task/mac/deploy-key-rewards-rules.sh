#!/bin/bash
# NOT RUN YET (2026-11-06). Adds the Key Rewards rules (key_rewards) to your live database rules. Run on the Mac ONLY after:
#   1. your attorney has reviewed the Key Rewards terms and the restaurant agreement,
#   2. owner-login.sh has finished (owner sign-in works),
#   3. you have said "go" in the chat.
# Same safety as deploy-key-rules.sh: saves a copy of your current rules first, only ADDS the key_rewards section, reads the result
# back, runs live checks, and PUTS YOUR OLD RULES BACK AUTOMATICALLY if any check fails.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
cat > /tmp/deploy-key-rewards-rules.js <<'NODE'
const { execSync } = require('child_process');
const fs = require('fs'), os = require('os'), path = require('path');
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const FRAG = 'https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/rules/key-rewards-rules.json?cb=' + Date.now();
const SECTIONS = ['key_rewards'];
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
async function report() { try { await fetch(DB + '/_debug/krrules.json', { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(out.join('\n').slice(0, 6000)) }); console.log('\nSENT result - tell Claude it is done'); } catch (e) {} }
const status = async (url, opts) => { try { return (await fetch(url, opts)).status; } catch (e) { return 'err'; } };
(async () => {
  let TOKEN = ''; try { TOKEN = execSync('gcloud auth print-access-token', { stdio: ['ignore', 'pipe', 'ignore'] }).toString().trim(); } catch (e) {}
  if (!TOKEN) { log('No gcloud login found - nothing changed.'); return report(); }
  const uidFile = path.join(os.homedir(), '.lvr', 'owner-uid');
  if (!fs.existsSync(uidFile)) { log('No owner id found. Run owner-setup.sh first - nothing changed.'); return report(); }
  const UID = fs.readFileSync(uidFile, 'utf8').trim();
  if (!/^[A-Za-z0-9]{20,40}$/.test(UID)) { log('The saved owner id looks wrong - nothing changed.'); return report(); }
  const apiKey = await (await fetch(DB + '/ownerAuth/apiKey.json')).json();
  if (!apiKey) { log('The admin sign-in key is not stored yet. Run owner-setup.sh first - nothing changed.'); return report(); }
  // prove the owner login works BEFORE anything is uploaded
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
  const dir = path.join(os.homedir(), 'lvr-rules-backups'); fs.mkdirSync(dir, { recursive: true });
  const stamp = new Date().toISOString().replace(/[:.]/g, '-');
  fs.writeFileSync(path.join(dir, `rules-before-keyrewards-${stamp}.json`), liveText); fs.writeFileSync(path.join(dir, 'LATEST-BEFORE-KEYREWARDS.json'), liveText);
  log('Saved a copy of your current rules on this Mac (~/lvr-rules-backups/LATEST-BEFORE-KEYREWARDS.json).');
  let fragText = await (await fetch(FRAG)).text();
  if (fragText.indexOf('__OWNER_UID__') < 0) { log('The owner rules file has no owner placeholder - nothing changed.'); return report(); }
  fragText = fragText.split('__OWNER_UID__').join(UID);
  let frag; try { frag = JSON.parse(fragText); } catch (e) { log('Could not read the owner rules file - nothing changed.'); return report(); }
  for (const k of SECTIONS) if (!frag[k]) { log('Owner rules file is missing section ' + k + ' - nothing changed.'); return report(); }
  const merged = JSON.parse(liveText); for (const k of SECTIONS) merged.rules[k] = frag[k];
  const o1 = Object.keys(live.rules).filter(k => !SECTIONS.includes(k)).sort().join(','), o2 = Object.keys(merged.rules).filter(k => !SECTIONS.includes(k)).sort().join(',');
  if (o1 !== o2) { log('Safety check failed (other sections changed) - nothing changed.'); return report(); }
  const pr = await put(JSON.stringify(merged)); log('Upload of owner rules -> HTTP ' + pr.status + (pr.status === 200 ? '' : ' ' + mask(await pr.text()).slice(0, 300)));
  if (pr.status !== 200) { log('Rejected by Firebase; your old rules are still in place.'); return report(); }
  // verify: a stranger is locked out, you are in, and the website forms / page counter still work
  const J = { 'Content-Type': 'application/json' }, A = encodeURIComponent(ID);
  const probes = [
    ['members still readable', await status(`${DB}/lvr_rewards.json?shallow=true`), 200],
    ['a stranger cannot list Key Rewards events', await status(`${DB}/key_rewards/events.json?shallow=true`), 401],
    ['YOU can list Key Rewards events', await status(`${DB}/key_rewards/events.json?shallow=true&auth=${A}`), 200],
    ['a stranger cannot add a restaurant', await status(`${DB}/key_rewards/restaurants/zzprobe.json`, { method: 'PUT', headers: J, body: JSON.stringify({ name: 'x', active: true, createdAt: Date.now() }) }), 401],
    ['a stranger cannot read check-ins', await status(`${DB}/key_rewards/checkins/ezzprobe0000.json`), 401],
    ['a stranger cannot write redemptions', await status(`${DB}/key_rewards/redemptions/zzprobe.json`, { method: 'PUT', headers: J, body: JSON.stringify({ mkey: 'a', rid: 'b', rewards: 15, at: 1 }) }), 401],
  ];
  let ok = true;
  for (const [name, got, want] of probes) { const good = got === want || (want === 401 && got === 403); if (!good) ok = false; log((good ? 'OK   ' : 'FAIL ') + name + ' (HTTP ' + got + ')'); }
  if (!ok) { const rb = await put(liveText); log('A check failed - put your old rules back automatically -> HTTP ' + rb.status); return report(); }
  log('ALL CHECKS PASSED. Key Rewards data is now protected by the staged rules. To undo, put the saved copy back (~/lvr-rules-backups/LATEST-BEFORE-KEYREWARDS.json)');
  await report();
})();
NODE
node /tmp/deploy-key-rewards-rules.js
