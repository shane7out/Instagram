/* Emulator test for the lvr_coupons rules: public offer page, private customer data. Run by run-coupon-rules-test.sh */
const NS = 'demo-lvr-default-rtdb', BASE = 'http://127.0.0.1:9000';
const b64u = o => Buffer.from(JSON.stringify(o)).toString('base64url');
const jwt = uid => b64u({ alg: 'none', typ: 'JWT' }) + '.' + b64u({ uid, user_id: uid, sub: uid, iat: Math.floor(Date.now() / 1000) }) + '.';
const TOK = { owner: jwt('TESTOWNER'), other: jwt('SOMEONE-ELSE') };
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
const EK = 'a'.repeat(32), EK2 = 'b'.repeat(32), PK = 'c'.repeat(32), PK2 = 'd'.repeat(32), PK3 = 'e'.repeat(32);
const claim = (x) => Object.assign({ biz: 'van', name: 'Ann Lee', email: 'ann@example.com', phone: '7025550100', marketingOptIn: true, smsOptIn: true, consentText: 'I agree to receive texts from Vanilla Rice and Las Vegas Restaurants. Reply STOP to opt out.', consentVer: 'sms1', code: 'VAN-7K3P9', redeemed: false, createdAt: { '.sv': 'timestamp' }, ek: EK, pk: PK }, x || {});
const upd = (id, ek, c, extra) => Object.assign({ ['claims/van/' + id]: c, ['idx/van/' + ek]: { code: c.code, id }, ['idx/van/' + c.pk]: { code: c.code, id } }, extra || {});
(async () => {
  const prog = { bizName: 'Vanilla Rice', offer: 'Free bowl', maxClaims: 2, active: true, staffKeys: 2 };
  await t('a stranger cannot create a program', 'anon', 'PUT', '/lvr_coupons/programs/van', prog, false);
  await t('a signed-in stranger cannot create a program', 'other', 'PUT', '/lvr_coupons/programs/van', prog, false);
  await t('the owner creates a program', 'owner', 'PUT', '/lvr_coupons/programs/van', prog, true);
  await t('the owner creates a paused program', 'owner', 'PUT', '/lvr_coupons/programs/off', Object.assign({}, prog, { active: false }), true);
  await t('anyone can read the offer', 'anon', 'GET', '/lvr_coupons/programs/van/offer', undefined, true, '"Free bowl"');
  await t('a stranger cannot change an offer', 'anon', 'PUT', '/lvr_coupons/programs/van/offer', 'Free everything', false);
  await t('a stranger cannot read any claims', 'anon', 'GET', '/lvr_coupons/claims', undefined, false);
  await t('a stranger cannot read the claims of one restaurant', 'anon', 'GET', '/lvr_coupons/claims/van', undefined, false);
  await t('a stranger cannot list the duplicate-check folder', 'anon', 'GET', '/lvr_coupons/idx/van', undefined, false);
  await t('a stranger cannot read the whole coupon folder', 'anon', 'GET', '/lvr_coupons', undefined, false);
  // claims
  await t('a claim written without its duplicate-check entry is refused', 'anon', 'PUT', '/lvr_coupons/claims/van/c1c1c1c1c1', claim(), false);
  await t('a duplicate-check entry written without a claim is refused', 'anon', 'PUT', '/lvr_coupons/idx/van/' + EK, { code: 'VAN-7K3P9', id: 'c1c1c1c1c1' }, false);
  await t('a claim for a program that does not exist is refused', 'anon', 'PATCH', '/lvr_coupons', { 'claims/nope/c1c1c1c1c1': claim({ biz: 'nope' }), ['idx/nope/' + EK]: { code: 'VAN-7K3P9', id: 'c1c1c1c1c1' }, ['idx/nope/' + PK]: { code: 'VAN-7K3P9', id: 'c1c1c1c1c1' } }, false);
  await t('a claim for a paused program is refused', 'anon', 'PATCH', '/lvr_coupons', { 'claims/off/c1c1c1c1c1': claim({ biz: 'off' }), ['idx/off/' + EK]: { code: 'VAN-7K3P9', id: 'c1c1c1c1c1' }, ['idx/off/' + PK]: { code: 'VAN-7K3P9', id: 'c1c1c1c1c1' } }, false);
  await t('a bad email is refused', 'anon', 'PATCH', '/lvr_coupons', upd('c1c1c1c1c1', EK, claim({ email: 'nope' })), false);
  await t('a claim with no phone number is refused', 'anon', 'PATCH', '/lvr_coupons', upd('c1c1c1c1c1', EK, (() => { const c = claim(); delete c.phone; return c; })()), false);
  await t('a too-short phone number is refused', 'anon', 'PATCH', '/lvr_coupons', upd('c1c1c1c1c1', EK, claim({ phone: '123' })), false);
  await t('a bad Instagram handle is refused', 'anon', 'PATCH', '/lvr_coupons', upd('c1c1c1c1c1', EK, claim({ ig: 'not a handle!' })), false);
  await t('a claim from an employee code that does not exist is refused', 'anon', 'PATCH', '/lvr_coupons', upd('c1c1c1c1c1', EK, claim({ ref: 'ghost-abc' })), false);
  await t('the phone fingerprint must differ from the email fingerprint', 'anon', 'PATCH', '/lvr_coupons', { 'claims/van/c1c1c1c1c1': claim({ pk: EK }), ['idx/van/' + EK]: { code: 'VAN-7K3P9', id: 'c1c1c1c1c1' } }, false);
  await t('a stranger cannot add an employee', 'anon', 'PUT', '/lvr_coupons/staff/van/maria-7k3', { name: 'Maria' }, false);
  await t('the owner adds an employee', 'owner', 'PUT', '/lvr_coupons/staff/van/maria-7k3', { name: 'Maria', active: true, createdAt: { '.sv': 'timestamp' } }, true);
  await t('a stranger cannot read the employee list', 'anon', 'GET', '/lvr_coupons/staff/van', undefined, false);
  await t('the owner cannot add an employee with a bad id', 'owner', 'PUT', '/lvr_coupons/staff/van/X', { name: 'Maria' }, false);
  await t('text consent without the consent wording is refused', 'anon', 'PATCH', '/lvr_coupons', upd('c1c1c1c1c1', EK, (() => { const c = claim(); delete c.consentText; return c; })()), false);
  await t('a claim that arrives already redeemed is refused', 'anon', 'PATCH', '/lvr_coupons', upd('c1c1c1c1c1', EK, claim({ redeemed: true })), false);
  await t('a claim with an unknown field is refused', 'anon', 'PATCH', '/lvr_coupons', upd('c1c1c1c1c1', EK, claim({ hack: 1 })), false);
  await t('a made-up time is refused', 'anon', 'PATCH', '/lvr_coupons', upd('c1c1c1c1c1', EK, claim({ createdAt: 5 })), false);
  await t('the duplicate-check entry must match the claim code', 'anon', 'PATCH', '/lvr_coupons', { 'claims/van/c1c1c1c1c1': claim(), ['idx/van/' + EK]: { code: 'OTHER-CODE', id: 'c1c1c1c1c1' }, ['idx/van/' + PK]: { code: 'VAN-7K3P9', id: 'c1c1c1c1c1' } }, false);
  await t('a valid claim through a real employee code is accepted', 'anon', 'PATCH', '/lvr_coupons', upd('c9c9c9c9c9', 'f'.repeat(32), claim({ email: 'ref@example.com', ek: 'f'.repeat(32), pk: '9'.repeat(32), phone: '7025550999', code: 'VAN-REF22', ref: 'maria-7k3' })), true);
  // instant employee credit: the log entry is only allowed together with a claim that names that employee
  await t('an employee credit without a claim is refused', 'anon', 'PUT', '/lvr_coupons/staffLog/van/maria-7k3/zzzzzzzz1', { t: { '.sv': 'timestamp' }, k: 2 }, false);
  await t('an employee credit for the wrong number of keys is refused', 'anon', 'PATCH', '/lvr_coupons', upd('c8c8c8c8c8', 'b1'.repeat(16), claim({ email: 'k@example.com', ek: 'b1'.repeat(16), pk: 'b2'.repeat(16), phone: '7025550888', code: 'VAN-KEY88', ref: 'maria-7k3' }), { 'staffLog/van/maria-7k3/c8c8c8c8c8': { t: { '.sv': 'timestamp' }, k: 50 } }), false);
  await t('a claim through an employee plus the matching credit is accepted at once', 'anon', 'PATCH', '/lvr_coupons', upd('c7c7c7c7c7', 'a1'.repeat(16), claim({ email: 'j@example.com', ek: 'a1'.repeat(16), pk: 'a2'.repeat(16), phone: '7025550777', code: 'VAN-KEY77', ref: 'maria-7k3' }), { 'staffLog/van/maria-7k3/c7c7c7c7c7': { t: { '.sv': 'timestamp' }, k: 2 } }), true);
  await t('a credit for an employee who is not on the claim is refused', 'anon', 'PATCH', '/lvr_coupons', upd('c6c6c6c6c6', 'c1'.repeat(16), claim({ email: 'l@example.com', ek: 'c1'.repeat(16), pk: 'c2'.repeat(16), phone: '7025550666', code: 'VAN-KEY66' }), { 'staffLog/van/maria-7k3/c6c6c6c6c6': { t: { '.sv': 'timestamp' }, k: 2 } }), false);
  await t('anyone with the employee link can read that employee\'s live count', 'anon', 'GET', '/lvr_coupons/staffLog/van/maria-7k3', undefined, true);
  await t('anyone can read an employee\'s first name by exact link', 'anon', 'GET', '/lvr_coupons/staff/van/maria-7k3/name', undefined, true, '"Maria"');
  await t('a stranger still cannot list the employees', 'anon', 'GET', '/lvr_coupons/staff/van', undefined, false);
  await t('a stranger cannot erase an employee\'s credits', 'anon', 'DELETE', '/lvr_coupons/staffLog/van/maria-7k3', undefined, false);
  await t('a valid claim with its duplicate-check entry is accepted', 'anon', 'PATCH', '/lvr_coupons', upd('c1c1c1c1c1', EK, claim()), true);
  await t('a claim with a phone, an Instagram handle and no text consent is accepted', 'anon', 'PATCH', '/lvr_coupons', upd('c2c2c2c2c2', EK2, (() => { const c = claim({ email: 'bo@example.com', code: 'VAN-AAAA2', ek: EK2, pk: PK2, phone: '7025550111', smsOptIn: false, ig: 'bo.chen' }); delete c.consentText; return c; })()), true);
  await t('the same phone number with a different email cannot claim twice', 'anon', 'PATCH', '/lvr_coupons', upd('c4c4c4c4c4', PK3, claim({ email: 'other@example.com', ek: PK3, code: 'VAN-ZZZZ4' })), false);
  await t('the same person cannot claim twice', 'anon', 'PATCH', '/lvr_coupons', upd('c3c3c3c3c3', EK, claim({ code: 'VAN-ZZZZ3' })), false);
  await t('a visitor can look up their own code by the duplicate-check key', 'anon', 'GET', '/lvr_coupons/idx/van/' + EK + '/code', undefined, true, '"VAN-7K3P9"');
  await t('a stranger still cannot read the claim itself', 'anon', 'GET', '/lvr_coupons/claims/van/c1c1c1c1c1', undefined, false);
  await t('a stranger cannot overwrite a claim', 'anon', 'PUT', '/lvr_coupons/claims/van/c1c1c1c1c1', claim({ name: 'Eve' }), false);
  await t('a stranger cannot mark a claim redeemed', 'anon', 'PATCH', '/lvr_coupons/claims/van/c1c1c1c1c1', { redeemed: true }, false);
  await t('a stranger cannot delete claims', 'anon', 'DELETE', '/lvr_coupons/claims/van', undefined, false);
  await t('a stranger cannot delete the duplicate-check entry', 'anon', 'DELETE', '/lvr_coupons/idx/van/' + EK, undefined, false);
  await t('the owner reads all the claims', 'owner', 'GET', '/lvr_coupons/claims/van', undefined, true);
  await t('the owner marks a claim redeemed', 'owner', 'PATCH', '/lvr_coupons/claims/van/c1c1c1c1c1', { redeemed: true, redeemedAt: { '.sv': 'timestamp' } }, true);
  // counter
  await t('the counter starts at 1', 'anon', 'PUT', '/lvr_coupons/counts/van', 1, true);
  await t('the counter cannot jump by 2', 'anon', 'PUT', '/lvr_coupons/counts/van', 3, false);
  await t('the counter cannot go down', 'anon', 'PUT', '/lvr_coupons/counts/van', 0, false);
  await t('the counter goes up by 1', 'anon', 'PUT', '/lvr_coupons/counts/van', 2, true);
  await t('the counter cannot pass the limit of 2', 'anon', 'PUT', '/lvr_coupons/counts/van', 3, false);
  await t('anyone can read the counter', 'anon', 'GET', '/lvr_coupons/counts/van', undefined, true, '2');
  await t('the owner can reset the counter', 'owner', 'PUT', '/lvr_coupons/counts/van', 0, true);
  await t('the owner can delete a claim', 'owner', 'DELETE', '/lvr_coupons/claims/van/c2c2c2c2c2', undefined, true);
  console.log(`\n${pass} passed, ${fail} failed`);
  process.exit(fail ? 1 : 0);
})();
