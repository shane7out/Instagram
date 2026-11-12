#!/bin/bash
# DO NOT RUN until Shane says go. Run on the Mac (one command), AFTER deploy-rewards-admin.sh and deploy-dashboard-owner-auth.sh and backup-setup.sh:
#   curl -sL "https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/mac/member-data-cutover.sh?$(date +%s)" -o /tmp/member-data-cutover.sh && bash /tmp/member-data-cutover.sh
#
# MEMBER DATA PROTECTION, steps 5 + 6 (plan: docs/key-integration/MEMBER_DATA_PLAN.md). In this order, stopping at the first problem:
#   0. signs you in (your owner email + password are typed here, nothing is stored), then saves a backup of the member data on THIS Mac (~/lvr-backups/member-move-<date>/)
#   1. shows what would change (counts only) and waits for you to type MOVE
#   2. COPIES each member's phone / email / birthday / link token into the hidden spot, adds their referral code, duplicate-check hash and leaderboard entry (adds only, nothing is removed)
#   3. re-reads every copy and compares it with the original; stops if even one does not match
#   4. installs the new database rules (member list closed to everyone but you); puts your old rules back AUTOMATICALLY if any check fails
#   5. adds "who invited me" to the leaderboard, switches the new sign-up layout on, and only THEN removes phone / email / birthday / token from the public member records (only for members whose copy matched)
#   6. checks from the outside, like a stranger, that the list is closed and nothing private is readable
# Prints only counts, never names, phones, emails or tokens.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
RAWB="https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task"
curl -sL -o /tmp/member-data-lib.js "$RAWB/mac/member-data-lib.js?cb=$(date +%s)"
[ -s /tmp/member-data-lib.js ] || { echo "Could not download the helper - nothing changed."; exit 1; }
cat > /tmp/member-data-cutover.js <<'NODE'
const { execSync } = require('child_process');
const fs = require('fs'), os = require('os'), path = require('path'), zlib = require('zlib');
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const FRAG = 'https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/rules/lvr-rules-private.json?cb=' + Date.now();
const SECTIONS = ['lvr_points', 'lvr_rewards', 'lvr_instagram_index', 'lvr_coupons', 'lvr_member_private', 'lvr_refcodes', 'lvr_member_idx'];
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
async function report() { try { await fetch(DB + '/_debug/cutover.json', { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(out.join('\n').slice(0, 6000)) }); console.log('\nSENT result - tell Claude "done".'); } catch (e) { console.log('\n(could not send result; copy the text above to Claude)'); } }
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
  const email = ask('Owner email: ', false).trim().toLowerCase(), pw = ask('Owner password (hidden): ', true);
  const si = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${encodeURIComponent(apiKey)}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, password: pw, returnSecureToken: true }) });
  const sj = await si.json().catch(() => ({}));
  if (!si.ok || !sj.idToken) { log('Owner sign-in failed (HTTP ' + si.status + ') - nothing changed.'); return report(); }
  if (sj.localId !== UID) { log('Signed in, but the owner id does not match the saved one - nothing changed.'); return report(); }
  const ID = sj.idToken; log('Owner sign-in works.');
  const L = require('/tmp/member-data-lib.js')({ DB, fetch, idToken: ID, log });
  const A = '?auth=' + encodeURIComponent(ID), J = { 'Content-Type': 'application/json' };

  // 0. backup on this Mac
  const stamp = new Date().toISOString().replace(/[:.]/g, '-'), dir = path.join(os.homedir(), 'lvr-backups', 'member-move-' + stamp); fs.mkdirSync(dir, { recursive: true, mode: 0o700 });
  for (const n of ['lvr_rewards', 'lvr_points/round1', 'lvr_member_private', 'lvr_refcodes', 'lvr_member_idx']) {
    const r = await fetch(DB + '/' + n + '.json' + A); if (!r.ok) { log('Could not read ' + n + ' for the backup (HTTP ' + r.status + ') - nothing changed.'); return report(); }
    const t = await r.text(); fs.writeFileSync(path.join(dir, n.replace(/\//g, '_') + '.json.gz'), zlib.gzipSync(Buffer.from(t)), { mode: 0o600 });
  }
  const files = fs.readdirSync(dir); if (files.length !== 5 || files.some(f => fs.statSync(path.join(dir, f)).size < 20)) { log('Backup looks incomplete - nothing changed.'); return report(); }
  log('Backup saved on this Mac: ' + dir.replace(os.homedir(), '~') + ' (5 files).');

  // 1. plan
  const pl = await L.plan(); log('What would change: ' + JSON.stringify(pl.p));
  if (pl.p.conflict) { log('Some hidden records belong to a different member than their link says (' + pl.p.conflict + ') - stopping, nothing changed.'); return report(); }
  const go = ask('\nType MOVE (capital letters) and press Return to copy the data and switch the rules on, or just press Return to stop: ', false).trim();
  if (go !== 'MOVE') { log('Stopped. Nothing was changed.'); return report(); }

  // sample member for the outside probes (kept in memory only)
  const sampleKey = Object.keys(pl.members).find(k => pl.members[k] && pl.members[k].token && pl.members[k].refCode);
  const sample = sampleKey ? { key: sampleKey, token: pl.members[sampleKey].token, code: pl.members[sampleKey].refCode } : null;

  // 2-3. copy then verify
  const cp = await L.copy(); log('Copied (added only): ' + JSON.stringify(cp.done));
  const v = await L.verify(); log('Copies re-read and compared: ' + v.ok + ' match, ' + v.bad + ' do not.');
  if (v.bad) { log('A copy did not match - STOPPING before the rules change. Public records are untouched.'); return report(); }

  // 4. rules (same safety as deploy-owner-rules.sh)
  const rulesUrl = `${DB}/.settings/rules.json?access_token=${encodeURIComponent(TOKEN)}`;
  const put = body => fetch(rulesUrl, { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body });
  const liveText = await (await fetch(rulesUrl)).text();
  let live; try { live = JSON.parse(liveText); } catch (e) { log('Could not read current rules - stopping (copies are harmless and stay).'); return report(); }
  const rdir = path.join(os.homedir(), 'lvr-rules-backups'); fs.mkdirSync(rdir, { recursive: true });
  fs.writeFileSync(path.join(rdir, 'rules-before-private-' + stamp + '.json'), liveText); fs.writeFileSync(path.join(rdir, 'LATEST-BEFORE-PRIVATE.json'), liveText);
  log('Saved a copy of your current rules (~/lvr-rules-backups/LATEST-BEFORE-PRIVATE.json).');
  let fragText = await (await fetch(FRAG)).text();
  if (fragText.indexOf('__OWNER_UID__') < 0) { log('The rules file has no owner placeholder - stopping.'); return report(); }
  fragText = fragText.split('__OWNER_UID__').join(UID);
  let frag; try { frag = JSON.parse(fragText); } catch (e) { log('Could not read the new rules file - stopping.'); return report(); }
  for (const k of SECTIONS) if (!frag[k]) { log('New rules file is missing section ' + k + ' - stopping.'); return report(); }
  const merged = JSON.parse(liveText); for (const k of SECTIONS) merged.rules[k] = frag[k];
  const o1 = Object.keys(live.rules).filter(k => !SECTIONS.includes(k)).sort().join(','), o2 = Object.keys(merged.rules).filter(k => !SECTIONS.includes(k)).sort().join(',');
  if (o1 !== o2) { log('Safety check failed (other sections changed) - stopping.'); return report(); }
  const pr = await put(JSON.stringify(merged)); log('Upload of the new rules -> HTTP ' + pr.status + (pr.status === 200 ? '' : ' ' + mask(await pr.text()).slice(0, 300)));
  if (pr.status !== 200) { log('Rejected by Firebase; your old rules are still in place.'); return report(); }
  const probes = [
    ['stranger cannot list members', await status(`${DB}/lvr_rewards.json?shallow=true`), 401],
    ['stranger cannot list hidden records', await status(`${DB}/lvr_member_private.json`), 401],
    ['stranger cannot list referral codes', await status(`${DB}/lvr_refcodes.json`), 401],
    ['stranger cannot list the duplicate index', await status(`${DB}/lvr_member_idx.json`), 401],
    ['YOU can list members', await status(`${DB}/lvr_rewards.json${A}&shallow=true`), 200],
    ['YOU can list hidden records', await status(`${DB}/lvr_member_private.json${A}&shallow=true`), 200],
    ['leaderboard still public', await status(`${DB}/lvr_points/round1.json?shallow=true`), 200],
    ['settings still public to read', await status(`${DB}/lvr_points/settings.json?shallow=true`), 200],
    ['a stranger cannot change settings', await status(`${DB}/lvr_points/settings/zz_probe.json`, { method: 'PUT', headers: J, body: '1' }), 401],
    ['YOU can change settings', await status(`${DB}/lvr_points/settings/zz_probe.json${A}`, { method: 'PUT', headers: J, body: '1' }), 200],
  ];
  if (sample) {
    probes.push(['one member readable by key', await status(`${DB}/lvr_rewards/${encodeURIComponent(sample.key)}/points.json`), 200]);
    probes.push(['personal link finds its hidden record', await status(`${DB}/lvr_member_private/${encodeURIComponent(sample.token)}.json`), 200]);
    probes.push(['referral code lookup works', await status(`${DB}/lvr_refcodes/${encodeURIComponent(sample.code)}.json`), 200]);
  }
  await status(`${DB}/lvr_points/settings/zz_probe.json${A}`, { method: 'DELETE' });
  let ok = true;
  for (const [name, got, want] of probes) { const good = got === want || (want === 401 && got === 403); if (!good) ok = false; log((good ? 'OK   ' : 'FAIL ') + name + ' (HTTP ' + got + ')'); }
  if (!ok) { const rb = await put(liveText); log('A check failed - put your old rules back automatically -> HTTP ' + rb.status + '. The copies stay (harmless); public records are untouched.'); return report(); }
  log('New rules are live and every check passed.');

  // 5. leaderboard invites, new layout on, then remove the old public fields (only verified members)
  const rf = await L.refs(); log('Leaderboard "invited by" added: ' + JSON.stringify(rf));
  const fl = await status(`${DB}/lvr_points/settings/privateLayout.json${A}`, { method: 'PUT', headers: J, body: 'true' }); log('New sign-up layout switched on -> HTTP ' + fl);
  const st = await L.strip(); log('Removed phone/email/birthday/anniversary/token from the public records: ' + JSON.stringify(st));

  // 6. outside check
  const ou = await L.outside(Object.keys(pl.members)); log('Outside check (a stranger): ' + JSON.stringify(ou));
  const clean = ou.leakedFields === 0 && [401, 403].includes(ou.listMembers) && [401, 403].includes(ou.listPrivate);
  log(clean ? 'DONE. The member list is closed and no private field is readable from outside. Your backup is in ' + dir.replace(os.homedir(), '~') + '. To undo the rules only: bash undo-private-rules.sh' : 'FINISHED WITH A WARNING: copy this text to Claude (something is still readable).');
  await report();
})().catch(async e => { log('Stopped by an error: ' + mask(e.message)); await report(); });
NODE
node /tmp/member-data-cutover.js
