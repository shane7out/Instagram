// Unit tests for the Key Rewards engine (pure logic + in-memory store). Run: node .github/db-task/rewards-tests/test-kr-engine.js
const KR = require('../../../sites/key-technologies/key-platform/kr-engine.js');
let pass = 0, fail = 0;
const ok = (name, cond, extra) => { cond ? pass++ : fail++; console.log((cond ? 'PASS' : 'FAIL') + '  ' + name + (cond ? '' : '  ' + JSON.stringify(extra))); };
const eq = (name, a, b) => ok(name, JSON.stringify(a) === JSON.stringify(b), { got: a, want: b });
const rej = async (name, p) => { try { await p; ok(name, false, 'did not reject'); } catch (e) { ok(name, true); } };
(async () => {
  // ---- the split
  eq('2000 among 200 = 10 each', KR.split(2000, 50, 200), { share: 10, issued: 2000, leftover: 0, approved: 200 });
  eq('rounding down leaves a leftover', KR.split(1000, 50, 300), { share: 3, issued: 900, leftover: 100, approved: 300 });
  eq('the per-person cap applies on a quiet night', KR.split(2000, 15, 5), { share: 15, issued: 75, leftover: 1925, approved: 5 });
  eq('one person gets at most the cap', KR.split(2000, 40, 1), { share: 40, issued: 40, leftover: 1960, approved: 1 });
  eq('nobody there: nothing issued', KR.split(2000, 15, 0), { share: 0, issued: 0, leftover: 2000, approved: 0 });
  eq('more people than rewards: nothing issued, all left over', KR.split(10, 5, 50), { share: 0, issued: 0, leftover: 10, approved: 50 });
  let bad = 0; for (let i = 0; i < 2000; i++) { const p = 1 + Math.floor(Math.random() * 5000), c = 1 + Math.floor(Math.random() * 200), n = 1 + Math.floor(Math.random() * 600); const s = KR.split(p, c, n); if (s.issued + s.leftover !== p || s.issued > p || s.share > c || s.share * n !== s.issued || !Number.isInteger(s.share)) bad++; }
  ok('2000 random splits: issued + leftover = pool, never over the pool or the cap, whole numbers', bad === 0, bad);

  // ---- an event from start to finish
  let T = 1700000000000; const clock = () => T;
  const store = KR.memoryStore(); const kr = KR.create(store, clock);
  const r = await kr.addRestaurant({ name: 'Harbor Table', city: 'Las Vegas', country: 'us' });
  eq('restaurant country upper-cased', (await kr.listRestaurants())[0].country, 'US');
  await rej('a restaurant needs a name', kr.addRestaurant({ name: '  ' }));
  await rej('pool must be a whole number', kr.createEvent({ rid: r.id, title: 'x', pool: 10.5, cap: 5, opensAt: T, closesAt: T + 1000 }));
  await rej('cap cannot exceed the pool', kr.createEvent({ rid: r.id, title: 'x', pool: 100, cap: 101, opensAt: T, closesAt: T + 1000 }));
  await rej('window must end after it starts', kr.createEvent({ rid: r.id, title: 'x', pool: 100, cap: 10, opensAt: T, closesAt: T }));
  const ev = await kr.createEvent({ rid: r.id, title: 'Friday', pool: 100, cap: 20, opensAt: T, closesAt: T + 3600000 });
  eq('a new event is a draft', ev.status, 'draft');
  eq('check-in is refused until the event is open', (await kr.checkIn(ev.id, { name: 'Ava', mkey: 'abcdefghijkl' })).ok, false);
  await kr.openEvent(ev.id);
  await rej('an event cannot be opened twice', kr.openEvent(ev.id));
  eq('a valid check-in works', (await kr.checkIn(ev.id, { name: 'Ava', mkey: 'abcdefghijkl' })).ok, true);
  eq('the same member cannot check in twice', (await kr.checkIn(ev.id, { name: 'Ava', mkey: 'abcdefghijkl' })).already, true);
  eq('an empty name is refused', (await kr.checkIn(ev.id, { name: '  ', mkey: 'zzzzzzzzzzzz' })).ok, false);
  eq('a short member code is refused', (await kr.checkIn(ev.id, { name: 'Bo', mkey: 'short' })).ok, false);
  eq('markup is stripped from names', (await kr.checkIn(ev.id, { name: 'Cy<script>', mkey: 'ccccccccccccc' })).ok, true);
  await kr.checkIn(ev.id, { name: 'Dee', mkey: 'ddddddddddddd' });
  await kr.checkIn(ev.id, { name: 'Eve', mkey: 'eeeeeeeeeeeee' });
  let cks = await kr.listCheckins(ev.id);
  eq('four check-ins, all pending', cks.map(c => c.status), ['pending', 'pending', 'pending', 'pending']);
  ok('names are stored without markup', cks.some(c => c.name === 'Cyscript') && !cks.some(c => /[<>]/.test(c.name)), cks);
  T += 3600001;
  eq('check-in after the window is refused', (await kr.checkIn(ev.id, { name: 'Late', mkey: 'llllllllllll' })).ok, false);
  T -= 3600001;
  await kr.review(ev.id, ['ddddddddddddd'], 'rejected');
  await kr.approveAll(ev.id);
  cks = await kr.listCheckins(ev.id);
  eq('approve-all leaves rejected ones alone', cks.map(c => c.status), ['approved', 'approved', 'rejected', 'approved']);
  const res = await kr.closeEvent(ev.id);
  eq('3 approved share 100 rewards: the cap of 20 applies (20 each, 60 issued, 40 left)', [res.approved, res.share, res.issued, res.leftover], [3, 20, 60, 40]);
  await rej('a closed event cannot be closed again', kr.closeEvent(ev.id));
  await rej('check-ins cannot change after closing', kr.review(ev.id, ['abcdefghijkl'], 'rejected'));
  eq('a member can read their own share', (await kr.getShare(ev.id, 'abcdefghijkl')).rewards, 20);
  eq('a rejected member has no share', await kr.getShare(ev.id, 'ddddddddddddd'), null);
  eq('the event records what was issued', (await kr.getEvent(ev.id)).issued, 60);

  // ---- redemptions
  eq('balance before redeeming', await kr.balanceOf('abcdefghijkl'), { received: 20, redeemed: 0, available: 20 });
  await rej('an offer below 15 rewards is refused', kr.redeem({ mkey: 'abcdefghijkl', rid: r.id, rewards: 10 }));
  await rej('cannot redeem more than the balance', kr.redeem({ mkey: 'abcdefghijkl', rid: r.id, rewards: 25 }));
  await rej('a member with no rewards cannot redeem', kr.redeem({ mkey: 'ddddddddddddd', rid: r.id, rewards: 15 }));
  await kr.redeem({ mkey: 'abcdefghijkl', rid: r.id, offer: 'Chicken bowl', rewards: 15 });
  eq('balance after redeeming 15', await kr.balanceOf('abcdefghijkl'), { received: 20, redeemed: 15, available: 5 });
  await rej('the remaining 5 cannot be redeemed (offers start at 15)', kr.redeem({ mkey: 'abcdefghijkl', rid: r.id, rewards: 5 }));
  const sum = await kr.summary();
  eq('summary: issued 60, redeemed 15, outstanding 45, leftover 40', [sum.totals.issued, sum.totals.redeemed, sum.totals.outstanding, sum.totals.leftover], [60, 15, 45, 40]);
  eq('summary: 4 check-ins, 3 approved, 1 rejected', [sum.totals.checkins, sum.totals.approved, sum.totals.rejected], [4, 3, 1]);

  // ---- an event nobody attends
  const e2 = await kr.createEvent({ rid: r.id, title: 'Quiet', pool: 500, cap: 10, opensAt: T, closesAt: T + 1000 });
  await kr.openEvent(e2.id); const c2 = await kr.closeEvent(e2.id);
  eq('no check-ins: nothing issued, all 500 left over', [c2.issued, c2.leftover], [0, 500]);

  // ---- sandbox demo data
  const kr2 = KR.create(KR.memoryStore(), clock); await kr2.seedDemo(); const s2 = await kr2.summary();
  ok('demo data: 3 restaurants, 5 events (4 closed, 1 open)', s2.totals.restaurants === 3 && s2.totals.events === 5 && s2.totals.closed === 4 && s2.totals.open === 1, s2.totals);
  ok('demo data: issued never exceeds the pools', s2.totals.issued <= s2.totals.pools, s2.totals);
  console.log('\n' + pass + ' passed, ' + fail + ' failed'); process.exit(fail ? 1 : 0);
})().catch(e => { console.log('ERROR ' + e.stack); process.exit(2); });
