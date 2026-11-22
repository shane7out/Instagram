/* Emulator test for the key_dine rules (receipt claims for restaurant offers). Run by run-dine-rules-test.sh */
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
  ok ? pass++ : fail++; console.log((ok ? 'PASS' : 'FAIL') + '  [' + who + '] ' + name + (ok ? '' : '  (HTTP ' + r.s + ' ' + r.t.replace(/\s+/g," ").slice(0, 200) + ')'));
};
const O = '/key_dine/abcd1234efgh5678ijkl9012', R = O + '/receipts/r1';
const photo = 'data:image/jpeg;base64,' + 'A'.repeat(400);
const rec = (extra) => Object.assign({ first: 'Ann', last: 'Lee', email: 'ann@example.com', phone: '7025550100', at: { '.sv': 'timestamp' }, consent: true, photo }, extra || {});
(async () => {
  const mk = { rest: "Johnny Mac's", keys: 25, createdAt: { '.sv': 'timestamp' }, note: 'Show your receipt after you eat.' };
  await t('a stranger cannot make an offer', 'anon', 'PUT', O, mk, false);
  await t('a signed-in stranger cannot make an offer', 'other', 'PUT', O, mk, false);
  await t('the owner makes an offer', 'owner', 'PUT', O, mk, true);
  await t('the Treasury PIN account makes an offer', 'treasurer', 'PUT', '/key_dine/zzzz1234efgh5678ijkl9012', mk, true);
  await t('fractional keys are refused', 'owner', 'PUT', '/key_dine/frac12345frac12345frac1', Object.assign({}, mk, { keys: 1.5 }), false);
  await t('a stranger cannot read the offers', 'anon', 'GET', '/key_dine', undefined, false);
  await t('the page can read the restaurant name', 'anon', 'GET', O + '/rest', undefined, true, '"Johnny Mac\'s"');
  await t('the page can read the keys', 'anon', 'GET', O + '/keys', undefined, true, '25');
  await t('a receipt for an offer that does not exist is refused', 'anon', 'PUT', '/key_dine/nothere1234nothere1234no/receipts/r1', rec(), false);
  await t('a receipt without consent is refused', 'anon', 'PUT', R, rec({ consent: false }), false);
  await t('a receipt without a photo is refused', 'anon', 'PUT', R, (() => { const x = rec(); delete x.photo; return x; })(), false);
  await t('a photo that is not an image is refused', 'anon', 'PUT', R, rec({ photo: 'data:text/html;base64,' + 'A'.repeat(400) }), false);
  await t('an oversize photo is refused', 'anon', 'PUT', R, rec({ photo: 'data:image/jpeg;base64,' + 'A'.repeat(460000) }), false);
  await t('a bad email is refused', 'anon', 'PUT', R, rec({ email: 'nope' }), false);
  await t('a made-up time is refused', 'anon', 'PUT', R, rec({ at: 5 }), false);
  await t('a visitor cannot approve their own receipt', 'anon', 'PUT', R, rec({ status: 'approved', paid: true }), false);
  await t('extra fields are refused', 'anon', 'PUT', R, rec({ hack: 1 }), false);
  await t('a visitor sends a receipt', 'anon', 'PUT', R, rec({ rno: '10234' }), true);
  await t('the same receipt id cannot be overwritten', 'anon', 'PUT', R, rec({ first: 'Eve' }), false);
  await t('a second receipt from someone else is fine', 'anon', 'PUT', O + '/receipts/r2', rec({ first: 'Bob', email: 'bob@example.com' }), true);
  await t('a stranger cannot read the receipts', 'anon', 'GET', O + '/receipts', undefined, false);
  await t('a stranger cannot read one receipt', 'anon', 'GET', R, undefined, false);
  await t('the owner can read the receipts', 'owner', 'GET', O + '/receipts', undefined, true);
  await t('the Treasury PIN account can read the offers', 'treasurer', 'GET', '/key_dine', undefined, true);
  await t('the owner approves a receipt', 'owner', 'PATCH', R, { status: 'approved', paid: true, paidAt: { '.sv': 'timestamp' }, wallet: 'Ann Lee' }, true);
  await t('the owner can decline a receipt', 'owner', 'PATCH', O + '/receipts/r2', { status: 'declined' }, true);
  await t('an owner status other than approved/declined is refused', 'owner', 'PATCH', O + '/receipts/r2', { status: 'whatever' }, false);
  await t('the owner can close the offer', 'owner', 'PATCH', O, { open: false }, true);
  await t('receipts to a closed offer are refused', 'anon', 'PUT', O + '/receipts/r3', rec(), false);
  await t('a stranger cannot delete a receipt', 'anon', 'DELETE', R, undefined, false);
  console.log(`\n${pass} passed, ${fail} failed`); process.exit(fail ? 1 : 0);
})();
