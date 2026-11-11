/* Tests for lvr-rules-private.json (member data protection, plan step 1). Run: bash .github/db-task/rules/run-private-rules-test.sh
   Tokens as in test-owner-rules.js: anon = no token, owner = uid TESTOWNER, other = a signed-in stranger, admin = emulator bypass (seeding). */
const NS = 'demo-lvr-default-rtdb';
const BASE = 'http://127.0.0.1:9000';
const b64u = o => Buffer.from(JSON.stringify(o)).toString('base64url');
const jwt = uid => b64u({ alg: 'none', typ: 'JWT' }) + '.' + b64u({ uid: uid, user_id: uid, sub: uid, iat: Math.floor(Date.now() / 1000) }) + '.';
const OWNER_JWT = jwt('TESTOWNER'), OTHER_JWT = jwt('SOMEONE-ELSE');
async function call(who, method, p, body, q) {
  const auth = who === 'owner' ? '&auth=' + OWNER_JWT : who === 'other' ? '&auth=' + OTHER_JWT : '';
  const r = await fetch(`${BASE}${p}.json?ns=${NS}${auth}${q || ''}`, { method, headers: Object.assign({ 'Content-Type': 'application/json' }, who === 'admin' ? { Authorization: 'Bearer owner' } : {}), body: body === undefined ? undefined : JSON.stringify(body) });
  return { s: r.status, t: await r.text() };
}
let pass = 0, fail = 0;
function check(name, res, allow) { const ok = (res.s === 200) === allow; ok ? pass++ : fail++; console.log((ok ? 'PASS' : 'FAIL') + '  ' + name + '  [' + (res.s === 200 ? 'allowed' : 'denied') + (ok ? '' : ', expected ' + (allow ? 'allowed' : 'denied') + ' HTTP ' + res.s + ' ' + res.t.slice(0, 80)) + ']'); }
const t = async (name, who, method, p, body, allow, q) => check('[' + who + '] ' + name, await call(who, method, p, body, q), allow);
const TOK = 'tokAAAAAAAAAAAAAAAAAAAA', TOK2 = 'tokBBBBBBBBBBBBBBBBBBBB';
(async () => {
  // seed (admin): two members in the NEW layout (no phone/token in the public record) + their private nodes
  await call('admin', 'PUT', '/lvr_rewards/K1', { name: 'Kayla R.', instagram: '@kayla', points: 120, status: 'approved', refCode: 'KAYLA1', joinedAt: 1 });
  await call('admin', 'PUT', '/lvr_rewards/K2', { name: 'Zed Q.', points: 0, status: 'pending', refCode: 'ZED22', joinedAt: 2 });
  await call('admin', 'PUT', '/lvr_member_private/' + TOK, { memberKey: 'K1', phone: '555-0101', email: 'k@example.com', birthday: '1990-05-05' });
  await call('admin', 'PUT', '/lvr_refcodes/KAYLA1', 'K1');

  // 1. nobody can download the member list any more
  await t('list all members', 'anon', 'GET', '/lvr_rewards', undefined, false);
  await t('list all members (signed-in stranger)', 'other', 'GET', '/lvr_rewards', undefined, false);
  await t('shallow member count', 'anon', 'GET', '/lvr_rewards', undefined, false, '&shallow=true');
  await t('find member by token query', 'anon', 'GET', '/lvr_rewards', undefined, false, '&orderBy="token"&equalTo="x"');
  await t('find member by refCode query', 'anon', 'GET', '/lvr_rewards', undefined, false, '&orderBy="refCode"&equalTo="KAYLA1"');
  await t('owner can list members', 'owner', 'GET', '/lvr_rewards', undefined, true);
  // 2. one member by exact key still readable (leaderboard / restaurant views / the app after it knows the key)
  await t('read one member by key', 'anon', 'GET', '/lvr_rewards/K1', undefined, true);
  await t('read one member points', 'anon', 'GET', '/lvr_rewards/K1/points', undefined, true);
  const pub = await call('anon', 'GET', '/lvr_rewards/K1');
  const leaks = ['phone', 'email', 'birthday', 'token', 'consent'].filter(k => pub.t.includes(k));
  check('public record contains no phone/email/birthday/token', { s: leaks.length ? 500 : 200, t: leaks.join(',') }, true);
  // 3. private node
  await t('list private nodes', 'anon', 'GET', '/lvr_member_private', undefined, false);
  await t('list private nodes (signed-in stranger)', 'other', 'GET', '/lvr_member_private', undefined, false);
  await t('private query', 'anon', 'GET', '/lvr_member_private', undefined, false, '&orderBy="memberKey"&equalTo="K1"');
  await t('member reads own private node by token path', 'anon', 'GET', '/lvr_member_private/' + TOK, undefined, true);
  await t('wrong token path reads nothing sensitive', 'anon', 'GET', '/lvr_member_private/tokZZZZZZZZZZZZZZZZZZZZ', undefined, true); // allowed but empty
  const empty = await call('anon', 'GET', '/lvr_member_private/tokZZZZZZZZZZZZZZZZZZZZ');
  check('wrong token returns null', { s: empty.t.trim() === 'null' ? 200 : 500, t: empty.t }, true);
  await t('owner lists all private nodes', 'owner', 'GET', '/lvr_member_private', undefined, true);
  // sign-up writes
  await t('sign-up creates a private node', 'anon', 'PUT', '/lvr_member_private/' + TOK2, { memberKey: 'K2', phone: '555-0202', email: 'z@example.com', birthday: '1988-01-01' }, true);
  await t('cannot overwrite an existing private node with another member key', 'anon', 'PUT', '/lvr_member_private/' + TOK, { memberKey: 'K2', phone: '555-9999' }, false);
  await t('member can update own private fields (same member key)', 'anon', 'PATCH', '/lvr_member_private/' + TOK, { anniversary: '2015-06-06' }, true);
  await t('stranger cannot delete a private node', 'anon', 'DELETE', '/lvr_member_private/' + TOK, undefined, false);
  await t('signed-in stranger cannot delete a private node', 'other', 'DELETE', '/lvr_member_private/' + TOK, undefined, false);
  await t('token path too short is refused', 'anon', 'PUT', '/lvr_member_private/short', { memberKey: 'K9' }, false);
  await t('record without memberKey is refused', 'anon', 'PUT', '/lvr_member_private/tokCCCCCCCCCCCCCCCCCCCC', { phone: '1' }, false);
  await t('oversized phone refused', 'anon', 'PUT', '/lvr_member_private/tokDDDDDDDDDDDDDDDDDDDD', { memberKey: 'K9', phone: 'x'.repeat(50) }, false);
  await t('owner can delete a private node', 'owner', 'DELETE', '/lvr_member_private/' + TOK2, undefined, true);
  // 4. referral codes by exact path
  await t('list referral codes', 'anon', 'GET', '/lvr_refcodes', undefined, false);
  await t('look up one referral code', 'anon', 'GET', '/lvr_refcodes/KAYLA1', undefined, true);
  await t('register own referral code (matches the member record)', 'anon', 'PUT', '/lvr_refcodes/ZED22', 'K2', true);
  await t('cannot register a code the member record does not hold', 'anon', 'PUT', '/lvr_refcodes/FAKE99', 'K2', false);
  await t('cannot take over an existing code', 'anon', 'PUT', '/lvr_refcodes/KAYLA1', 'K2', false);
  await t('stranger cannot delete a code', 'anon', 'DELETE', '/lvr_refcodes/KAYLA1', undefined, false);
  await t('owner can delete a code', 'owner', 'DELETE', '/lvr_refcodes/KAYLA1', undefined, true);
  // 4b. hashed duplicate index and round1 referredBy
  const H1 = 'a'.repeat(64);
  await t('list the duplicate index', 'anon', 'GET', '/lvr_member_idx', undefined, false);
  await t('register a phone hash for a member', 'anon', 'PUT', '/lvr_member_idx/' + H1, 'K2', true);
  await t('read one hash entry', 'anon', 'GET', '/lvr_member_idx/' + H1, undefined, true);
  await t('cannot overwrite a hash entry', 'anon', 'PUT', '/lvr_member_idx/' + H1, 'K3', false);
  await t('hash key must be 64 characters', 'anon', 'PUT', '/lvr_member_idx/short', 'K2', false);
  await t('round1 entry with referredBy (sign-up)', 'anon', 'PUT', '/lvr_points/round1/K5', { name: 'Ref P.', at: { '.sv': 'timestamp' }, status: 'pending', referredBy: 'K1' }, true);
  await t('round1 entry with an unknown extra field is still refused', 'anon', 'PUT', '/lvr_points/round1/K6', { name: 'X', at: { '.sv': 'timestamp' }, status: 'pending', junk: 'x' }, false);
  // 5. member sign-up and the rest of the program keep working (rules inherited from the owner rules)
  await t('new member sign-up record (pending, 0 points, no phone)', 'anon', 'PUT', '/lvr_rewards/K3', { name: 'New P.', points: 0, status: 'pending', joinedAt: 3, refCode: 'NEWP33' }, true);
  await t('sign-up cannot start approved with points', 'anon', 'PUT', '/lvr_rewards/K4', { name: 'Cheat', points: 500, status: 'approved' }, false);
  await t('member points update still works (known open gap: needs server code)', 'anon', 'PUT', '/lvr_rewards/K1/points', 100, true);
  await t('leaderboard registry still public', 'anon', 'GET', '/lvr_points/round1', undefined, true);
  await t('settings still public to read', 'anon', 'GET', '/lvr_points/settings', undefined, true);
  await t('stranger cannot change settings', 'anon', 'PUT', '/lvr_points/settings/welcome', { amount: 1 }, false);
  console.log('\n' + pass + ' passed, ' + fail + ' failed');
  process.exit(fail ? 1 : 0);
})();
