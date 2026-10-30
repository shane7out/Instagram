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
  check('add or change referredBy after sign-up', await call('anon', 'PUT', '/lvr_rewards/K1/referredBy', 'K2'), false);
  check('sign-up that names who invited them (allowed at creation only)', await call('anon', 'POST', '/lvr_rewards', { name: 'Friend', points: 0, token: 'tokFriendabcdefabcdefa', referredBy: 'K1' }), true);
  // ---- welcome bonus at sign-up (needs the owner's setting to be on)
  const welMember = pts => ({ name: 'Wel', token: 'welcometoken123456789', refCode: 'WELC123', points: pts, welcomeGiven: { amount: pts, via: 'signup', at: TS } });
  check('sign-up with 13 points while the welcome bonus is OFF', await call('anon', 'POST', '/lvr_rewards', welMember(13)), false);
  await call('admin', 'PUT', '/lvr_points/settings/welcome', { enabled: true, amount: 13, when: 'signup' });
  check('sign-up with exactly 13 points when it is on (sign-up mode)', await call('anon', 'POST', '/lvr_rewards', welMember(13)), true);
  check('sign-up with 14 points when the bonus is 13', await call('anon', 'POST', '/lvr_rewards', welMember(14)), false);
  check('sign-up with 13 points but no welcome record', await call('anon', 'POST', '/lvr_rewards', { name: 'Wel', token: 'welcometoken123456789', refCode: 'WELC124', points: 13 }), false);
  check('settings: welcome amount of 5000', await call('anon', 'PUT', '/lvr_points/settings/welcome', { enabled: true, amount: 5000, when: 'signup' }), false);
  check('settings: welcome timing nonsense', await call('anon', 'PUT', '/lvr_points/settings/welcome', { enabled: true, amount: 13, when: 'whenever' }), false);
  check('settings: owner saves welcome bonus (13, sign-up)', await call('anon', 'PUT', '/lvr_points/settings/welcome', { enabled: true, amount: 13, when: 'signup' }), true);
  await call('admin', 'PUT', '/lvr_points/settings/welcome', { enabled: true, amount: 13, when: 'receipt' });
  check('sign-up with 13 points when timing is "first receipt"', await call('anon', 'POST', '/lvr_rewards', welMember(13)), false);
  await call('admin', 'DELETE', '/lvr_points/settings/welcome');
  // ---- member bonus: ready every 10 days, 48 hours to claim, otherwise the wait starts over + manual bonuses
  const CH = { waitDays: 10, claimHours: 48, prizeMin: 1, prizeMax: 2, repeat: true };
  await call('admin', 'PUT', '/lvr_points/settings/chest', CH);
  const DAYMS = 86400000, HRMS = 3600000;
  const mem = (nm, tok, rc, joinedAgo) => ({ name: nm, token: tok, refCode: rc, points: 0, joinedAt: Date.now() - joinedAgo });
  await call('admin', 'PUT', '/lvr_rewards/OLD1', mem('Old', 'oldtokenoldtokenoldtoken', 'OLDC123', 11 * DAYMS));
  await call('admin', 'PUT', '/lvr_rewards/NEW1', mem('New', 'newtokennewtokennewtoken', 'NEWC123', 3 * DAYMS));
  await call('admin', 'PUT', '/lvr_rewards/LATE1', mem('Late', 'latetokenlatetokenlate1', 'LATEC12', 20 * DAYMS));
  await call('admin', 'PUT', '/lvr_rewards/AGAIN1', mem('Again', 'againtokenagaintoken01', 'AGAINC1', 35 * DAYMS));
  check('bonus: first claim on day 11 (inside the 48 hours)', await call('anon', 'PATCH', '/lvr_rewards/OLD1', { chestState: { n: 1, amount: 1, at: TS } }), true);
  check('bonus: same claim again (n stays 1)', await call('anon', 'PATCH', '/lvr_rewards/OLD1', { chestState: { n: 1, amount: 1, at: TS } }), false);
  check('bonus: remove the claim state to re-claim', await call('anon', 'PUT', '/lvr_rewards/OLD1/chestState', null), false);
  check('bonus: second claim right away (needs 10 days)', await call('anon', 'PATCH', '/lvr_rewards/OLD1', { chestState: { n: 2, amount: 2, at: TS } }), false);
  check('bonus: claim during the first waiting period', await call('anon', 'PATCH', '/lvr_rewards/NEW1', { chestState: { n: 1, amount: 1, at: TS } }), false);
  check('bonus: claim after the 48 hours closed (day 20, wait started over)', await call('anon', 'PATCH', '/lvr_rewards/LATE1', { chestState: { n: 1, amount: 1, at: TS } }), false);
  check('bonus: claim in the next window (day 35)', await call('anon', 'PATCH', '/lvr_rewards/AGAIN1', { chestState: { n: 1, amount: 1, at: TS } }), true);
  check('bonus: prize above the allowed maximum', await call('anon', 'PATCH', '/lvr_rewards/OLD1', { chestState: { n: 2, amount: 9, at: TS } }), false);
  check('bonus: skipping a number (n 3 when on 1)', await call('anon', 'PATCH', '/lvr_rewards/OLD1', { chestState: { n: 3, amount: 1, at: TS } }), false);
  await call('admin', 'PUT', '/lvr_rewards/OLD1/chestState', { n: 1, amount: 1, at: Date.now() - 11 * DAYMS });
  check('bonus: second claim 11 days after the first (2 points)', await call('anon', 'PATCH', '/lvr_rewards/OLD1', { chestState: { n: 2, amount: 2, at: TS } }), true);
  await call('admin', 'PUT', '/lvr_rewards/OLD1/chestState', { n: 2, amount: 2, at: Date.now() - 9 * DAYMS });
  check('bonus: third claim after only 9 days', await call('anon', 'PATCH', '/lvr_rewards/OLD1', { chestState: { n: 3, amount: 1, at: TS } }), false);
  await call('admin', 'PUT', '/lvr_rewards/OLD1/chestState', { n: 2, amount: 2, at: Date.now() - 13 * DAYMS });
  check('bonus: third claim 13 days later (window already closed)', await call('anon', 'PATCH', '/lvr_rewards/OLD1', { chestState: { n: 3, amount: 1, at: TS } }), false);
  await call('admin', 'PUT', '/lvr_rewards/OLD1/chestState', { n: 2, amount: 2, at: Date.now() - (10 * DAYMS + 47 * HRMS) });
  check('bonus: third claim near the end of the 48 hours', await call('anon', 'PATCH', '/lvr_rewards/OLD1', { chestState: { n: 3, amount: 1, at: TS } }), true);
  check('bonus: log a bonus prize', await call('anon', 'PUT', '/lvr_points/chest_log/OLD1/3', { amount: 1, at: TS }), true);
  check('bonus: overwrite a log entry', await call('anon', 'PUT', '/lvr_points/chest_log/OLD1/3', { amount: 2, at: TS }), false);
  await call('admin', 'PUT', '/lvr_points/settings/chest/repeat', false);
  await call('admin', 'PUT', '/lvr_rewards/OLD1/chestState', { n: 1, amount: 1, at: Date.now() - 11 * DAYMS });
  check('bonus: repeat switched off blocks a second bonus', await call('anon', 'PATCH', '/lvr_rewards/OLD1', { chestState: { n: 2, amount: 1, at: TS } }), false);
  await call('admin', 'PUT', '/lvr_points/settings/chest/repeat', true);
  await call('admin', 'PUT', '/lvr_points/settings/chest/prizeMax', 0);
  check('bonus: prizes off (max 0) blocks claims', await call('anon', 'PATCH', '/lvr_rewards/OLD1', { chestState: { n: 2, amount: 1, at: TS } }), false);
  check('bonus: settings out of range (prize 500)', await call('anon', 'PUT', '/lvr_points/settings/chest', Object.assign({}, CH, { prizeMax: 500 })), false);
  check('bonus: settings out of range (claim window 5000 hours)', await call('anon', 'PUT', '/lvr_points/settings/chest', Object.assign({}, CH, { claimHours: 5000 })), false);
  check('bonus: owner saves settings', await call('anon', 'PUT', '/lvr_points/settings/chest', CH), true);
  // every offer must be worth at least $15 (15 points)
  check('offer: 20 points is accepted', await call('anon', 'PUT', '/lvr_points/catalog/van/bowl1', { itemName: 'Free Chicken Bowl', pointCost: 20, active: true }), true);
  check('offer: exactly 15 points is accepted', await call('anon', 'PUT', '/lvr_points/catalog/van/min15', { itemName: 'Free Plate', pointCost: 15, active: true }), true);
  check('offer: 10 points is refused', await call('anon', 'PUT', '/lvr_points/catalog/van/cheap', { itemName: 'Free Drink', pointCost: 10, active: true }), false);
  check('offer: lowering an existing offer to 14 is refused', await call('anon', 'PATCH', '/lvr_points/catalog/van/bowl1', { pointCost: 14 }), false);
  check('offer: switching an offer off still works', await call('anon', 'PATCH', '/lvr_points/catalog/van/bowl1', { active: false }), true);
  check('bonus record: give 5 points with a reason', await call('anon', 'PUT', '/lvr_points/bonuses/b1', { memberKey: 'K1', name: 'Kayla', points: 5, reason: 'Posted a video', at: TS }), true);
  check('bonus record: no reason', await call('anon', 'PUT', '/lvr_points/bonuses/b2', { memberKey: 'K1', points: 5, reason: '', at: TS }), false);
  check('bonus record: 5000 points', await call('anon', 'PUT', '/lvr_points/bonuses/b3', { memberKey: 'K1', points: 5000, reason: 'big one', at: TS }), false);
  check('bonus record: edit an existing one', await call('anon', 'PUT', '/lvr_points/bonuses/b1', { memberKey: 'K1', points: 500, reason: 'Posted a video', at: TS }), false);
  check('bonus record: delete one', await call('anon', 'DELETE', '/lvr_points/bonuses/b1'), false);
  check('bonus record: wipe all', await call('anon', 'DELETE', '/lvr_points/bonuses'), false);
  await call('admin', 'DELETE', '/lvr_points/settings/chest');
  check('give an old member a token (backfill / Generate Link)', await call('anon', 'PUT', '/lvr_rewards/K2/token', 'tokK2abcdefabcdefabcdefab'), true);
  check('lazy refCode for a member without one', await call('anon', 'PATCH', '/lvr_rewards/K2', { refCode: 'K2CODE' }), true);
  check('welcome bonus marker on a member', await call('anon', 'PATCH', '/lvr_rewards/K1', { welcomeGiven: { amount: 12, receiptId: 'r1', at: { '.sv': 'timestamp' } } }), true);
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
  check('welcome bonus recorded on the receipt', await call('anon', 'PATCH', '/lvr_points/receipts/' + rid, { welcomeAwarded: 12 }), true);
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
  check('redemption with a use-by date', await call('anon', 'POST', '/lvr_points/redemptions/van', Object.assign({}, red, { code: 'VAN-USEBY1', useBy: Date.now() + 86400000 })), true);
  check('extend a code\'s use-by date', await call('anon', 'PATCH', '/lvr_points/redemptions/van/' + redId, { useBy: 9999999999999 }), false);
  check('change a redemption cost', await call('anon', 'PATCH', '/lvr_points/redemptions/van/' + redId, { pointCost: 1 }), false);
  check('delete a redemption', await call('anon', 'DELETE', '/lvr_points/redemptions/van/' + redId), false);
  check('wipe all redemptions', await call('anon', 'DELETE', '/lvr_points/redemptions'), false);

  // ---------- owner-managed pieces keep working
  check('create a catalog item', await call('anon', 'PUT', '/lvr_points/catalog/van/i1', { itemName: 'Free Bowl', pointCost: 20, active: true }), true);
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

  // ---------- monthly community-fund return
  check('save decay settings', await call('anon', 'PUT', '/lvr_points/settings/decay', { enabled: true, percent: 20, graceDays: 30 }), true);
  check('decay percent over 50 rejected', await call('anon', 'PUT', '/lvr_points/settings/decay/percent', 90), false);
  check('decay percent 0 rejected', await call('anon', 'PUT', '/lvr_points/settings/decay/percent', 0), false);
  check('decay grace days negative rejected', await call('anon', 'PUT', '/lvr_points/settings/decay/graceDays', -1), false);
  check('record a monthly return', await call('anon', 'PUT', '/lvr_points/decay_by_member/ZZ/2026-11', { amount: 3, before: 17, after: 14, percent: 20, at: TS }), true);
  check('overwrite a monthly return record', await call('anon', 'PUT', '/lvr_points/decay_by_member/ZZ/2026-11', { amount: 9, before: 17, after: 8, percent: 20, at: TS }), false);
  check('delete a monthly return record', await call('anon', 'DELETE', '/lvr_points/decay_by_member/ZZ/2026-11'), false);
  check('pool total goes up', await call('anon', 'PUT', '/lvr_points/pool/total', { '.sv': { increment: 3 } }), true);
  check('pool total negative rejected', await call('anon', 'PUT', '/lvr_points/pool/total', -4), false);

  // end-to-end: run the real monthly script against the emulator
  const { spawnSync } = require('child_process');
  const seed = async () => {
    await call('admin', 'PUT', '/lvr_rewards', {
      OLD1: { name: 'Old One', points: 100, token: 'tokOld1abcdefabcdefabc', joinedAt: Date.now() - 90 * 86400000 },
      OLD2: { name: 'Old Two', points: 17, token: 'tokOld2abcdefabcdefabc', joinedAt: Date.now() - 60 * 86400000 },
      NEW1: { name: 'Brand New', points: 13, token: 'tokNew1abcdefabcdefabc', joinedAt: Date.now() - 3 * 86400000 },
      LOW1: { name: 'Few', points: 4, token: 'tokLow1abcdefabcdefabc', joinedAt: Date.now() - 90 * 86400000 },
      LEG1: { name: 'Legacy', points: 10 }
    });
    await call('admin', 'PUT', '/lvr_points/decay_by_member', null);
    await call('admin', 'PUT', '/lvr_points/decay_runs', null);
    await call('admin', 'PUT', '/lvr_points/pool', null);
  };
  const sweep = (extra) => { const r = spawnSync('node', [path.join(__dirname, 'monthly-decay.js')], { env: Object.assign({}, process.env, { DB_URL: BASE, DB_NS: NS, RUN_KEY: '2026-11' }, extra), encoding: 'utf8' }); return r.stdout + r.stderr; };
  const bal = async k => JSON.parse((await call('admin', 'GET', '/lvr_rewards/' + k + '/points')).t);
  await seed();
  let o = sweep({ DRY_RUN: '1' });
  check('sweep dry run changes nothing', { s: (await bal('OLD1')) === 100 && /WOULD return 25 points from 3 members/.test(o) ? 200 : 500, t: o }, true);
  o = sweep({});
  check('sweep takes 20% rounded down (100 -> 80)', { s: (await bal('OLD1')) === 80 ? 200 : 500, t: o }, true);
  check('sweep: 17 -> 14', { s: (await bal('OLD2')) === 14 ? 200 : 500, t: o }, true);
  check('sweep: brand-new member untouched (grace period)', { s: (await bal('NEW1')) === 13 ? 200 : 500, t: o }, true);
  check('sweep: 4 points is under 1 whole point, untouched', { s: (await bal('LOW1')) === 4 ? 200 : 500, t: o }, true);
  check('sweep: member with no join date is treated as long-standing (10 -> 8)', { s: (await bal('LEG1')) === 8 ? 200 : 500, t: o }, true);
  const pool = JSON.parse((await call('admin', 'GET', '/lvr_points/pool/total')).t);
  check('pool total equals what was taken (20+3+2 = 25)', { s: pool === 25 ? 200 : 500, t: String(pool) }, true);
  o = sweep({});
  check('running it again the same month takes nothing more', { s: (await bal('OLD1')) === 80 && (await bal('OLD2')) === 14 ? 200 : 500, t: o }, true);
  await call('admin', 'PUT', '/lvr_points/settings/decay/enabled', false);
  await seed();
  o = sweep({});
  check('switched off in Settings: nothing is taken', { s: (await bal('OLD1')) === 100 ? 200 : 500, t: o }, true);
  await call('admin', 'PUT', '/lvr_points/settings/decay/enabled', true);

  check('settings: default commission 20%', await call('anon', 'PUT', '/lvr_points/settings/defaultCommissionPct', 20), true);
  check('settings: default commission 250% rejected', await call('anon', 'PUT', '/lvr_points/settings/defaultCommissionPct', 250), false);
  check('settings: default commission as text rejected', await call('anon', 'PUT', '/lvr_points/settings/defaultCommissionPct', 'lots'), false);

  // ---------- everything else behaves exactly as before
  check('other apps: write a nested value (dashboard)', await call('anon', 'PUT', '/dashboard/abc', { x: 1 }), true);
  check('other apps: read (dashboard)', await call('anon', 'GET', '/dashboard'), true);
  check('other apps: wipe a whole top-level node (already blocked today)', await call('anon', 'DELETE', '/dashboard'), false);
  check('debug area for remote tasks still writable', await call('anon', 'PUT', '/_debug/diag', 'hello'), true);
  check('lead form still writes', await call('anon', 'POST', '/key_leads/leads', { source: 'x', email: 'a@example.com' }), true);
  check('page-view tracker still writes (key without a period)', await call('anon', 'POST', '/key_pageviews/hits/index_html', { t: 1 }), true);
  check('pet game stays locked to anonymous visitors (explicit sibling beats the catch-all)', await call('anon', 'PUT', '/petgame/pets/p1', { name: 'x' }), false);

  console.log('\n' + pass + ' passed, ' + fail + ' failed');
  process.exit(fail ? 1 : 0);
})().catch(e => { console.log('TEST HARNESS ERROR', e); process.exit(2); });
