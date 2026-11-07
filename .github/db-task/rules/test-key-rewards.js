/* Tests for the STAGED Key Rewards rules (key-rewards-rules.json) and for the engine running against them
   (kr-engine.js with the Firebase store). Runs in the Realtime Database emulator only; nothing touches the real database.
   Run: bash .github/db-task/rules/run-kr-rules-test.sh
   who: 'anon' = no token | 'owner' = uid TESTOWNER (the runner swaps __OWNER_UID__ for it) | 'other' = signed in, not the owner */
const NS = 'demo-lvr-default-rtdb', BASE = 'http://127.0.0.1:9000';
const KR = require('./kr-engine.js');
const b64u = o => Buffer.from(JSON.stringify(o)).toString('base64url');
const jwt = uid => b64u({ alg: 'none', typ: 'JWT' }) + '.' + b64u({ uid, user_id: uid, sub: uid, iat: Math.floor(Date.now() / 1000) }) + '.';
const OWNER = jwt('TESTOWNER'), OTHER = jwt('SOMEONE-ELSE');
async function call(who, method, p, body) {
  const auth = who === 'owner' ? '&auth=' + OWNER : who === 'other' ? '&auth=' + OTHER : '';
  const r = await fetch(`${BASE}${p}.json?ns=${NS}${auth}`, { method, headers: Object.assign({ 'Content-Type': 'application/json' }, who === 'admin' ? { Authorization: 'Bearer owner' } : {}), body: body === undefined ? undefined : JSON.stringify(body) });
  return { s: r.status, t: await r.text() };
}
let pass = 0, fail = 0;
const t = async (name, who, method, p, body, allow) => { const r = await call(who, method, p, body), a = r.s === 200, ok = a === allow; ok ? pass++ : fail++; console.log((ok ? 'PASS' : 'FAIL') + '  [' + who + '] ' + name + '  [' + (a ? 'allowed' : 'denied') + (ok ? '' : ', expected ' + (allow ? 'allowed' : 'denied') + ' HTTP ' + r.s + ' ' + r.t.slice(0, 80)) + ']'); return r; };
const eq = (name, a, b) => { const ok = JSON.stringify(a) === JSON.stringify(b); ok ? pass++ : fail++; console.log((ok ? 'PASS' : 'FAIL') + '  ' + name + (ok ? '' : '  got ' + JSON.stringify(a) + ' want ' + JSON.stringify(b))); };
const K = '/key_rewards/';
(async () => {
  const now = Date.now(), H = 3600000;
  const EV = { rid: 'rA', title: 'Friday', pool: 2000, cap: 15, opensAt: now - H, closesAt: now + H, status: 'draft', createdAt: now };
  const MK = 'abcdefghijkl1', MK2 = 'abcdefghijkl2', MK3 = 'abcdefghijkl3';

  // ---- restaurants
  await t('create a restaurant', 'anon', 'PUT', K + 'restaurants/rA', { name: 'Harbor', active: true, createdAt: now }, false);
  await t('create a restaurant', 'other', 'PUT', K + 'restaurants/rA', { name: 'Harbor', active: true, createdAt: now }, false);
  await t('create a restaurant', 'owner', 'PUT', K + 'restaurants/rA', { name: 'Harbor', city: 'Las Vegas', country: 'US', active: true, createdAt: now }, true);
  await t('restaurant with an unknown extra field', 'owner', 'PUT', K + 'restaurants/rB', { name: 'X', active: true, createdAt: now, secret: 1 }, false);
  await t('restaurant with a 3-letter country', 'owner', 'PUT', K + 'restaurants/rB', { name: 'X', active: true, createdAt: now, country: 'USA' }, false);
  await t('the restaurant list cannot be read by a stranger', 'anon', 'GET', K + 'restaurants', undefined, false);

  // ---- events
  await t('create an event', 'anon', 'PUT', K + 'events/e1abcdefgh', EV, false);
  await t('create an event', 'other', 'PUT', K + 'events/e1abcdefgh', EV, false);
  await t('create an event as already closed', 'owner', 'PUT', K + 'events/e1abcdefgh', Object.assign({}, EV, { status: 'closed', issued: 0, share: 0, leftover: 2000, approvedCount: 0, closedAt: now }), false);
  await t('event with a fractional pool', 'owner', 'PUT', K + 'events/e1abcdefgh', Object.assign({}, EV, { pool: 100.5 }), false);
  await t('event with a cap above the pool', 'owner', 'PUT', K + 'events/e1abcdefgh', Object.assign({}, EV, { cap: 5000 }), false);
  await t('event with a pool above one million', 'owner', 'PUT', K + 'events/e1abcdefgh', Object.assign({}, EV, { pool: 2000000, cap: 5 }), false);
  await t('event whose window ends before it starts', 'owner', 'PUT', K + 'events/e1abcdefgh', Object.assign({}, EV, { closesAt: now - 2 * H }), false);
  await t('event with an unknown extra field', 'owner', 'PUT', K + 'events/e1abcdefgh', Object.assign({}, EV, { bonus: 99 }), false);
  await t('create a draft event', 'owner', 'PUT', K + 'events/e1abcdefgh', EV, true);
  await t('anyone may read ONE event by its id (the check-in page needs it)', 'anon', 'GET', K + 'events/e1abcdefgh', undefined, true);
  await t('nobody but the owner may LIST events', 'anon', 'GET', K + 'events', undefined, false);
  await t('the owner may list events', 'owner', 'GET', K + 'events', undefined, true);
  await t('change the pool of an existing event', 'owner', 'PATCH', K + 'events/e1abcdefgh', { pool: 9999 }, false);
  await t('anyone changing an event status', 'anon', 'PATCH', K + 'events/e1abcdefgh', { status: 'open' }, false);
  await t('skip straight from draft to closed', 'owner', 'PATCH', K + 'events/e1abcdefgh', { status: 'closed', issued: 0, share: 0, leftover: 2000, approvedCount: 0, closedAt: now }, false);
  await t('check in while the event is still a draft', 'anon', 'PUT', K + 'checkins/e1abcdefgh/' + MK, { t: now, name: 'Ava', status: 'pending' }, false);
  await t('open the event', 'owner', 'PATCH', K + 'events/e1abcdefgh', { status: 'open' }, true);

  // ---- check-ins
  await t('check in', 'anon', 'PUT', K + 'checkins/e1abcdefgh/' + MK, { t: now, name: 'Ava', status: 'pending' }, true);
  await t('check in again with the same code', 'anon', 'PUT', K + 'checkins/e1abcdefgh/' + MK, { t: now, name: 'Ava2', status: 'pending' }, false);
  await t('check in already approved', 'anon', 'PUT', K + 'checkins/e1abcdefgh/' + MK2, { t: now, name: 'Ben', status: 'approved' }, false);
  await t('check in with a short member code', 'anon', 'PUT', K + 'checkins/e1abcdefgh/short', { t: now, name: 'Ben', status: 'pending' }, false);
  await t('check in with a 60-character name', 'anon', 'PUT', K + 'checkins/e1abcdefgh/' + MK2, { t: now, name: 'x'.repeat(60), status: 'pending' }, false);
  await t('check in with a time far in the past', 'anon', 'PUT', K + 'checkins/e1abcdefgh/' + MK2, { t: now - 5 * H, name: 'Ben', status: 'pending' }, false);
  await t('check in with an extra field', 'anon', 'PUT', K + 'checkins/e1abcdefgh/' + MK2, { t: now, name: 'Ben', status: 'pending', points: 500 }, false);
  await t('check in to an event that does not exist', 'anon', 'PUT', K + 'checkins/eNOPE12345/' + MK2, { t: now, name: 'Ben', status: 'pending' }, false);
  await t('check in (second member)', 'anon', 'PUT', K + 'checkins/e1abcdefgh/' + MK2, { t: now, name: 'Ben', status: 'pending' }, true);
  await t('check in (third member)', 'anon', 'PUT', K + 'checkins/e1abcdefgh/' + MK3, { t: now, name: 'Cy', status: 'pending' }, true);
  await t('read the check-in list', 'anon', 'GET', K + 'checkins/e1abcdefgh', undefined, false);
  await t('read one check-in', 'anon', 'GET', K + 'checkins/e1abcdefgh/' + MK, undefined, false);
  await t('approve a check-in', 'anon', 'PATCH', K + 'checkins/e1abcdefgh/' + MK, { status: 'approved' }, false);
  await t('approve a check-in', 'other', 'PATCH', K + 'checkins/e1abcdefgh/' + MK, { status: 'approved' }, false);
  await t('approve a check-in', 'owner', 'PATCH', K + 'checkins/e1abcdefgh/' + MK, { status: 'approved' }, true);
  await t('owner changes a check-in name', 'owner', 'PATCH', K + 'checkins/e1abcdefgh/' + MK2, { name: 'Renamed' }, false);
  await t('owner changes a check-in time', 'owner', 'PATCH', K + 'checkins/e1abcdefgh/' + MK2, { t: now + 1 }, false);
  await t('owner rejects a check-in', 'owner', 'PATCH', K + 'checkins/e1abcdefgh/' + MK2, { status: 'rejected' }, true);
  await t('owner approves the third', 'owner', 'PATCH', K + 'checkins/e1abcdefgh/' + MK3, { status: 'approved' }, true);

  // ---- a window that has ended
  await call('admin', 'PUT', K + 'events/eold1234567', Object.assign({}, EV, { opensAt: now - 3 * H, closesAt: now - 2 * H, status: 'open' }));
  await t('check in after the window closed', 'anon', 'PUT', K + 'checkins/eold1234567/' + MK, { t: now, name: 'Ava', status: 'pending' }, false);
  await call('admin', 'PUT', K + 'events/efuture1234', Object.assign({}, EV, { opensAt: now + 2 * H, closesAt: now + 3 * H, status: 'open' }));
  await t('check in before the window opens', 'anon', 'PUT', K + 'checkins/efuture1234/' + MK, { t: now, name: 'Ava', status: 'pending' }, false);

  // ---- closing: shares + the event update in one atomic write
  const sh = { rewards: 15, at: now };
  await t('write a share before the event is closed out', 'anon', 'PUT', K + 'shares/e1abcdefgh/' + MK, sh, false);
  await t('write a share', 'other', 'PUT', K + 'shares/e1abcdefgh/' + MK, sh, false);
  await t('a share above the per-person cap (16 > 15)', 'owner', 'PUT', K + 'shares/e1abcdefgh/' + MK, { rewards: 16, at: now }, false);
  await t('a fractional share', 'owner', 'PUT', K + 'shares/e1abcdefgh/' + MK, { rewards: 7.5, at: now }, false);
  await t('a zero share', 'owner', 'PUT', K + 'shares/e1abcdefgh/' + MK, { rewards: 0, at: now }, false);
  await t('a share with an extra field', 'owner', 'PUT', K + 'shares/e1abcdefgh/' + MK, { rewards: 15, at: now, note: 'x' }, false);
  await t('close with issued + leftover that do not add up to the pool', 'owner', 'PATCH', K + '', { 'events/e1abcdefgh/status': 'closed', 'events/e1abcdefgh/closedAt': now, 'events/e1abcdefgh/approvedCount': 2, 'events/e1abcdefgh/share': 15, 'events/e1abcdefgh/issued': 30, 'events/e1abcdefgh/leftover': 5 }, false);
  await t('close with an issued total above the pool', 'owner', 'PATCH', K + '', { 'events/e1abcdefgh/status': 'closed', 'events/e1abcdefgh/closedAt': now, 'events/e1abcdefgh/approvedCount': 200, 'events/e1abcdefgh/share': 15, 'events/e1abcdefgh/issued': 3000, 'events/e1abcdefgh/leftover': 0 }, false);
  await t('close the event and issue the shares (2 approved x 15)', 'owner', 'PATCH', K + '', { ['shares/e1abcdefgh/' + MK]: sh, ['shares/e1abcdefgh/' + MK3]: sh, 'events/e1abcdefgh/status': 'closed', 'events/e1abcdefgh/closedAt': now, 'events/e1abcdefgh/approvedCount': 2, 'events/e1abcdefgh/share': 15, 'events/e1abcdefgh/issued': 30, 'events/e1abcdefgh/leftover': 1970 }, true);
  await t('a member reads their own share by key', 'anon', 'GET', K + 'shares/e1abcdefgh/' + MK, undefined, true);
  await t('nobody can list all shares', 'anon', 'GET', K + 'shares/e1abcdefgh', undefined, false);
  await t('the owner can list shares', 'owner', 'GET', K + 'shares/e1abcdefgh', undefined, true);
  await t('issue a second, bigger share to the same member', 'owner', 'PUT', K + 'shares/e1abcdefgh/' + MK, { rewards: 15, at: now + 1 }, false);
  await t('issue a share for a rejected member after closing', 'owner', 'PUT', K + 'shares/e1abcdefgh/' + MK2, sh, false);
  await t('change a closed event', 'owner', 'PATCH', K + 'events/e1abcdefgh', { issued: 0 }, false);
  await t('reopen a closed event', 'owner', 'PATCH', K + 'events/e1abcdefgh', { status: 'open' }, false);
  await t('delete a closed event', 'owner', 'DELETE', K + 'events/e1abcdefgh', undefined, false);
  await t('change a check-in after the event closed', 'owner', 'PATCH', K + 'checkins/e1abcdefgh/' + MK, { status: 'rejected' }, false);
  await t('new check-in after the event closed', 'anon', 'PUT', K + 'checkins/e1abcdefgh/abcdefghijkl9', { t: now, name: 'Late', status: 'pending' }, false);

  // ---- redemptions
  const RD = { mkey: MK, rid: 'rA', offer: 'Chicken bowl', rewards: 15, at: now };
  await t('record a redemption', 'anon', 'PUT', K + 'redemptions/x1', RD, false);
  await t('record a redemption', 'other', 'PUT', K + 'redemptions/x1', RD, false);
  await t('record a redemption below the 15-reward minimum', 'owner', 'PUT', K + 'redemptions/x1', Object.assign({}, RD, { rewards: 10 }), false);
  await t('record a fractional redemption', 'owner', 'PUT', K + 'redemptions/x1', Object.assign({}, RD, { rewards: 15.5 }), false);
  await t('record a redemption', 'owner', 'PUT', K + 'redemptions/x1', RD, true);
  await t('overwrite a redemption', 'owner', 'PUT', K + 'redemptions/x1', Object.assign({}, RD, { rewards: 20 }), false);
  await t('delete a redemption', 'owner', 'DELETE', K + 'redemptions/x1', undefined, false);
  await t('read redemptions', 'anon', 'GET', K + 'redemptions', undefined, false);
  await t('read the whole key_rewards tree', 'anon', 'GET', K.slice(0, -1), undefined, false);
  await t('write at an unknown place inside key_rewards', 'owner', 'PUT', K + 'secret', { a: 1 }, false);
  await t('the owner may read the whole tree', 'owner', 'GET', K.slice(0, -1), undefined, true);

  // ---- people (members) and hand-added rewards (grants)
  const MM = { name: 'Maria', createdAt: now, source: 'owner' };
  await t('add a person', 'anon', 'PUT', K + 'members/' + MK, MM, false);
  await t('add a person', 'other', 'PUT', K + 'members/' + MK, MM, false);
  await t('add a person with a short code', 'owner', 'PUT', K + 'members/short', MM, false);
  await t('add a person with a 60-character name', 'owner', 'PUT', K + 'members/mmmmmmmmmmmm1', Object.assign({}, MM, { name: 'x'.repeat(60) }), false);
  await t('add a person with an unknown field (phone)', 'owner', 'PUT', K + 'members/mmmmmmmmmmmm1', Object.assign({}, MM, { phone: '555' }), false);
  await t('add a person with a made-up source', 'owner', 'PUT', K + 'members/mmmmmmmmmmmm1', Object.assign({}, MM, { source: 'admin' }), false);
  await t('add a person', 'owner', 'PUT', K + 'members/mmmmmmmmmmmm1', MM, true);
  await t('rename a person', 'owner', 'PATCH', K + 'members/mmmmmmmmmmmm1', { name: 'Maria L' }, true);
  await t('change when a person joined', 'owner', 'PATCH', K + 'members/mmmmmmmmmmmm1', { createdAt: 1 }, false);
  await t('read the list of people', 'anon', 'GET', K + 'members', undefined, false);
  await t('read the list of people', 'owner', 'GET', K + 'members', undefined, true);
  const GR = { mkey: 'mmmmmmmmmmmm1', rewards: 20, reason: 'Welcome', at: now };
  await t('add rewards to a person', 'anon', 'PUT', K + 'grants/g1', GR, false);
  await t('add rewards to a person', 'other', 'PUT', K + 'grants/g1', GR, false);
  await t('add rewards to someone who is not a person in the list', 'owner', 'PUT', K + 'grants/g1', Object.assign({}, GR, { mkey: 'nobodyxxxxxx1' }), false);
  await t('add 0 rewards', 'owner', 'PUT', K + 'grants/g1', Object.assign({}, GR, { rewards: 0 }), false);
  await t('add 1001 rewards (above the 1000 limit)', 'owner', 'PUT', K + 'grants/g1', Object.assign({}, GR, { rewards: 1001 }), false);
  await t('add 7.5 rewards', 'owner', 'PUT', K + 'grants/g1', Object.assign({}, GR, { rewards: 7.5 }), false);
  await t('add rewards with no reason', 'owner', 'PUT', K + 'grants/g1', Object.assign({}, GR, { reason: '' }), false);
  await t('add rewards with an unknown field', 'owner', 'PUT', K + 'grants/g1', Object.assign({}, GR, { note: 'x' }), false);
  await t('add rewards to a person', 'owner', 'PUT', K + 'grants/g1', GR, true);
  await t('change a hand-added grant afterwards', 'owner', 'PUT', K + 'grants/g1', Object.assign({}, GR, { rewards: 900 }), false);
  await t('delete a grant', 'owner', 'DELETE', K + 'grants/g1', undefined, false);
  await t('read grants', 'anon', 'GET', K + 'grants', undefined, false);

  // ---- the engine, end to end, through the Firebase store (anonymous guests, owner dashboard)
  const q = 'ns=' + NS;
  const ownerKr = KR.create(KR.firebaseStore(BASE, () => OWNER, { query: q }));
  const guestKr = KR.create(KR.firebaseStore(BASE, () => '', { query: q }));
  const rest = await ownerKr.addRestaurant({ name: 'Cedar Grill', city: 'Las Vegas', country: 'US' });
  const ev = await ownerKr.createEvent({ rid: rest.id, title: 'Engine night', pool: 1000, cap: 20, opensAt: Date.now() - 1000, closesAt: Date.now() + H });
  await ownerKr.openEvent(ev.id);
  const guests = ['aaaaaaaaaaaa1', 'aaaaaaaaaaaa2', 'aaaaaaaaaaaa3', 'aaaaaaaaaaaa4'];
  for (const g of guests) eq('engine: guest check-in ' + g.slice(-1), (await guestKr.checkIn(ev.id, { name: 'Guest' + g.slice(-1), mkey: g })).ok, true);
  eq('engine: a duplicate check-in is refused', (await guestKr.checkIn(ev.id, { name: 'Guest1', mkey: guests[0] })).already, true);
  let listErr = false; try { await guestKr.listCheckins(ev.id); } catch (e) { listErr = true; }
  eq('engine: a guest cannot read the check-in list', listErr, true);
  await ownerKr.review(ev.id, [guests[3]], 'rejected');
  await ownerKr.approveAll(ev.id);
  const res = await ownerKr.closeEvent(ev.id);
  eq('engine: 3 approved share 1000 with a cap of 20', [res.approved, res.share, res.issued, res.leftover], [3, 20, 60, 940]);
  eq('engine: a guest reads their own share', (await guestKr.getShare(ev.id, guests[0])).rewards, 20);
  eq('engine: the rejected guest has no share', await guestKr.getShare(ev.id, guests[3]), null);
  let closeErr = false; try { await ownerKr.closeEvent(ev.id); } catch (e) { closeErr = true; }
  eq('engine: closing twice is refused', closeErr, true);
  await ownerKr.redeem({ mkey: guests[0], rid: rest.id, offer: 'Burger', rewards: 15 });
  eq('engine: balance after a redemption', await ownerKr.balanceOf(guests[0]), { received: 20, redeemed: 15, available: 5 });
  let guestRedeem = false; try { await guestKr.redeem({ mkey: guests[1], rid: rest.id, rewards: 15 }); } catch (e) { guestRedeem = true; }
  eq('engine: a guest cannot redeem for themselves', guestRedeem, true);
  const pm = await ownerKr.addMember({ name: 'Priya' });
  await ownerKr.grant({ mkey: pm.mkey, rewards: 40, reason: 'Thank you' });
  eq('engine: a person added by hand has what was added', (await ownerKr.balanceOf(pm.mkey)).available, 40);
  await ownerKr.redeem({ mkey: pm.mkey, rid: rest.id, offer: 'Salad', rewards: 15 });
  const led = await ownerKr.ledger();
  eq('engine: the list of everybody has the event guests and the added person', led.filter(m => m.name.startsWith('Guest') || m.name === 'Priya').length, 4);
  let gGuest = false; try { await guestKr.grant({ mkey: pm.mkey, rewards: 500, reason: 'x' }); } catch (e) { gGuest = true; }
  eq('engine: a guest cannot add rewards to anyone', gGuest, true);
  const sum = await ownerKr.summary();
  eq('engine: summary totals match (events 30 + 60 issued, grants 20 + 40, redemptions 15 x 3)', [sum.totals.issued + sum.totals.granted, sum.totals.redeemed, sum.totals.outstanding], [90 + 20 + 40, 30 + 15, 150 - 45]);
  console.log('\n' + pass + ' passed, ' + fail + ' failed');
  process.exit(fail ? 1 : 0);
})().catch(e => { console.log('ERROR ' + e.stack); process.exit(2); });
