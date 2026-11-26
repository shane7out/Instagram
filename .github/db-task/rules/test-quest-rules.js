/* Emulator test for the key_quest rules (the restaurant journey: players, receipts for each level). Run by run-quest-rules-test.sh */
const NS = 'demo-lvr-default-rtdb', BASE = 'http://127.0.0.1:9000';
const b64u = o => Buffer.from(JSON.stringify(o)).toString('base64url');
const jwt = uid => b64u({ alg: 'none', typ: 'JWT' }) + '.' + b64u({ uid, user_id: uid, sub: uid, iat: Math.floor(Date.now() / 1000) }) + '.';
const TOK = { owner: jwt('TESTOWNER'), treasurer: jwt('TESTTREASURER'), other: jwt('SOMEONE-ELSE') };
async function call(who, method, p, body) {
  const auth = TOK[who] ? '&auth=' + TOK[who] : '';
  const r = await fetch(`${BASE}${p}.json?ns=${NS}${auth}`, { method, headers: { 'Content-Type': 'application/json' }, body: body === undefined ? undefined : JSON.stringify(body) });
  return { s: r.status, t: await r.text() };
}
let pass = 0, fail = 0;
const t = async (name, who, method, p, body, allow, expectBody) => {
  const r = await call(who, method, p, body), ok = (r.s === 200) === allow && (expectBody === undefined || r.t === expectBody);
  ok ? pass++ : fail++; console.log((ok ? 'PASS' : 'FAIL') + '  [' + who + '] ' + name + (ok ? '' : '  (HTTP ' + r.s + ' ' + r.t.replace(/\s+/g, ' ').slice(0, 200) + ')'));
};
const PID = 'abcdefghij0123456789', PID2 = 'zyxwvutsrq9876543210';
const P = '/key_quest/players/' + PID, S = '/key_quest/subs/' + PID + '_1';
const photo = 'data:image/jpeg;base64,' + 'A'.repeat(400);
const player = (x) => Object.assign({ first: 'Ann', last: 'Lee', ig: 'annlee', level: 1, keys: 1, total: 3, createdAt: { '.sv': 'timestamp' }, stopName: "Johnny Mac's", stopIg: 'johnnymacs', stopNote: 'Try the hibachi.' }, x || {});
const sub = (x) => Object.assign({ pid: PID, n: 1, photo, spentCents: 1250, photoAt: Date.now() - 60000, at: { '.sv': 'timestamp' } }, x || {});
(async () => {
  await t('a stranger cannot make a player', 'anon', 'PUT', P, player(), false);
  await t('a signed-in stranger cannot make a player', 'other', 'PUT', P, player(), false);
  await t('the owner makes a player', 'owner', 'PUT', P, player(), true);
  await t('the Treasury PIN account makes a player', 'treasurer', 'PUT', '/key_quest/players/' + PID2, player({ first: 'Bo' }), true);
  await t('a player with level 0 is refused', 'owner', 'PUT', '/key_quest/players/q1q1q1q1q1q1q1q1q1q1', player({ level: 0 }), false);
  await t('a player with fractional keys is refused', 'owner', 'PUT', '/key_quest/players/q2q2q2q2q2q2q2q2q2q2', player({ keys: 1.5 }), false);
  await t('a player with an unknown field is refused', 'owner', 'PUT', '/key_quest/players/q3q3q3q3q3q3q3q3q3q3', player({ secret: 'x' }), false);
  await t('the player can read their own journey by the private link', 'anon', 'GET', P + '/level', undefined, true, '1');
  await t('a stranger cannot list the players', 'anon', 'GET', '/key_quest/players', undefined, false);
  await t('a stranger cannot read the whole quest folder', 'anon', 'GET', '/key_quest', undefined, false);
  await t('a stranger cannot read the receipts', 'anon', 'GET', '/key_quest/subs', undefined, false);
  await t('a stranger cannot change their own level', 'anon', 'PATCH', P, { level: 2 }, false);
  await t('a stranger cannot give themselves keys', 'anon', 'PATCH', P, { keys: 99999 }, false);
  await t('the owner moves the master list (stops)', 'owner', 'PUT', '/key_quest/stops/s1', { name: "Johnny Mac's", order: 1 }, true);
  await t('a stranger cannot read the master list', 'anon', 'GET', '/key_quest/stops', undefined, false);
  await t('a stranger cannot write the master list', 'anon', 'PUT', '/key_quest/stops/s9', { name: 'x', order: 9 }, false);
  // receipts
  await t('a receipt for a player that does not exist is refused', 'anon', 'PUT', '/key_quest/subs/nobodynobodynobody00_1', sub({ pid: 'nobodynobodynobody00' }), false);
  await t('a receipt for the wrong level is refused', 'anon', 'PUT', S, sub({ n: 2 }), false);
  await t('a receipt without a photo is refused', 'anon', 'PUT', S, (() => { const x = sub(); delete x.photo; return x; })(), false);
  await t('a photo that is not an image is refused', 'anon', 'PUT', S, sub({ photo: 'data:text/html;base64,' + 'A'.repeat(400) }), false);
  await t('an oversize photo is refused', 'anon', 'PUT', S, sub({ photo: 'data:image/jpeg;base64,' + 'A'.repeat(460000) }), false);
  await t('an amount of zero is refused', 'anon', 'PUT', S, sub({ spentCents: 0 }), false);
  await t('a made-up time is refused', 'anon', 'PUT', S, sub({ at: 5 }), false);
  await t('a receipt cannot approve itself', 'anon', 'PUT', S, sub({ status: 'approved' }), false);
  await t('a receipt with an extra field is refused', 'anon', 'PUT', S, sub({ hack: 1 }), false);
  await t('the player sends their receipt for level 1', 'anon', 'PUT', S, sub(), true);
  await t('the same receipt cannot be overwritten', 'anon', 'PUT', S, sub({ spentCents: 99 }), false);
  await t('a stranger cannot approve the receipt', 'anon', 'PATCH', S, { status: 'approved' }, false);
  await t('the owner approves the receipt', 'owner', 'PATCH', S, { status: 'approved', amountCents: 1250, decidedAt: { '.sv': 'timestamp' } }, true);
  await t('the owner reads all the receipts', 'owner', 'GET', '/key_quest/subs', undefined, true);
  await t('the owner moves the player to level 2', 'owner', 'PATCH', P, { level: 2, keys: 26, stopName: 'Wings Korean Chicken', stopIg: 'wingskoreanchicken', lastAt: { '.sv': 'timestamp' } }, true);
  await t('a level 1 receipt is refused now that the player is on level 2', 'anon', 'PUT', '/key_quest/subs/' + PID + '_1b', sub(), false);
  await t('the player sends a level 2 receipt', 'anon', 'PUT', '/key_quest/subs/' + PID + '_2', sub({ n: 2 }), true);
  await t('the owner declines (removes) a receipt so it can be sent again', 'owner', 'DELETE', '/key_quest/subs/' + PID + '_2', undefined, true);
  await t('the player can send level 2 again after a decline', 'anon', 'PUT', '/key_quest/subs/' + PID + '_2', sub({ n: 2 }), true);
  await t('the owner finishes the journey', 'owner', 'PATCH', P, { done: true }, true);
  await t('a finished player cannot send more receipts', 'anon', 'PUT', '/key_quest/subs/' + PID + '_3', sub({ n: 2 }), false);
  console.log(`\n${pass} passed, ${fail} failed`);
  process.exit(fail ? 1 : 0);
})();
