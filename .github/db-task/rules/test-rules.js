// Tests the LVR rules fragment against the Firebase Realtime Database emulator.
// "anon" = an unauthenticated visitor (what every member/restaurant page is);
// "admin" = the emulator's owner bypass, used only to seed data.
const fs = require('fs');
const path = require('path');
const NS = 'demo-lvr-default-rtdb';
const BASE = 'http://127.0.0.1:9000';

async function call(who, method, p, body) {
  const url = `${BASE}${p}.json?ns=${NS}`;
  const r = await fetch(url, {
    method,
    headers: Object.assign({ 'Content-Type': 'application/json' }, who === 'admin' ? { Authorization: 'Bearer owner' } : {}),
    body: body === undefined ? undefined : JSON.stringify(body)
  });
  return { s: r.status, t: await r.text() };
}
let pass = 0, fail = 0;
function check(name, res, shouldAllow) {
  const allowed = res.s === 200;
  const ok = allowed === shouldAllow;
  ok ? pass++ : fail++;
  console.log((ok ? 'PASS' : 'FAIL') + '  ' + name + '  [' + (allowed ? 'allowed' : 'denied') + (ok ? '' : ', expected ' + (shouldAllow ? 'allowed' : 'denied') + ' - HTTP ' + res.s + ' ' + res.t.slice(0, 80)) + ']');
}
const TS = { '.sv': 'timestamp' };
const goodReceipt = () => ({ slug: 'van', memberKey: 'K1', token: 'tok1abcdefabcdefabcdef', name: 'Kayla', receiptNo: '4821', amount: 62.4, receiptDate: '2026-10-27', receiptType: 'paper', status: 'pending', submittedAt: TS });
const BIG = 'x'.repeat(100);

(async () => {
  // ---------- member records
  await call('admin', 'PUT', '/lvr_rewards/K1', { name: 'Kayla', points: 100, token: 'tok1abcdefabcdefabcdef', refCode: 'ABC234', joinedAt: 1700000000000 });
  await call('admin', 'PUT', '/lvr_rewards/K2', { name: 'Old', points: 5 });
  check('anyone can read members (as today)', await call('anon', 'GET', '/lvr_rewards'), true);
  check('sign-up: new member with 0 points', await call('anon', 'POST', '/lvr_rewards', { name: 'Bob', points: 0, token: 'tokBobabcdefabcdefabcd', refCode: 'BOB234', joinedAt: TS, referredBy: 'K1' }), true);
  check('sign-up: new member starting with 50 points', await call('anon', 'POST', '/lvr_rewards', { name: 'Cheat', points: 50, token: 'tokCheatabcdefabcdefab' }), false);
  check('award points (+5, as the dashboard does)', await call('anon', 'PUT', '/lvr_rewards/K1/points', 105), true);
  check('server-side increment (as the dashboard does)', await call('anon', 'PUT', '/lvr_rewards/K1/points', { '.sv': { increment: 10 } }), true);
  check('points set negative', await call('anon', 'PUT', '/lvr_rewards/K1/points', -5), false);
  check('points set to text', await call('anon', 'PUT', '/lvr_rewards/K1/points', 'lots'), false);
  check('change a member\'s personal-link token', await call('anon', 'PUT', '/lvr_rewards/K1/token', 'hijackedtokenhijackedtoken'), false);
  check('change an existing refCode', await call('anon', 'PUT', '/lvr_rewards/K1/refCode', 'HACK99'), false);
  check('change referredBy after the fact', await call('anon', 'PUT', '/lvr_rewards/K1/referredBy', 'K2'), false);
  check('give an old member a token (backfill / Generate Link)', await call('anon', 'PUT', '/lvr_rewards/K2/token', 'tokK2abcdefabcdefabcdefab'), true);
  check('lazy refCode for a member without one', await call('anon', 'PATCH', '/lvr_rewards/K2', { refCode: 'K2CODE' }), true);
  check('referral bonus fields', await call('anon', 'PATCH', '/lvr_rewards/K1', { refCarry: 0.4, refBonusTotal: 2 }), true);
  check('delete ONE member (data-deletion request)', await call('anon', 'DELETE', '/lvr_rewards/K2'), true);
  check('wipe ALL members in one request', await call('anon', 'DELETE', '/lvr_rewards'), false);
  check('overwrite the whole members list', await call('anon', 'PUT', '/lvr_rewards', { x: { name: 'x', points: 0 } }), false);

  // ---------- receipts
  check('submit a receipt', await call('anon', 'POST', '/lvr_points/receipts', goodReceipt()), true);
  const rid = Object.keys(JSON.parse((await call('admin', 'GET', '/lvr_points/receipts')).t))[0];
  check('submit a receipt already marked approved', await call('anon', 'POST', '/lvr_points/receipts', Object.assign(goodReceipt(), { status: 'approved' })), false);
  check('submit a receipt with points pre-awarded', await call('anon', 'POST', '/lvr_points/receipts', Object.assign(goodReceipt(), { pointsAwarded: 500 })), false);
  check('submit a $0 receipt', await call('anon', 'POST', '/lvr_points/receipts', Object.assign(goodReceipt(), { amount: 0 })), false);
  check('submit a $9,999 receipt', await call('anon', 'POST', '/lvr_points/receipts', Object.assign(goodReceipt(), { amount: 9999 })), false);
  check('submit a receipt with no token', await call('anon', 'POST', '/lvr_points/receipts', (() => { const r = goodReceipt(); delete r.token; return r; })()), false);
  check('approve (what the admin does)', await call('anon', 'PATCH', '/lvr_points/receipts/' + rid, { status: 'approved', pointsAwarded: 6, pointsApplied: false, referralDone: false, decidedAt: TS }), true);
  check('mark points applied', await call('anon', 'PATCH', '/lvr_points/receipts/' + rid, { pointsApplied: true }), true);
  check('referral flags', await call('anon', 'PATCH', '/lvr_points/receipts/' + rid, { refL1Done: true, refL1Points: 1, referralDone: true }), true);
  check('restaurant flags a receipt', await call('anon', 'PATCH', '/lvr_points/receipts/' + rid, { restFlag: { note: 'looks high', at: TS } }), true);
  check('change the amount of a receipt', await call('anon', 'PATCH', '/lvr_points/receipts/' + rid, { amount: 1 }), false);
  check('change the receipt number', await call('anon', 'PATCH', '/lvr_points/receipts/' + rid, { receiptNo: '9999' }), false);
  check('change the receipt date', await call('anon', 'PATCH', '/lvr_points/receipts/' + rid, { receiptDate: '2026-01-01' }), false);
  check('re-open a decided receipt (back to pending)', await call('anon', 'PATCH', '/lvr_points/receipts/' + rid, { status: 'pending' }), false);
  check('flip approved to rejected', await call('anon', 'PATCH', '/lvr_points/receipts/' + rid, { status: 'rejected' }), false);
  check('change points already awarded', await call('anon', 'PATCH', '/lvr_points/receipts/' + rid, { pointsAwarded: 5000 }), false);
  check('DELETE a receipt', await call('anon', 'DELETE', '/lvr_points/receipts/' + rid), false);
  check('wipe ALL receipts in one request', await call('anon', 'DELETE', '/lvr_points/receipts'), false);
  check('wipe the whole points program', await call('anon', 'DELETE', '/lvr_points'), false);
  check('overwrite the whole points program', await call('anon', 'PUT', '/lvr_points', { receipts: {} }), false);
  check('queries by token/restaurant still readable', await call('anon', 'GET', '/lvr_points/receipts'), true);

  // ---------- photos
  check('upload two photos for a receipt', await call('anon', 'PUT', '/lvr_points/receipt_photos/' + rid, { wide: BIG, close: BIG }), true);
  check('upload a single screenshot (emailed receipt)', await call('anon', 'PUT', '/lvr_points/receipt_photos/zzz1', { wide: BIG }), true);
  check('legacy single-photo format', await call('anon', 'PUT', '/lvr_points/receipt_photos/zzz2', { data: BIG }), true);
  check('replace an existing photo', await call('anon', 'PUT', '/lvr_points/receipt_photos/' + rid, { wide: 'tampered' }), false);
  check('DELETE a photo', await call('anon', 'DELETE', '/lvr_points/receipt_photos/' + rid), false);
  check('edit one photo field', await call('anon', 'PUT', '/lvr_points/receipt_photos/' + rid + '/wide', 'tampered'), false);
  check('oversized photo (3 MB)', await call('anon', 'PUT', '/lvr_points/receipt_photos/zzz3', { wide: 'x'.repeat(3000000) }), false);
  check('photo record with junk fields', await call('anon', 'PUT', '/lvr_points/receipt_photos/zzz4', { wide: BIG, evil: 'x' }), false);
  check('wipe ALL photos', await call('anon', 'DELETE', '/lvr_points/receipt_photos'), false);
  check('read one photo', await call('anon', 'GET', '/lvr_points/receipt_photos/' + rid), true);

  // ---------- redemptions
  const red = { token: 'tok1abcdefabcdefabcdef', name: 'Kayla', itemId: 'i1', itemName: 'Free Bowl', bizName: 'Vanilla Rice', pointCost: 10, code: 'VAN-AB2CD', redeemedAt: TS };
  check('redeem an offer (member app)', await call('anon', 'POST', '/lvr_points/redemptions/van', red), true);
  const redId = Object.keys(JSON.parse((await call('admin', 'GET', '/lvr_points/redemptions/van')).t))[0];
  check('redemption that costs nothing', await call('anon', 'POST', '/lvr_points/redemptions/van', Object.assign({}, red, { pointCost: 0 })), false);
  check('create a redemption already marked used', await call('anon', 'POST', '/lvr_points/redemptions/van', Object.assign({}, red, { usedAt: 1 })), false);
  check('restaurant marks a code used', await call('anon', 'PATCH', '/lvr_points/redemptions/van/' + redId, { usedAt: TS }), true);
  check('un-use / change usedAt', await call('anon', 'PATCH', '/lvr_points/redemptions/van/' + redId, { usedAt: 5 }), false);
  check('change a redemption code', await call('anon', 'PATCH', '/lvr_points/redemptions/van/' + redId, { code: 'FREE-ALL' }), false);
  check('change a redemption cost', await call('anon', 'PATCH', '/lvr_points/redemptions/van/' + redId, { pointCost: 1 }), false);
  check('delete a redemption', await call('anon', 'DELETE', '/lvr_points/redemptions/van/' + redId), false);
  check('wipe all redemptions', await call('anon', 'DELETE', '/lvr_points/redemptions'), false);

  // ---------- owner-managed pieces keep working
  check('create a catalog item', await call('anon', 'PUT', '/lvr_points/catalog/van/i1', { itemName: 'Free Bowl', pointCost: 10, active: true }), true);
  check('edit / delete one catalog item', await call('anon', 'DELETE', '/lvr_points/catalog/van/i1'), true);
  check('wipe the whole catalog', await call('anon', 'DELETE', '/lvr_points/catalog'), false);
  check('save a business + PIN', await call('anon', 'PATCH', '/lvr_points/restaurants/van', { bizName: 'Vanilla Rice', pin: '1234', commissionPct: 15 }), true);
  check('save directory entry', await call('anon', 'PATCH', '/lvr_points/directory/van', { bizName: 'Vanilla Rice', earnRate: 0.05, active: true }), true);
  check('credit draw-down on redeem', await call('anon', 'PUT', '/lvr_points/directory/van/creditRemaining', { '.sv': { increment: -10 } }), true);
  check('save settings (pause switches)', await call('anon', 'PUT', '/lvr_points/settings/paused', { signups: true }), true);
  check('add credit to the ledger', await call('anon', 'POST', '/lvr_points/fundings/van', { amount: 500, note: 'gift', at: TS }), true);
  const fid = Object.keys(JSON.parse((await call('admin', 'GET', '/lvr_points/fundings/van')).t))[0];
  check('delete a ledger entry', await call('anon', 'DELETE', '/lvr_points/fundings/van/' + fid), false);
  check('edit a ledger entry', await call('anon', 'PATCH', '/lvr_points/fundings/van/' + fid, { amount: 1 }), false);
  check('write to an unknown spot under lvr_points', await call('anon', 'PUT', '/lvr_points/mystery', { a: 1 }), false);

  // ---------- coupons + instagram index
  check('create coupon program', await call('anon', 'PUT', '/lvr_coupons/programs/van', { bizName: 'Vanilla Rice', offer: 'Free bowl', maxClaims: 50 }), true);
  check('customer claims a coupon', await call('anon', 'POST', '/lvr_coupons/claims/van', { name: 'A', email: 'a@example.com', code: '55555' }), true);
  check('wipe all coupon claims', await call('anon', 'DELETE', '/lvr_coupons/claims'), false);
  check('wipe all coupon programs', await call('anon', 'DELETE', '/lvr_coupons/programs'), false);
  check('duplicate-check entry for a new sign-up', await call('anon', 'PUT', '/lvr_instagram_index/someone', true), true);
  check('wipe the instagram index', await call('anon', 'DELETE', '/lvr_instagram_index'), false);

  // ---------- everything else behaves exactly as before
  check('other apps: write a nested value (dashboard)', await call('anon', 'PUT', '/dashboard/abc', { x: 1 }), true);
  check('other apps: read (dashboard)', await call('anon', 'GET', '/dashboard'), true);
  check('other apps: wipe a whole top-level node (already blocked today)', await call('anon', 'DELETE', '/dashboard'), false);
  check('debug area for remote tasks still writable', await call('anon', 'PUT', '/_debug/diag', 'hello'), true);
  check('lead form still writes', await call('anon', 'POST', '/key_leads/leads', { source: 'x', email: 'a@example.com' }), true);
  check('page-view tracker still writes', await call('anon', 'POST', '/key_pageviews/hits/index.html', { t: 1 }), true);
  check('pet game stays locked to anonymous visitors (explicit sibling beats the catch-all)', await call('anon', 'PUT', '/petgame/pets/p1', { name: 'x' }), false);

  console.log('\n' + pass + ' passed, ' + fail + ' failed');
  process.exit(fail ? 1 : 0);
})().catch(e => { console.log('TEST HARNESS ERROR', e); process.exit(2); });
