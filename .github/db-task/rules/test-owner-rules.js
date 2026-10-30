/*
=====================================================================================
README  -  STAGED OWNER-ONLY RULES  (lvr-rules-owner.json)  -  NOT DEPLOYED YET
=====================================================================================
What this is
  lvr-rules-owner.json holds the same four sections as lvr-rules-fragment.json
  (lvr_points, lvr_rewards, lvr_instagram_index, lvr_coupons), tightened so the highest-value
  writes need the owner's Firebase Auth sign-in. The owner test is
      (auth != null && auth.uid == '__OWNER_UID__')
  and a deploy script must replace the literal __OWNER_UID__ with the owner's real uid.
  Members and restaurants stay anonymous. NO .read rule was changed and NO existing
  .validate rule was removed or weakened.
  Run:  bash .github/db-task/rules/run-owner-rules-test.sh   (emulator, port 9000; assembles the
  ruleset with __OWNER_UID__ -> TESTOWNER; this file builds unsigned tokens for that uid).
  Tokens used below: anon = no token, owner = uid TESTOWNER, other = a signed-in stranger
  (uid SOMEONE-ELSE: proves that "signed in" alone is not enough; keep Auth sign-ups closed).

Rules-language fact that shaped the edits: a .write granted at a parent cannot be revoked by a
child. So lvr_rewards/$k/.write, receipts/$id/.write, settings (the old $key wildcard and the
per-section .write: true) were narrowed, and what anonymous visitors may still do is re-granted
explicitly (create-only conditions, unchanged-field conditions, or child-level grants).
The owner is still bound by the old integrity rules (write-once records, immutable receipt
fields, no deletes of evidence); the staged change only adds WHO may decide.

OWNER-ONLY NOW (anonymous and signed-in non-owner are refused)
  lvr_points/settings/*   every setting EXCEPT hiddenRestaurants and serviceModes (validation kept)
  lvr_points/pool/total   (the only pool rule that exists)
  decay_by_member, decay_runs, pool_drops, pool_drop_runs, bonuses, fundings (still write-once)
  tag_claims              anyone may CREATE a pending claim; any change to an existing claim is owner-only
  round1                  anyone may CREATE (pending/approved); any change afterwards is owner-only
  lvr_rewards             member fields status, approvedAt, decidedAt, welcomeGiven; deleting a member.
                          Anonymous CREATE only with points == 0, status absent or 'pending', and no
                          welcomeGiven / approvedAt / decidedAt (welcome points are now added by the owner
                          at approval, which is what the admin tool already does).
  receipts                create stays anonymous (pending, no decision fields). Every change to an existing
                          receipt is owner-only EXCEPT restFlag and the "void" exception below.
                          Decision fields: status, pointsAwarded, pointsApplied, referralDone,
                          welcomeAwarded, decidedAt (+ refL1Done, refL1Points, refL2Done, refL2Points,
                          which only the admin tool writes; they are also refused at creation).
  transactions            types welcome, receipt, opening, adjustment, bonus, referral are owner-only.

STILL OPEN ON PURPOSE (tests prove each still works anonymously)
  - a member's own `points` (spin credit, redeem decrement, dashboard +/-, refCarry/refBonusTotal):
    making these tamper-proof needs server code, not rules
  - catalog, redemptions (restaurant portal uses a PIN), restaurants, directory incl. creditRemaining
    draw-down (the member app does that on redeem), receipt_photos, chest_log, transactions of type
    spin/redeem, tag_claims creation, round1 creation, lvr_instagram_index, lvr_coupons,
    settings/hiddenRestaurants and settings/serviceModes (member page PIN owner-mode),
    consent PATCH, lazy refCode, token backfill, chestState (spin claim), all public reads.
  - DELIBERATE EXCEPTION (receipts): my-account.html voids a receipt whose photo upload failed by
    PATCHing {status:'rejected', decidedAt}. Anonymous may do exactly that, only to a receipt that is
    still 'pending' AND was submitted less than 10 minutes ago (rules: receipts/$id/status and
    /decidedAt). A stranger could therefore reject someone else's brand-new pending receipt within
    10 minutes (the same griefing is possible today with no time limit). Remove it once the page
    stops doing that.
  - Candidates for a later phase (found while enumerating writers): catalog and restaurants (PINs,
    commissionPct) are written ONLY by lvr-points-admin.html today, not by the portal; lvr_coupons
    programs only by lvr-coupons-admin.html. Not gated here because they were not in scope.

STEP 0: WRITERS TODAY  (path -> who writes it -> owner-only in staged rules?)
  OWNER tools = mac/lvr-points-admin.html, mac/key-room.html, patched-dashboard.html (points only),
  mac/lvr-invoice.html (read only). Member/anonymous = sites/key-technologies/my-account.html,
  rewards.html, menu.html, mac/lvr-rewards.html (legacy sign-up), mac/lvr-wallet.html (no writes).
  Restaurant (PIN) = mac/lvr-restaurant-portal.html. join-restaurant.html writes only key_leads.
  settings/* except the two below ... lvr-points-admin (Settings, Pause, Banner), key-room (paused) ... YES
  settings/hiddenRestaurants ........ my-account.html + menu.html (PIN owner-mode), lvr-points-admin ... NO
  settings/serviceModes ............. my-account.html (PIN owner-mode) ................................ NO
  pool/total ........................ lvr-points-admin, decay/monthly-decay.js (script) ................ YES
  decay_by_member, decay_runs ....... lvr-points-admin, decay/monthly-decay.js ........................ YES
  pool_drops, pool_drop_runs, bonuses, fundings ... lvr-points-admin only ............................ YES
  tag_claims create ................. my-account.html .................................................. NO
  tag_claims decisions .............. lvr-points-admin only ............................................ YES
  round1 create ..................... rewards.html, lvr-points-admin, backfill-round1.js ............... NO
  round1 status change .............. lvr-points-admin only ............................................ YES
  lvr_rewards create ................ rewards.html, mac/lvr-rewards.html (incl. welcome points) ........ NO (but welcome-at-sign-up now refused)
  lvr_rewards status/approvedAt/decidedAt/welcomeGiven, delete ... lvr-points-admin only ............... YES
  lvr_rewards points ................ my-account.html, patched-dashboard.html, lvr-points-admin, monthly-decay.js ... NO
  lvr_rewards token/refCode/consent/chestState ... my-account.html, rewards.html ................... NO
  lvr_rewards refCarry/refBonusTotal ... lvr-points-admin (referral payout; kept open with points) .... NO
  receipts create ................... my-account.html .................................................. NO
  receipts restFlag ................. lvr-restaurant-portal.html ....................................... NO
  receipts void (status+decidedAt) .. my-account.html (photo upload failure) ........................... NO (narrow exception)
  receipts other changes/decisions .. lvr-points-admin only ............................................ YES
  receipt_photos, redemptions ....... my-account.html, lvr-restaurant-portal.html (usedAt) ............. NO
  transactions spin/redeem .......... my-account.html .................................................. NO
  transactions other types .......... lvr-points-admin only (rewards.html queues a 'welcome' that my-account would send) ... YES
  catalog, restaurants .............. lvr-points-admin only (kept open: out of scope) ..................... NO
  directory ......................... lvr-points-admin; my-account.html (creditRemaining on redeem) ...... NO
  chest_log ......................... my-account.html .................................................. NO
  lvr_instagram_index ............... mac/lvr-rewards.html (create), lvr-points-admin (delete) ......... NO
  lvr_coupons ....................... lvr-coupon.html (claims), lvr-coupons-admin.html (programs) ....... NO (unchanged)
  Other .github/db-task scripts: only decay/monthly-decay.js and backfill-round1.js write these paths.

OLD SUITE (test-rules.js) RE-RUN AGAINST THE NEW FILE
  With every owner-tool action converted to send the owner token, the old suite passes except ONE
  intentional flip. Expectations that changed (all covered above by this file):
   - anonymous sign-up with the welcome points attached while the bonus is on: allowed -> REFUSED
   - owner actions that now need the token (anonymous: allowed -> refused): saving any setting
     (welcome, chest, decay, tagBonus, launch, paused, defaultCommissionPct), pool total, monthly return
     records, pool drop records and run summaries, bonus records, credit (fundings), Round One
     approve/decline, member approve (status), welcomeGiven marker, receipt approve / pointsApplied /
     referral flags / welcomeAwarded, tag claim approve / pointsApplied, deleting a member,
     ledger types welcome/receipt/bonus/referral/opening/adjustment.
   - the old monthly-decay.js sweep needs the owner token (section 10 runs it through a tiny fetch
     preload that appends ?auth=<token>; run anonymously it takes nothing).
  Unchanged and re-verified: receipts, photos, redemptions, catalog, restaurants, directory, coupons,
  instagram index, spin claim rules, token/refCode/referredBy immutability, wipe protections, other apps.
=====================================================================================
*/
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const NS = 'demo-lvr-default-rtdb';
const BASE = 'http://127.0.0.1:9000';

// Unsigned test tokens (the emulator accepts alg "none"). The runner replaces __OWNER_UID__ with TESTOWNER.
const b64u = o => Buffer.from(JSON.stringify(o)).toString('base64url');
const jwt = uid => b64u({ alg: 'none', typ: 'JWT' }) + '.' + b64u({ uid: uid, user_id: uid, sub: uid, iat: Math.floor(Date.now() / 1000) }) + '.';
const OWNER_JWT = jwt('TESTOWNER');
const OTHER_JWT = jwt('SOMEONE-ELSE'); // signed in, but NOT the owner (e.g. a stranger who signed up through the public Auth API)

// who: 'anon' (no token) | 'owner' (token for the owner uid) | 'other' (token for another uid) | 'admin' (emulator bypass, used to seed data)
async function call(who, method, p, body) {
  const auth = who === 'owner' ? '&auth=' + OWNER_JWT : who === 'other' ? '&auth=' + OTHER_JWT : '';
  const url = `${BASE}${p}.json?ns=${NS}${auth}`;
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
// one check: who does method path body, should it be allowed?
const t = async (name, who, method, p, body, allow) => check('[' + who + '] ' + name, await call(who, method, p, body), allow);
// owner-only pair: the anonymous call is refused, then the owner call goes through
const both = async (name, method, p, body, ownerBody) => {
  await t(name, 'anon', method, p, body, false);
  await t(name, 'owner', method, p, ownerBody === undefined ? body : ownerBody, true);
};

const TS = { '.sv': 'timestamp' };
const TOK = 'tok1abcdefabcdefabcdef';
const goodReceipt = (o) => Object.assign({ slug: 'van', memberKey: 'K1', token: TOK, name: 'Kayla', phone: '555', instagram: '@kayla', receiptNo: '4821', amount: 62.4, receiptDate: '2026-10-27', receiptType: 'paper', status: 'pending', submittedAt: TS }, o || {});
const BIG = 'x'.repeat(100);
const L = '/lvr_points/', S = '/lvr_points/settings/', R = '/lvr_points/receipts';
const DAYMS = 86400000, HRMS = 3600000;

(async () => {
  // ---------- seed (emulator bypass)
  await call('admin', 'PUT', '/lvr_rewards/K1', { name: 'Kayla', points: 100, token: TOK, refCode: 'ABC234', joinedAt: 1700000000000, status: 'approved' });
  await call('admin', 'PUT', '/lvr_rewards/K2', { name: 'Old', points: 5 });
  await call('admin', 'PUT', '/lvr_rewards/PEND1', { name: 'Pending Pat', points: 0, token: 'tokPend1abcdefabcdefab', refCode: 'PEND123', joinedAt: 1700000000000, status: 'pending' });
  await call('admin', 'PUT', L + 'directory/van', { bizName: 'Vanilla Rice', creditRemaining: 500, earnRate: 0.05, active: true });

  // =====================================================================
  // 1. SETTINGS: owner-only, EXCEPT hiddenRestaurants / serviceModes
  // =====================================================================
  await t('settings can still be READ by anyone (public read unchanged)', 'anon', 'GET', L + 'settings', undefined, true);
  await both('settings: pause switches (paused)', 'PUT', S + 'paused', { signups: true, receipts: false });
  await both('settings: banner message', 'PUT', S + 'banner', 'We are upgrading, back Monday');
  await both('settings: welcome bonus (13, sign-up)', 'PUT', S + 'welcome', { enabled: true, amount: 13, when: 'signup' });
  await t('settings: welcome amount of 5000 (validation still applies)', 'owner', 'PUT', S + 'welcome', { enabled: true, amount: 5000, when: 'signup' }, false);
  await t('settings: welcome timing nonsense (validation still applies)', 'owner', 'PUT', S + 'welcome', { enabled: true, amount: 13, when: 'whenever' }, false);
  const CH = { waitDays: 10, claimHours: 48, prizeMin: 1, prizeMax: 2, repeat: true };
  await both('settings: bonus spin settings (chest)', 'PUT', S + 'chest', CH);
  await t('settings: chest prize of 500 (validation still applies)', 'owner', 'PUT', S + 'chest', Object.assign({}, CH, { prizeMax: 500 }), false);
  await t('settings: chest claim window of 5000 hours (validation still applies)', 'owner', 'PUT', S + 'chest', Object.assign({}, CH, { claimHours: 5000 }), false);
  await both('settings: monthly return (decay)', 'PUT', S + 'decay', { enabled: true, percent: 20, graceDays: 30 });
  await t('settings: decay percent over 50 (validation still applies)', 'owner', 'PUT', S + 'decay/percent', 90, false);
  await t('settings: decay percent 0 (validation still applies)', 'owner', 'PUT', S + 'decay/percent', 0, false);
  await t('settings: decay grace days negative (validation still applies)', 'owner', 'PUT', S + 'decay/graceDays', -1, false);
  await both('settings: tag bonus (5 points)', 'PUT', S + 'tagBonus', { enabled: true, points: 5 });
  await t('settings: tag bonus of 500 (validation still applies)', 'owner', 'PUT', S + 'tagBonus', { enabled: true, points: 500 }, false);
  await both('settings: launch / founding spots', 'PUT', S + 'launch', { enabled: true, limit: 25, invites: 1 });
  await t('settings: launch 0 spots (validation still applies)', 'owner', 'PUT', S + 'launch', { enabled: true, limit: 0, invites: 1 }, false);
  await t('settings: launch 500 invites each (validation still applies)', 'owner', 'PUT', S + 'launch', { enabled: true, limit: 25, invites: 500 }, false);
  await t('settings: launch approval must be true/false (validation still applies)', 'owner', 'PUT', S + 'launch', { enabled: true, limit: 25, invites: 1, approval: 'yes' }, false);
  await t('settings: launch approval switch saves for the owner', 'owner', 'PUT', S + 'launch', { enabled: true, limit: 25, invites: 1, approval: true }, true);
  await t('settings: launch approval switch refused for anonymous', 'anon', 'PUT', S + 'launch', { enabled: true, limit: 25, invites: 1, approval: false }, false);
  await both('settings: default commission 20%', 'PUT', S + 'defaultCommissionPct', 20);
  await t('settings: default commission 250% (validation still applies)', 'owner', 'PUT', S + 'defaultCommissionPct', 250, false);
  await t('settings: default commission as text (validation still applies)', 'owner', 'PUT', S + 'defaultCommissionPct', 'lots', false);
  await both('settings: referral program', 'PUT', S + 'referral', { enabled: true, l1: 0.1, l2: 0.05 });
  await both('settings: receipt limits', 'PUT', S + 'limits', { maxAmount: 500, maxPerWeek: 5, windowDays: 7 });
  await both('settings: spin prize ladder', 'PUT', S + 'prizeLadder', { tiers: [1, 2, 3] });
  await t('settings: a brand-new unknown setting key', 'anon', 'PUT', S + 'somethingNew', 1, false);
  await t('settings: wipe all settings', 'anon', 'DELETE', L + 'settings', undefined, false);
  await t('settings: overwrite all settings', 'anon', 'PUT', L + 'settings', { paused: { signups: false } }, false);
  await t('settings: PATCH several settings at once', 'anon', 'PATCH', L + 'settings', { paused: { signups: false }, banner: 'x' }, false);
  await t('settings: a signed-in NON-owner cannot change settings either', 'other', 'PUT', S + 'paused', { signups: true }, false);
  // the two nodes the member page's PIN owner-mode writes (still open on purpose)
  await t('hiddenRestaurants: PIN owner-mode hides a restaurant (PUT true)', 'anon', 'PUT', S + 'hiddenRestaurants/vanilla-rice', true, true);
  await t('hiddenRestaurants: PIN owner-mode shows it again (DELETE one)', 'anon', 'DELETE', S + 'hiddenRestaurants/vanilla-rice', undefined, true);
  await t('hiddenRestaurants: admin tool hides one', 'owner', 'PUT', S + 'hiddenRestaurants/taco-spot', true, true);
  await t('hiddenRestaurants: admin tool Restore (DELETE the whole node)', 'owner', 'DELETE', S + 'hiddenRestaurants', undefined, true);
  await t('hiddenRestaurants: still readable', 'anon', 'GET', S + 'hiddenRestaurants', undefined, true);
  await t('serviceModes: PIN owner-mode sets a restaurant to pickup', 'anon', 'PUT', S + 'serviceModes/vanilla-rice', 'pickup', true);
  await t('serviceModes: PIN owner-mode clears it (DELETE one)', 'anon', 'DELETE', S + 'serviceModes/vanilla-rice', undefined, true);
  await t('serviceModes: owner can set it too', 'owner', 'PUT', S + 'serviceModes/taco-spot', 'both', true);

  // =====================================================================
  // 2. POOL, MONTHLY RETURN, POOL DROPS, BONUSES, FUNDINGS: owner-only
  // =====================================================================
  await t('pool total: anonymous increment', 'anon', 'PUT', L + 'pool/total', { '.sv': { increment: 3 } }, false);
  await t('pool total: anonymous set to a big number', 'anon', 'PUT', L + 'pool/total', 99999, false);
  await t('pool total: a signed-in NON-owner', 'other', 'PUT', L + 'pool/total', { '.sv': { increment: 3 } }, false);
  await t('pool total goes up (owner)', 'owner', 'PUT', L + 'pool/total', { '.sv': { increment: 30 } }, true);
  await t('pool total goes down (pool drop, owner)', 'owner', 'PUT', L + 'pool/total', { '.sv': { increment: -4 } }, true);
  await t('pool total negative (validation still applies)', 'owner', 'PUT', L + 'pool/total', -4, false);
  await t('pool: unknown key under pool', 'anon', 'PUT', L + 'pool/extra', 1, false);
  await t('pool: wipe the pool', 'anon', 'DELETE', L + 'pool', undefined, false);
  await t('pool: still readable', 'anon', 'GET', L + 'pool/total', undefined, true);

  await t('monthly return record', 'anon', 'PUT', L + 'decay_by_member/ZZ/2026-11', { amount: 3, before: 17, after: 14, percent: 20, at: TS }, false);
  await t('monthly return record', 'owner', 'PUT', L + 'decay_by_member/ZZ/2026-11', { amount: 3, before: 17, after: 14, percent: 20, at: TS }, true);
  await t('monthly return record overwrite', 'owner', 'PUT', L + 'decay_by_member/ZZ/2026-11', { amount: 9, before: 17, after: 8, percent: 20, at: TS }, false);
  await t('monthly return record delete', 'owner', 'DELETE', L + 'decay_by_member/ZZ/2026-11', undefined, false);
  await t('monthly return record with amount 0 (validation still applies)', 'owner', 'PUT', L + 'decay_by_member/ZZ/2026-12', { amount: 0, before: 17, after: 17, percent: 20, at: TS }, false);
  await t('monthly return record: all cannot be wiped', 'owner', 'DELETE', L + 'decay_by_member', undefined, false);
  await t('monthly return run summary', 'anon', 'PUT', L + 'decay_runs/2026-11', { members: 3, points: 25, percent: 20, at: TS }, false);
  await t('monthly return run summary', 'owner', 'PUT', L + 'decay_runs/2026-11', { members: 3, points: 25, percent: 20, at: TS }, true);
  await t('monthly return run summary overwrite', 'owner', 'PUT', L + 'decay_runs/2026-11', { members: 9, points: 99, percent: 20, at: TS }, false);

  await t('pool drop: a drop of 4 points', 'anon', 'PUT', L + 'pool_drops/-Mk9/2026-11', { amount: 4, at: TS }, false);
  await t('pool drop: a drop of 4 points', 'owner', 'PUT', L + 'pool_drops/-Mk9/2026-11', { amount: 4, at: TS }, true);
  await t('pool drop: same month twice', 'owner', 'PUT', L + 'pool_drops/-Mk9/2026-11', { amount: 9, at: TS }, false);
  await t('pool drop: 500 points (validation still applies)', 'owner', 'PUT', L + 'pool_drops/-Mk8/2026-11', { amount: 500, at: TS }, false);
  await t('pool drop: a record cannot be deleted', 'owner', 'DELETE', L + 'pool_drops/-Mk9/2026-11', undefined, false);
  await t('pool drop: all drops cannot be wiped', 'owner', 'DELETE', L + 'pool_drops', undefined, false);
  await t('pool drop run: summary', 'anon', 'PUT', L + 'pool_drop_runs/2026-11', { members: 3, points: 12, at: TS }, false);
  await t('pool drop run: summary', 'owner', 'PUT', L + 'pool_drop_runs/2026-11', { members: 3, points: 12, at: TS }, true);
  await t('pool drop run: overwrite', 'owner', 'PUT', L + 'pool_drop_runs/2026-11', { members: 9, points: 99, at: TS }, false);

  const bonus = (o) => Object.assign({ memberKey: 'K1', name: 'Kayla', points: 5, reason: 'Posted a video', at: TS }, o || {});
  await t('bonus record: give 5 points with a reason', 'anon', 'PUT', L + 'bonuses/b1', bonus(), false);
  await t('bonus record: give 5 points with a reason', 'owner', 'PUT', L + 'bonuses/b1', bonus(), true);
  await t('bonus record: no reason (validation still applies)', 'owner', 'PUT', L + 'bonuses/b2', bonus({ reason: '' }), false);
  await t('bonus record: 5000 points (validation still applies)', 'owner', 'PUT', L + 'bonuses/b3', bonus({ points: 5000 }), false);
  await t('bonus record: edit an existing one', 'owner', 'PUT', L + 'bonuses/b1', bonus({ points: 500 }), false);
  await t('bonus record: delete one', 'owner', 'DELETE', L + 'bonuses/b1', undefined, false);
  await t('bonus record: wipe all', 'owner', 'DELETE', L + 'bonuses', undefined, false);

  await t('credit ledger: add credit', 'anon', 'POST', L + 'fundings/van', { amount: 500, note: 'gift', at: TS }, false);
  const fr = await call('owner', 'POST', L + 'fundings/van', { amount: 500, note: 'gift', at: TS });
  check('[owner] credit ledger: add credit', fr, true);
  const fid = JSON.parse(fr.t).name;
  await t('credit ledger: amount 0 (validation still applies)', 'owner', 'POST', L + 'fundings/van', { amount: 0, at: TS }, false);
  await t('credit ledger: delete an entry', 'owner', 'DELETE', L + 'fundings/van/' + fid, undefined, false);
  await t('credit ledger: edit an entry', 'owner', 'PATCH', L + 'fundings/van/' + fid, { amount: 1 }, false);
  await t('credit ledger: still readable (restaurant portal)', 'anon', 'GET', L + 'fundings/van', undefined, true);

  // =====================================================================
  // 3. INSTAGRAM TAG CLAIMS: member creates pending; only the owner decides
  // =====================================================================
  const claim = (o) => Object.assign({ memberKey: 'K1', token: TOK, handle: '@kayla', postUrl: 'https://www.instagram.com/p/ABC123/', status: 'pending', submittedAt: TS }, o || {});
  await t('tag: member submits an Instagram post link', 'anon', 'PUT', L + 'tag_claims/c1', claim(), true);
  await t('tag: member submits through POST (what the page does)', 'anon', 'POST', L + 'tag_claims', claim({ postUrl: 'https://www.instagram.com/p/POST1/' }), true);
  await t('tag: a link that is not Instagram', 'anon', 'PUT', L + 'tag_claims/c2', claim({ postUrl: 'https://evil.example.com/p/1' }), false);
  await t('tag: a claim that arrives already approved', 'anon', 'PUT', L + 'tag_claims/c3', claim({ status: 'approved' }), false);
  await t('tag: a claim that arrives with points already awarded', 'anon', 'PUT', L + 'tag_claims/c4', claim({ pointsAwarded: 5 }), false);
  await t('tag: a claim that arrives with decidedAt', 'anon', 'PUT', L + 'tag_claims/c5', claim({ decidedAt: TS }), false);
  await t('tag: a claim that arrives marked as applied', 'anon', 'PUT', L + 'tag_claims/c6', claim({ pointsApplied: true }), false);
  await t('tag: member cannot approve their own claim', 'anon', 'PATCH', L + 'tag_claims/c1', { status: 'approved', pointsAwarded: 5, pointsApplied: false, decidedAt: TS }, false);
  await t('tag: member cannot reject a claim', 'anon', 'PATCH', L + 'tag_claims/c1', { status: 'rejected', decidedAt: TS }, false);
  await t('tag: member cannot award points alone', 'anon', 'PATCH', L + 'tag_claims/c1', { pointsAwarded: 50 }, false);
  await t('tag: a signed-in NON-owner cannot approve', 'other', 'PATCH', L + 'tag_claims/c1', { status: 'approved', pointsAwarded: 5, pointsApplied: false, decidedAt: TS }, false);
  await t('tag: owner approves a pending claim', 'owner', 'PATCH', L + 'tag_claims/c1', { status: 'approved', pointsAwarded: 5, pointsApplied: false, decidedAt: TS }, true);
  await t('tag: member cannot mark it applied', 'anon', 'PATCH', L + 'tag_claims/c1', { pointsApplied: true }, false);
  await t('tag: owner marks points applied', 'owner', 'PATCH', L + 'tag_claims/c1', { pointsApplied: true }, true);
  await t('tag: the post link cannot be swapped after approval (owner)', 'owner', 'PATCH', L + 'tag_claims/c1', { postUrl: 'https://www.instagram.com/p/OTHER/' }, false);
  await t('tag: approved cannot flip to rejected (owner)', 'owner', 'PATCH', L + 'tag_claims/c1', { status: 'rejected' }, false);
  await t('tag: awarded points cannot be changed (owner)', 'owner', 'PATCH', L + 'tag_claims/c1', { pointsAwarded: 50 }, false);
  await t('tag: a decision on a claim that does not exist', 'owner', 'PATCH', L + 'tag_claims/c1b', { status: 'rejected', decidedAt: TS }, false);
  await t('tag: a claim cannot be deleted', 'owner', 'DELETE', L + 'tag_claims/c1', undefined, false);
  await t('tag: all claims cannot be wiped', 'owner', 'DELETE', L + 'tag_claims', undefined, false);
  await t('tag: duplicate-link query works (indexed read)', 'anon', 'GET', L + 'tag_claims', undefined, true);
  await t('tag: another member claim arrives pending', 'anon', 'PUT', L + 'tag_claims/c7', claim({ postUrl: 'https://www.instagram.com/p/REJ1/' }), true);
  await t('tag: owner can reject a pending claim', 'owner', 'PATCH', L + 'tag_claims/c7', { status: 'rejected', decidedAt: TS }, true);

  // =====================================================================
  // 4. ROUND ONE REGISTRY: anonymous registers; only the owner changes status
  // =====================================================================
  const R1 = L + 'round1/';
  await t('round one: new sign-up registered as pending', 'anon', 'PUT', R1 + '-Mk1', { name: 'Lisa W.', at: TS, status: 'pending' }, true);
  await t('round one: new sign-up registered as approved (approval switched off)', 'anon', 'PUT', R1 + '-Mk4', { name: 'Ann B.', at: TS, status: 'approved' }, true);
  await t('round one: anonymous approves a pending entry', 'anon', 'PATCH', R1 + '-Mk1', { status: 'approved' }, false);
  await t('round one: anonymous declines an entry', 'anon', 'PATCH', R1 + '-Mk4', { status: 'rejected' }, false);
  await t('round one: a signed-in NON-owner cannot approve', 'other', 'PATCH', R1 + '-Mk1', { status: 'approved' }, false);
  await t('round one: owner approves (status only)', 'owner', 'PATCH', R1 + '-Mk1', { status: 'approved' }, true);
  await t('round one: owner declines (frees the spot)', 'owner', 'PATCH', R1 + '-Mk1', { status: 'rejected' }, true);
  await t('round one: owner puts a registry entry back to pending (admin tool fallback PUT)', 'owner', 'PUT', R1 + '-Mk5', { name: 'Zed Z.', at: 1700000000000, status: 'pending' }, true);
  await t('round one: anonymous re-writes an existing entry (same name/at)', 'anon', 'PUT', R1 + '-Mk5', { name: 'Zed Z.', at: 1700000000000, status: 'approved' }, false);
  await t('round one: cannot rename a registered member (anonymous)', 'anon', 'PATCH', R1 + '-Mk1', { name: 'Someone Else' }, false);
  await t('round one: cannot rename a registered member (owner)', 'owner', 'PATCH', R1 + '-Mk1', { name: 'Someone Else' }, false);
  await t('round one: cannot register as already rejected', 'anon', 'PUT', R1 + '-Mk2', { name: 'Bad', at: TS, status: 'rejected' }, false);
  await t('round one: cannot delete an entry (anonymous)', 'anon', 'DELETE', R1 + '-Mk1', undefined, false);
  await t('round one: cannot delete an entry (owner)', 'owner', 'DELETE', R1 + '-Mk1', undefined, false);
  await t('round one: long name refused', 'anon', 'PUT', R1 + '-Mk3', { name: 'x'.repeat(60), at: TS, status: 'pending' }, false);
  await t('round one: registry readable (leaderboard)', 'anon', 'GET', L + 'round1', undefined, true);

  // =====================================================================
  // 5. MEMBERS (lvr_rewards)
  // =====================================================================
  await t('members are readable by anyone (unchanged)', 'anon', 'GET', '/lvr_rewards', undefined, true);
  // ---- sign-up exactly as rewards.html does it
  await t('sign-up: new member, 0 points, status pending (approval ON)', 'anon', 'POST', '/lvr_rewards', { name: 'Bob', email: 'b@example.com', phone: '555', points: 0, token: 'tokBobabcdefabcdefabcd', refCode: 'BOB234', source: 'keytechnologies-rewards-signup', joinedAt: TS, consent_rules: true, consent_rules_ts: TS, consent_terms: '2026-10-30e', consent_terms_ts: TS, status: 'pending', referredBy: 'K1' }, true);
  await t('sign-up: new member, 0 points, no status field (approval switched off, no welcome)', 'anon', 'POST', '/lvr_rewards', { name: 'Fran', points: 0, token: 'tokFranabcdefabcdefab', refCode: 'FRAN234', joinedAt: TS, founding: true }, true);
  await t('sign-up: new member written with a chosen key (PUT), pending', 'anon', 'PUT', '/lvr_rewards/-Mkp', { name: 'Pat', points: 0, token: 'tokPatabcdefabcdefabcd', refCode: 'PAT234', joinedAt: TS, status: 'pending' }, true);
  await t('sign-up: arrives already approved', 'anon', 'POST', '/lvr_rewards', { name: 'Sneaky', points: 0, token: 'tokSneakyabcdefabcdef', status: 'approved' }, false);
  await t('sign-up: arrives rejected', 'anon', 'POST', '/lvr_rewards', { name: 'Sneaky', points: 0, token: 'tokSneakyabcdefabcdef', status: 'rejected' }, false);
  await t('sign-up: arrives with an approval date', 'anon', 'POST', '/lvr_rewards', { name: 'Sneaky', points: 0, token: 'tokSneakyabcdefabcdef', status: 'pending', approvedAt: TS }, false);
  await t('sign-up: arrives with a decision date', 'anon', 'POST', '/lvr_rewards', { name: 'Sneaky', points: 0, token: 'tokSneakyabcdefabcdef', status: 'pending', decidedAt: TS }, false);
  await t('sign-up: starting with 50 points', 'anon', 'POST', '/lvr_rewards', { name: 'Cheat', points: 50, token: 'tokCheatabcdefabcdefab' }, false);
  await t('sign-up: 0 points but a welcome record already attached', 'anon', 'POST', '/lvr_rewards', { name: 'Cheat', points: 0, token: 'tokCheatabcdefabcdefab', welcomeGiven: { amount: 13, via: 'signup', at: TS } }, false);
  await t('sign-up: no name', 'anon', 'POST', '/lvr_rewards', { points: 0, token: 'tokNoNameabcdefabcdef' }, false);
  await t('sign-up: unknown status word (validation still applies)', 'anon', 'POST', '/lvr_rewards', { name: 'X', points: 0, status: 'vip' }, false);
  // welcome points at sign-up are refused now, even when the owner has the welcome bonus ON in sign-up mode
  const welMember = pts => ({ name: 'Wel', token: 'welcometoken123456789', refCode: 'WELC123', points: pts, welcomeGiven: { amount: pts, via: 'signup', at: TS } });
  await call('admin', 'PUT', S + 'welcome', { enabled: true, amount: 13, when: 'signup' });
  await t('sign-up: 13 welcome points at sign-up while the bonus is on (old flow, now refused)', 'anon', 'POST', '/lvr_rewards', welMember(13), false);
  await t('sign-up: welcome points, 14 when the bonus is 13', 'anon', 'POST', '/lvr_rewards', welMember(14), false);
  await t('sign-up: 13 points without any welcome record', 'anon', 'POST', '/lvr_rewards', { name: 'Wel', token: 'welcometoken123456789', refCode: 'WELC124', points: 13 }, false);
  await t('sign-up: owner can still create a member with a welcome record', 'owner', 'POST', '/lvr_rewards', welMember(13), true);
  await call('admin', 'DELETE', S + 'welcome');
  // ---- owner approval: status / approvedAt / decidedAt / welcomeGiven are owner-only
  await t('approval: member approves themselves (status)', 'anon', 'PATCH', '/lvr_rewards/PEND1', { status: 'approved' }, false);
  await t('approval: member approves themselves (status + approvedAt)', 'anon', 'PATCH', '/lvr_rewards/PEND1', { status: 'approved', approvedAt: TS }, false);
  await t('approval: member sets only an approval date', 'anon', 'PATCH', '/lvr_rewards/PEND1', { approvedAt: TS }, false);
  await t('approval: member sets only a decision date', 'anon', 'PATCH', '/lvr_rewards/PEND1', { decidedAt: TS }, false);
  await t('approval: member overwrites their whole record as approved', 'anon', 'PUT', '/lvr_rewards/PEND1', { name: 'Pending Pat', points: 0, token: 'tokPend1abcdefabcdefab', refCode: 'PEND123', joinedAt: 1700000000000, status: 'approved' }, false);
  await t('approval: member removes the pending flag (DELETE status)', 'anon', 'DELETE', '/lvr_rewards/PEND1/status', undefined, false);
  await t('approval: a signed-in NON-owner approves', 'other', 'PATCH', '/lvr_rewards/PEND1', { status: 'approved', approvedAt: TS }, false);
  await t('approval: owner approves (status + approvedAt, as the admin tool does)', 'owner', 'PATCH', '/lvr_rewards/PEND1', { status: 'approved', approvedAt: TS }, true);
  await t('approval: junk status value (validation still applies)', 'owner', 'PATCH', '/lvr_rewards/PEND1', { status: 'vip' }, false);
  await t('approval: member sets their approved status back to pending', 'anon', 'PATCH', '/lvr_rewards/PEND1', { status: 'pending' }, false);
  await t('approval: owner declines (status + decidedAt)', 'owner', 'PATCH', '/lvr_rewards/-Mkp', { status: 'rejected', decidedAt: TS }, true);
  await t('approval: owner rolls back to pending (admin tool rollback)', 'owner', 'PATCH', '/lvr_rewards/-Mkp', { status: 'pending' }, true);
  // ---- welcomeGiven marker
  await t('welcome marker: member writes their own welcomeGiven (PATCH)', 'anon', 'PATCH', '/lvr_rewards/K1', { welcomeGiven: { amount: 12, receiptId: 'r1', at: TS } }, false);
  await t('welcome marker: member writes their own welcomeGiven (PUT child)', 'anon', 'PUT', '/lvr_rewards/K1/welcomeGiven', { amount: 12, via: 'approval', at: TS }, false);
  await t('welcome marker: a signed-in NON-owner', 'other', 'PUT', '/lvr_rewards/K1/welcomeGiven', { amount: 12, via: 'approval', at: TS }, false);
  await t('welcome marker: owner claims it first (admin tool)', 'owner', 'PUT', '/lvr_rewards/K1/welcomeGiven', { amount: 12, via: 'approval', at: TS }, true);
  await t('welcome marker: member edits the amount', 'anon', 'PUT', '/lvr_rewards/K1/welcomeGiven/amount', 99, false);
  await t('welcome marker: member removes it', 'anon', 'DELETE', '/lvr_rewards/K1/welcomeGiven', undefined, false);
  await t('welcome marker: owner removes it (admin tool rollback)', 'owner', 'DELETE', '/lvr_rewards/K1/welcomeGiven', undefined, true);
  // ---- an approved member who already has the owner's markers keeps using the app normally
  await call('admin', 'PUT', '/lvr_rewards/WG1', { name: 'Approved Ann', points: 20, token: 'tokWG1abcdefabcdefabcd', refCode: 'WG1CODE', joinedAt: 1700000000000, status: 'approved', approvedAt: 1700000100000, decidedAt: 1700000100000, welcomeGiven: { amount: 12, via: 'approval', at: 1700000100000 } });
  await t('approved member with markers: spin credit (points increment)', 'anon', 'PUT', '/lvr_rewards/WG1/points', { '.sv': { increment: 2 } }, true);
  await t('approved member with markers: redeem (points decrement)', 'anon', 'PUT', '/lvr_rewards/WG1/points', { '.sv': { increment: -5 } }, true);
  await t('approved member with markers: consent PATCH', 'anon', 'PATCH', '/lvr_rewards/WG1', { consent_terms: '2026-10-30e', consent_terms_ts: TS }, true);
  await t('approved member with markers: dashboard PATCH points', 'anon', 'PATCH', '/lvr_rewards/WG1', { points: 50 }, true);
  await t('approved member with markers: change approval date', 'anon', 'PATCH', '/lvr_rewards/WG1', { approvedAt: TS }, false);
  await t('approved member with markers: change the welcome date', 'anon', 'PUT', '/lvr_rewards/WG1/welcomeGiven/at', 5, false);
  await t('approved member with markers: add a receiptId to the welcome record', 'anon', 'PUT', '/lvr_rewards/WG1/welcomeGiven/receiptId', 'r9', false);
  await t('approved member with markers: reject themselves', 'anon', 'PATCH', '/lvr_rewards/WG1', { status: 'rejected' }, false);
  // ---- everything the member pages still do (unchanged)
  await t('points: server-side increment (spin credit)', 'anon', 'PUT', '/lvr_rewards/K1/points', { '.sv': { increment: 10 } }, true);
  await t('points: server-side decrement (redeem)', 'anon', 'PUT', '/lvr_rewards/K1/points', { '.sv': { increment: -20 } }, true);
  await t('points: set to an absolute value (dashboard PATCH points)', 'anon', 'PATCH', '/lvr_rewards/K1', { points: 105 }, true);
  await t('points: owner tool increment', 'owner', 'PUT', '/lvr_rewards/K1/points', { '.sv': { increment: 6 } }, true);
  await t('points: set negative (validation still applies)', 'anon', 'PUT', '/lvr_rewards/K1/points', -5, false);
  await t('points: set to text (validation still applies)', 'anon', 'PUT', '/lvr_rewards/K1/points', 'lots', false);
  await t('points: a pending member can be credited too (dashboard)', 'anon', 'PUT', '/lvr_rewards/-Mkp/points', { '.sv': { increment: 1 } }, true);
  await t('consent: terms agreement PATCH on a member', 'anon', 'PATCH', '/lvr_rewards/K1', { consent_terms: '2026-10-30e', consent_terms_ts: TS }, true);
  await t('lazy refCode for a member without one', 'anon', 'PATCH', '/lvr_rewards/K2', { refCode: 'K2CODE' }, true);
  await t('give an old member a token (Generate Link)', 'anon', 'PUT', '/lvr_rewards/K2/token', 'tokK2abcdefabcdefabcdefab', true);
  await t('referral bonus fields (refCarry / refBonusTotal)', 'owner', 'PATCH', '/lvr_rewards/K1', { refCarry: 0.4, refBonusTotal: 2 }, true);
  await t('referral bonus fields (refCarry / refBonusTotal), anonymous (unchanged)', 'anon', 'PATCH', '/lvr_rewards/K1', { refCarry: 0.4, refBonusTotal: 2 }, true);
  await t('change a member\'s personal-link token', 'anon', 'PUT', '/lvr_rewards/K1/token', 'hijackedtokenhijackedtoken', false);
  await t('change a member\'s personal-link token (owner)', 'owner', 'PUT', '/lvr_rewards/K1/token', 'hijackedtokenhijackedtoken', false);
  await t('change an existing refCode', 'anon', 'PUT', '/lvr_rewards/K1/refCode', 'HACK99', false);
  await t('add or change referredBy after sign-up', 'anon', 'PUT', '/lvr_rewards/K1/referredBy', 'K2', false);
  await t('sign-up that names who invited them (allowed at creation only)', 'anon', 'POST', '/lvr_rewards', { name: 'Friend', points: 0, token: 'tokFriendabcdefabcdefa', referredBy: 'K1' }, true);
  // ---- bonus spin (chest) claim rules are unchanged
  await call('admin', 'PUT', S + 'chest', CH);
  const mem = (nm, tok, rc, joinedAgo) => ({ name: nm, token: tok, refCode: rc, points: 0, joinedAt: Date.now() - joinedAgo, status: 'approved' });
  await call('admin', 'PUT', '/lvr_rewards/OLD1', mem('Old', 'oldtokenoldtokenoldtoken', 'OLDC123', 11 * DAYMS));
  await call('admin', 'PUT', '/lvr_rewards/NEW1', mem('New', 'newtokennewtokennewtoken', 'NEWC123', 3 * DAYMS));
  await call('admin', 'PUT', '/lvr_rewards/LATE1', mem('Late', 'latetokenlatetokenlate1', 'LATEC12', 20 * DAYMS));
  await call('admin', 'PUT', '/lvr_rewards/AGAIN1', mem('Again', 'againtokenagaintoken01', 'AGAINC1', 35 * DAYMS));
  await t('spin claim: first claim on day 11 (inside the 48 hours)', 'anon', 'PUT', '/lvr_rewards/OLD1/chestState', { n: 1, amount: 1, at: TS }, true);
  await t('spin credit: points added right after the claim', 'anon', 'PUT', '/lvr_rewards/OLD1/points', { '.sv': { increment: 1 } }, true);
  await t('spin log: chest_log entry', 'anon', 'PUT', L + 'chest_log/OLD1/1', { amount: 1, at: TS, terms: '2026-10-30', confirmedReal: true }, true);
  await t('spin log: overwrite a log entry', 'anon', 'PUT', L + 'chest_log/OLD1/1', { amount: 2, at: TS }, false);
  await t('spin claim: same claim again (n stays 1)', 'anon', 'PATCH', '/lvr_rewards/OLD1', { chestState: { n: 1, amount: 1, at: TS } }, false);
  await t('spin claim: remove the claim state to re-claim', 'anon', 'PUT', '/lvr_rewards/OLD1/chestState', null, false);
  await t('spin claim: second claim right away (needs 10 days)', 'anon', 'PATCH', '/lvr_rewards/OLD1', { chestState: { n: 2, amount: 2, at: TS } }, false);
  await t('spin claim: during the first waiting period', 'anon', 'PATCH', '/lvr_rewards/NEW1', { chestState: { n: 1, amount: 1, at: TS } }, false);
  await t('spin claim: after the 48 hours closed', 'anon', 'PATCH', '/lvr_rewards/LATE1', { chestState: { n: 1, amount: 1, at: TS } }, false);
  await t('spin claim: in the next window (day 35)', 'anon', 'PATCH', '/lvr_rewards/AGAIN1', { chestState: { n: 1, amount: 1, at: TS } }, true);
  await t('spin claim: prize above the allowed maximum', 'anon', 'PATCH', '/lvr_rewards/OLD1', { chestState: { n: 2, amount: 9, at: TS } }, false);
  await t('spin claim: skipping a number', 'anon', 'PATCH', '/lvr_rewards/OLD1', { chestState: { n: 3, amount: 1, at: TS } }, false);
  await call('admin', 'PUT', '/lvr_rewards/OLD1/chestState', { n: 1, amount: 1, at: Date.now() - 11 * DAYMS });
  await t('spin claim: second claim 11 days after the first', 'anon', 'PATCH', '/lvr_rewards/OLD1', { chestState: { n: 2, amount: 2, at: TS } }, true);
  await call('admin', 'PUT', '/lvr_rewards/OLD1/chestState', { n: 2, amount: 2, at: Date.now() - 9 * DAYMS });
  await t('spin claim: third claim after only 9 days', 'anon', 'PATCH', '/lvr_rewards/OLD1', { chestState: { n: 3, amount: 1, at: TS } }, false);
  await call('admin', 'PUT', S + 'chest/repeat', false);
  await call('admin', 'PUT', '/lvr_rewards/OLD1/chestState', { n: 1, amount: 1, at: Date.now() - 11 * DAYMS });
  await t('spin claim: repeat switched off blocks a second bonus', 'anon', 'PATCH', '/lvr_rewards/OLD1', { chestState: { n: 2, amount: 1, at: TS } }, false);
  await call('admin', 'PUT', S + 'chest/repeat', true);
  // ---- deleting members
  await t('delete ONE member (anonymous): now owner-only', 'anon', 'DELETE', '/lvr_rewards/K2', undefined, false);
  await t('delete ONE member (a signed-in NON-owner)', 'other', 'DELETE', '/lvr_rewards/K2', undefined, false);
  await t('delete ONE member (owner, admin-tool cleanup / data-deletion request)', 'owner', 'DELETE', '/lvr_rewards/K2', undefined, true);
  await t('wipe ALL members in one request (anonymous)', 'anon', 'DELETE', '/lvr_rewards', undefined, false);
  await t('wipe ALL members in one request (owner)', 'owner', 'DELETE', '/lvr_rewards', undefined, false);
  await t('overwrite the whole members list (anonymous)', 'anon', 'PUT', '/lvr_rewards', { x: { name: 'x', points: 0 } }, false);
  await t('overwrite the whole members list (owner: the list itself has no write rule, as before)', 'owner', 'PUT', '/lvr_rewards', { x: { name: 'x', points: 0, token: 'xxxxxxxxxxxxxxxxxxxx' } }, false);
  await call('admin', 'PUT', '/lvr_rewards/K1', { name: 'Kayla', points: 100, token: TOK, refCode: 'ABC234', joinedAt: 1700000000000, status: 'approved' });

  // =====================================================================
  // 6. RECEIPTS: member creates pending; only the owner decides
  // =====================================================================
  let rr = await call('anon', 'POST', R, goodReceipt());
  check('[anon] submit a receipt', rr, true);
  const rid = JSON.parse(rr.t).name;
  await t('submit a receipt already marked approved', 'anon', 'POST', R, goodReceipt({ status: 'approved' }), false);
  await t('submit a receipt already marked rejected', 'anon', 'POST', R, goodReceipt({ status: 'rejected' }), false);
  await t('submit a receipt with points pre-awarded', 'anon', 'POST', R, goodReceipt({ pointsAwarded: 500 }), false);
  await t('submit a receipt with points pre-applied', 'anon', 'POST', R, goodReceipt({ pointsApplied: true }), false);
  await t('submit a receipt with referralDone', 'anon', 'POST', R, goodReceipt({ referralDone: true }), false);
  await t('submit a receipt with welcomeAwarded', 'anon', 'POST', R, goodReceipt({ welcomeAwarded: 50 }), false);
  await t('submit a receipt with a decision date', 'anon', 'POST', R, goodReceipt({ decidedAt: TS }), false);
  await t('submit a receipt with referral level flags', 'anon', 'POST', R, goodReceipt({ refL1Done: true, refL1Points: 9 }), false);
  await t('submit a receipt with a restaurant flag already on it', 'anon', 'POST', R, goodReceipt({ restFlag: { note: 'x', at: TS } }), false);
  await t('submit a $0 receipt', 'anon', 'POST', R, goodReceipt({ amount: 0 }), false);
  await t('submit a $9,999 receipt', 'anon', 'POST', R, goodReceipt({ amount: 9999 }), false);
  await t('submit a receipt with no token', 'anon', 'POST', R, (() => { const r = goodReceipt(); delete r.token; return r; })(), false);
  await t('approve (what the admin tool does)', 'anon', 'PATCH', R + '/' + rid, { status: 'approved', pointsAwarded: 6, pointsApplied: false, referralDone: false, decidedAt: TS }, false);
  await t('approve with only the status', 'anon', 'PATCH', R + '/' + rid, { status: 'approved' }, false);
  await t('award points only', 'anon', 'PATCH', R + '/' + rid, { pointsAwarded: 600 }, false);
  await t('approve (a signed-in NON-owner)', 'other', 'PATCH', R + '/' + rid, { status: 'approved', pointsAwarded: 6, pointsApplied: false, referralDone: false, decidedAt: TS }, false);
  await t('approve (what the admin tool does)', 'owner', 'PATCH', R + '/' + rid, { status: 'approved', pointsAwarded: 6, pointsApplied: false, referralDone: false, decidedAt: TS }, true);
  await t('mark points applied', 'anon', 'PATCH', R + '/' + rid, { pointsApplied: true }, false);
  await t('mark points applied', 'owner', 'PATCH', R + '/' + rid, { pointsApplied: true }, true);
  await t('referral flags (referralDone / refL1Done / refL1Points)', 'anon', 'PATCH', R + '/' + rid, { refL1Done: true, refL1Points: 1, referralDone: true }, false);
  await t('referral flags (referralDone / refL1Done / refL1Points)', 'owner', 'PATCH', R + '/' + rid, { refL1Done: true, refL1Points: 1, referralDone: true }, true);
  await t('welcome bonus recorded on the receipt', 'anon', 'PATCH', R + '/' + rid, { welcomeAwarded: 12 }, false);
  await t('welcome bonus recorded on the receipt', 'owner', 'PATCH', R + '/' + rid, { welcomeAwarded: 12 }, true);
  await t('restaurant flags an approved receipt (portal "flag")', 'anon', 'PATCH', R + '/' + rid, { restFlag: { note: 'looks high', at: TS } }, true);
  await t('restaurant flag: written directly at the flag path', 'anon', 'PUT', R + '/' + rid + '/restFlag', { note: 'still looks high', at: TS }, true);
  await t('restaurant flag: cannot be removed by anonymous', 'anon', 'DELETE', R + '/' + rid + '/restFlag', undefined, false);
  await t('restaurant flag: a receipt that does not exist', 'anon', 'PATCH', R + '/-NoSuchReceipt', { restFlag: { note: 'x', at: TS } }, false);
  await t('restaurant flag: owner can clear it after review', 'owner', 'DELETE', R + '/' + rid + '/restFlag', undefined, true);
  await t('flag + approve in one request', 'anon', 'PATCH', R + '/' + rid, { restFlag: { note: 'n', at: TS }, status: 'approved' }, false);
  await t('change the amount of a receipt (anonymous)', 'anon', 'PATCH', R + '/' + rid, { amount: 1 }, false);
  await t('change the amount of a receipt (owner)', 'owner', 'PATCH', R + '/' + rid, { amount: 1 }, false);
  await t('change the receipt number', 'anon', 'PATCH', R + '/' + rid, { receiptNo: '9999' }, false);
  await t('change the receipt date', 'anon', 'PATCH', R + '/' + rid, { receiptDate: '2026-01-01' }, false);
  await t('change the member name on a receipt', 'anon', 'PATCH', R + '/' + rid, { name: 'Someone Else' }, false);
  await t('re-open a decided receipt (back to pending), anonymous', 'anon', 'PATCH', R + '/' + rid, { status: 'pending' }, false);
  await t('re-open a decided receipt (back to pending), owner', 'owner', 'PATCH', R + '/' + rid, { status: 'pending' }, false);
  await t('flip approved to rejected, anonymous', 'anon', 'PATCH', R + '/' + rid, { status: 'rejected' }, false);
  await t('flip approved to rejected, owner', 'owner', 'PATCH', R + '/' + rid, { status: 'rejected' }, false);
  await t('change points already awarded, anonymous', 'anon', 'PATCH', R + '/' + rid, { pointsAwarded: 5000 }, false);
  await t('change points already awarded, owner', 'owner', 'PATCH', R + '/' + rid, { pointsAwarded: 5000 }, false);
  await t('DELETE a receipt (anonymous)', 'anon', 'DELETE', R + '/' + rid, undefined, false);
  await t('DELETE a receipt (owner)', 'owner', 'DELETE', R + '/' + rid, undefined, false);
  await t('wipe ALL receipts (anonymous)', 'anon', 'DELETE', R, undefined, false);
  await t('wipe ALL receipts (owner)', 'owner', 'DELETE', R, undefined, false);
  await t('wipe the whole points program', 'owner', 'DELETE', '/lvr_points', undefined, false);
  await t('overwrite the whole points program', 'owner', 'PUT', '/lvr_points', { receipts: {} }, false);
  await t('receipts can be read / queried by token', 'anon', 'GET', R, undefined, true);
  // owner rejects a pending receipt
  rr = await call('admin', 'PUT', R + '/OLDPEND', goodReceipt({ receiptNo: '5002', submittedAt: Date.now() - 3 * HRMS }));
  await t('reject an older pending receipt, anonymous', 'anon', 'PATCH', R + '/OLDPEND', { status: 'rejected', decidedAt: TS }, false);
  await t('reject an older pending receipt, a signed-in NON-owner', 'other', 'PATCH', R + '/OLDPEND', { status: 'rejected', decidedAt: TS }, false);
  await t('reject (what the admin tool does), owner', 'owner', 'PATCH', R + '/OLDPEND', { status: 'rejected', decidedAt: TS }, true);
  // ---- the one deliberate exception: the member page voids a receipt whose photo upload just failed
  rr = await call('anon', 'POST', R, goodReceipt({ receiptNo: '6001' })); const v1 = JSON.parse(rr.t).name;
  rr = await call('anon', 'POST', R, goodReceipt({ receiptNo: '6002' })); const v2 = JSON.parse(rr.t).name;
  rr = await call('anon', 'POST', R, goodReceipt({ receiptNo: '6003' })); const v3 = JSON.parse(rr.t).name;
  rr = await call('anon', 'POST', R, goodReceipt({ receiptNo: '6004' })); const v4 = JSON.parse(rr.t).name;
  await call('admin', 'PUT', R + '/OLDPEND2', goodReceipt({ receiptNo: '6005', submittedAt: Date.now() - 20 * 60000 }));
  await t('void: a decision date alone on a pending receipt', 'anon', 'PATCH', R + '/' + v1, { decidedAt: TS }, false);
  await t('void: approving a brand-new pending receipt', 'anon', 'PATCH', R + '/' + v1, { status: 'approved', decidedAt: TS }, false);
  await t('void: rejecting and awarding points in the same request', 'anon', 'PATCH', R + '/' + v1, { status: 'rejected', decidedAt: TS, pointsAwarded: 50 }, false);
  await t('void: rejecting and changing the amount in the same request', 'anon', 'PATCH', R + '/' + v1, { status: 'rejected', decidedAt: TS, amount: 1 }, false);
  await t('void: a pending receipt older than 10 minutes cannot be voided anonymously', 'anon', 'PATCH', R + '/OLDPEND2', { status: 'rejected', decidedAt: TS }, false);
  await t('void: the member page voids a brand-new pending receipt (status rejected + decidedAt)', 'anon', 'PATCH', R + '/' + v1, { status: 'rejected', decidedAt: TS }, true);
  await t('void: it cannot be un-voided', 'anon', 'PATCH', R + '/' + v1, { status: 'pending' }, false);
  await t('void: it cannot be un-voided by the owner either (decided receipts are final)', 'owner', 'PATCH', R + '/' + v1, { status: 'pending' }, false);
  await t('void: the decision date cannot be changed afterwards', 'anon', 'PATCH', R + '/' + v1, { decidedAt: TS }, false);
  await t('void: owner can still reject a fresh pending receipt', 'owner', 'PATCH', R + '/' + v2, { status: 'rejected', decidedAt: TS }, true);
  await t('void: owner can approve a fresh pending receipt', 'owner', 'PATCH', R + '/' + v3, { status: 'approved', pointsAwarded: 3, pointsApplied: false, referralDone: false, decidedAt: TS }, true);
  await t('void: an approved receipt cannot be voided anonymously', 'anon', 'PATCH', R + '/' + v3, { status: 'rejected', decidedAt: TS }, false);
  await t('void: the restaurant flag still works on a pending receipt', 'anon', 'PATCH', R + '/' + v4, { restFlag: { note: 'check', at: TS } }, true);

  // =====================================================================
  // 7. PHOTOS, REDEMPTIONS (unchanged, still open on purpose)
  // =====================================================================
  const P = L + 'receipt_photos/';
  await t('photos: upload two photos for a receipt', 'anon', 'PUT', P + v4, { wide: BIG, close: BIG }, true);
  await t('photos: upload a single screenshot (emailed receipt)', 'anon', 'PUT', P + 'zzz1', { wide: BIG }, true);
  await t('photos: legacy single-photo format', 'anon', 'PUT', P + 'zzz2', { data: BIG }, true);
  await t('photos: replace an existing photo', 'anon', 'PUT', P + v4, { wide: 'tampered' }, false);
  await t('photos: replace an existing photo (owner)', 'owner', 'PUT', P + v4, { wide: 'tampered' }, false);
  await t('photos: DELETE a photo', 'anon', 'DELETE', P + v4, undefined, false);
  await t('photos: edit one photo field', 'anon', 'PUT', P + v4 + '/wide', 'tampered', false);
  await t('photos: oversized photo (3 MB)', 'anon', 'PUT', P + 'zzz3', { wide: 'x'.repeat(3000000) }, false);
  await t('photos: junk fields', 'anon', 'PUT', P + 'zzz4', { wide: BIG, evil: 'x' }, false);
  await t('photos: wipe ALL photos', 'anon', 'DELETE', P.slice(0, -1), undefined, false);
  await t('photos: read one photo (admin tool, portal)', 'anon', 'GET', P + v4, undefined, true);

  const red = { token: TOK, name: 'Kayla', itemId: 'i1', itemName: 'Free Bowl', bizName: 'Vanilla Rice', pointCost: 10, code: 'VAN-AB2CD', redeemedAt: TS };
  const RD = L + 'redemptions/van';
  rr = await call('anon', 'POST', RD, red);
  check('[anon] redeem an offer (member app)', rr, true);
  const redId = JSON.parse(rr.t).name;
  await t('redeem: a redemption that costs nothing', 'anon', 'POST', RD, Object.assign({}, red, { pointCost: 0 }), false);
  await t('redeem: created already marked used', 'anon', 'POST', RD, Object.assign({}, red, { usedAt: 1 }), false);
  await t('redeem: restaurant marks a code used (portal)', 'anon', 'PATCH', RD + '/' + redId, { usedAt: TS }, true);
  await t('redeem: un-use / change usedAt', 'anon', 'PATCH', RD + '/' + redId, { usedAt: 5 }, false);
  await t('redeem: change a code', 'anon', 'PATCH', RD + '/' + redId, { code: 'FREE-ALL' }, false);
  await t('redeem: with a use-by date', 'anon', 'POST', RD, Object.assign({}, red, { code: 'VAN-USEBY1', useBy: Date.now() + DAYMS }), true);
  await t('redeem: extend a use-by date', 'anon', 'PATCH', RD + '/' + redId, { useBy: 9999999999999 }, false);
  await t('redeem: change a cost', 'anon', 'PATCH', RD + '/' + redId, { pointCost: 1 }, false);
  await t('redeem: delete one', 'anon', 'DELETE', RD + '/' + redId, undefined, false);
  await t('redeem: wipe all', 'anon', 'DELETE', L + 'redemptions', undefined, false);
  await t('redeem: the member points decrement that goes with it', 'anon', 'PUT', '/lvr_rewards/K1/points', { '.sv': { increment: -10 } }, true);
  await t('redeem: directory credit draw-down', 'anon', 'PUT', L + 'directory/van/creditRemaining', { '.sv': { increment: -10 } }, true);

  // =====================================================================
  // 8. LEDGER (transactions): spin / redeem stay open, every other type is owner-only
  // =====================================================================
  const T = L + 'transactions/K1/';
  const TX = (o) => Object.assign({ type: 'spin', amount: 5, at: TS, ref: 'Free spin #1', by: 'member' }, o || {});
  await t('ledger: a spin entry is recorded (member page)', 'anon', 'PUT', T + 'spin-1', TX(), true);
  await t('ledger: a redemption (negative amount) is recorded (member page)', 'anon', 'PUT', T + 'redeem-a1', TX({ type: 'redeem', amount: -20, ref: 'Free Chicken Bowl' }), true);
  await t('ledger: the owner can write a spin entry too', 'owner', 'PUT', T + 'spin-2', TX({ by: 'admin' }), true);
  for (const ty of ['welcome', 'receipt', 'opening', 'adjustment', 'bonus', 'referral']) {
    await t('ledger: a "' + ty + '" entry', 'anon', 'PUT', T + 'x-' + ty, TX({ type: ty, by: 'member' }), false);
    await t('ledger: a "' + ty + '" entry', 'other', 'PUT', T + 'x-' + ty, TX({ type: ty, by: 'member' }), false);
    await t('ledger: a "' + ty + '" entry', 'owner', 'PUT', T + 'x-' + ty, TX({ type: ty, by: 'admin' }), true);
  }
  await t('ledger: a welcome entry queued by the sign-up page (old welcome-on-sign-up flow)', 'anon', 'PUT', T + 'welcome', TX({ type: 'welcome', amount: 13, ref: 'Welcome points at sign-up' }), false);
  await t('ledger: a negative adjustment (emergency take-back, owner)', 'owner', 'PUT', T + 'return-2026-11', TX({ type: 'adjustment', amount: -3, by: 'admin' }), true);
  await t('ledger: the same entry cannot be written twice (anonymous)', 'anon', 'PUT', T + 'spin-1', TX({ amount: 9 }), false);
  await t('ledger: the same entry cannot be written twice (owner)', 'owner', 'PUT', T + 'spin-1', TX({ amount: 9 }), false);
  await t('ledger: an entry cannot be edited (anonymous)', 'anon', 'PATCH', T + 'spin-1', { amount: 9 }, false);
  await t('ledger: an entry cannot be edited (owner)', 'owner', 'PATCH', T + 'spin-1', { amount: 9 }, false);
  await t('ledger: an entry cannot be deleted (anonymous)', 'anon', 'DELETE', T + 'spin-1', undefined, false);
  await t('ledger: an entry cannot be deleted (owner)', 'owner', 'DELETE', T + 'spin-1', undefined, false);
  await t('ledger: all of a member\'s entries cannot be wiped', 'owner', 'DELETE', T.slice(0, -1), undefined, false);
  await t('ledger: everything cannot be wiped', 'owner', 'DELETE', L + 'transactions', undefined, false);
  await t('ledger: amount of zero is refused (owner)', 'owner', 'PUT', T + 'z1', TX({ type: 'bonus', amount: 0 }), false);
  await t('ledger: unknown type is refused (owner)', 'owner', 'PUT', T + 't1', TX({ type: 'free-money' }), false);
  await t('ledger: huge amount is refused (owner)', 'owner', 'PUT', T + 'h1', TX({ type: 'bonus', amount: 5000000 }), false);
  await t('ledger: back-dated entry is refused (owner)', 'owner', 'PUT', T + 'b1', TX({ type: 'bonus', at: Date.now() - DAYMS }), false);
  await t('ledger: junk extra field is refused (owner)', 'owner', 'PUT', T + 'j1', TX({ type: 'bonus', hack: true }), false);
  await t('ledger: back-dated spin is refused (anonymous)', 'anon', 'PUT', T + 'b2', TX({ at: Date.now() - DAYMS }), false);
  await t('ledger: junk extra field is refused (anonymous)', 'anon', 'PUT', T + 'j2', TX({ hack: true }), false);
  await t('ledger: huge spin amount is refused (anonymous)', 'anon', 'PUT', T + 'h2', TX({ amount: 5000000 }), false);
  await t('ledger: entries can be read', 'anon', 'GET', T.slice(0, -1), undefined, true);

  // =====================================================================
  // 9. THINGS THAT STAY OPEN ON PURPOSE (restaurant portal, registry, coupons, directory)
  // =====================================================================
  await t('catalog: create an item (restaurant / admin)', 'anon', 'PUT', L + 'catalog/van/bowl1', { itemName: 'Free Chicken Bowl', pointCost: 20, active: true }, true);
  await t('catalog: exactly 15 points is accepted', 'anon', 'PUT', L + 'catalog/van/min15', { itemName: 'Free Plate', pointCost: 15, active: true }, true);
  await t('catalog: 10 points is refused', 'anon', 'PUT', L + 'catalog/van/cheap', { itemName: 'Free Drink', pointCost: 10, active: true }, false);
  await t('catalog: lowering an existing offer to 14 is refused', 'anon', 'PATCH', L + 'catalog/van/bowl1', { pointCost: 14 }, false);
  await t('catalog: switching an offer off still works', 'anon', 'PATCH', L + 'catalog/van/bowl1', { active: false }, true);
  await t('catalog: delete one item', 'anon', 'DELETE', L + 'catalog/van/min15', undefined, true);
  await t('catalog: wipe the whole catalog', 'anon', 'DELETE', L + 'catalog', undefined, false);
  await t('restaurants: save a business + PIN', 'anon', 'PATCH', L + 'restaurants/van', { bizName: 'Vanilla Rice', pin: '1234', commissionPct: 15 }, true);
  await t('directory: save a directory entry', 'anon', 'PATCH', L + 'directory/van', { bizName: 'Vanilla Rice', earnRate: 0.05, active: true }, true);
  await t('directory: credit draw-down on redeem (member app)', 'anon', 'PUT', L + 'directory/van/creditRemaining', { '.sv': { increment: -10 } }, true);
  await t('directory: credit set by the owner (admin tool)', 'owner', 'PUT', L + 'directory/van/creditRemaining', 400, true);
  await t('unknown spot under lvr_points (anonymous)', 'anon', 'PUT', L + 'mystery', { a: 1 }, false);
  await t('unknown spot under lvr_points (owner)', 'owner', 'PUT', L + 'mystery', { a: 1 }, false);
  await t('coupons: create a program', 'anon', 'PUT', '/lvr_coupons/programs/van', { bizName: 'Vanilla Rice', offer: 'Free bowl', maxClaims: 50 }, true);
  await t('coupons: customer claims a coupon', 'anon', 'POST', '/lvr_coupons/claims/van', { name: 'A', email: 'a@example.com', code: '55555' }, true);
  await t('coupons: wipe all claims', 'anon', 'DELETE', '/lvr_coupons/claims', undefined, false);
  await t('coupons: wipe all programs', 'anon', 'DELETE', '/lvr_coupons/programs', undefined, false);
  await t('instagram index: duplicate-check entry for a new sign-up', 'anon', 'PUT', '/lvr_instagram_index/someone', true, true);
  await t('instagram index: owner cleanup removes an entry', 'owner', 'DELETE', '/lvr_instagram_index/someone', undefined, true);
  await t('instagram index: wipe the index', 'anon', 'DELETE', '/lvr_instagram_index', undefined, false);

  // =====================================================================
  // 10. THE MONTHLY RETURN SCRIPT (decay/monthly-decay.js) needs the owner token now
  // =====================================================================
  const preload = path.join(os.tmpdir(), 'lvr-owner-auth-preload.js');
  fs.writeFileSync(preload, "const f=globalThis.fetch;globalThis.fetch=(u,o)=>f(String(u)+(String(u).includes('?')?'&':'?')+'auth='+process.env.OWNER_JWT,o);\n");
  const seed = async () => {
    await call('admin', 'PUT', '/lvr_rewards', {
      OLD1: { name: 'Old One', points: 100, token: 'tokOld1abcdefabcdefabc', joinedAt: Date.now() - 90 * DAYMS },
      OLD2: { name: 'Old Two', points: 17, token: 'tokOld2abcdefabcdefabc', joinedAt: Date.now() - 60 * DAYMS },
      NEW1: { name: 'Brand New', points: 13, token: 'tokNew1abcdefabcdefabc', joinedAt: Date.now() - 3 * DAYMS },
      LOW1: { name: 'Few', points: 4, token: 'tokLow1abcdefabcdefabc', joinedAt: Date.now() - 90 * DAYMS },
      LEG1: { name: 'Legacy', points: 10 }
    });
    await call('admin', 'PUT', L + 'decay_by_member', null);
    await call('admin', 'PUT', L + 'decay_runs', null);
    await call('admin', 'PUT', L + 'pool', null);
    await call('admin', 'PUT', S + 'decay', { enabled: true, percent: 20, graceDays: 30 });
  };
  const sweep = (extra, signed) => {
    const script = path.join(__dirname, 'monthly-decay.js');
    const r = spawnSync('node', signed ? ['--require', preload, script] : [script], { env: Object.assign({}, process.env, { DB_URL: BASE, DB_NS: NS, RUN_KEY: '2026-11', OWNER_JWT: OWNER_JWT }, extra), encoding: 'utf8' });
    return r.stdout + r.stderr;
  };
  const bal = async k => JSON.parse((await call('admin', 'GET', '/lvr_rewards/' + k + '/points')).t);
  await seed();
  let o = sweep({}, false);
  check('[anon] the old anonymous sweep takes nothing (return records are owner-only)', { s: (await bal('OLD1')) === 100 && (await bal('OLD2')) === 17 && JSON.parse((await call('admin', 'GET', L + 'pool/total')).t) === null ? 200 : 500, t: o }, true);
  o = sweep({ DRY_RUN: '1' }, true);
  check('[owner] sweep dry run changes nothing', { s: (await bal('OLD1')) === 100 && /WOULD return 25 points from 3 members/.test(o) ? 200 : 500, t: o }, true);
  o = sweep({}, true);
  check('[owner] sweep takes 20% rounded down (100 -> 80)', { s: (await bal('OLD1')) === 80 ? 200 : 500, t: o }, true);
  check('[owner] sweep: 17 -> 14', { s: (await bal('OLD2')) === 14 ? 200 : 500, t: o }, true);
  check('[owner] sweep: brand-new member untouched (grace period)', { s: (await bal('NEW1')) === 13 ? 200 : 500, t: o }, true);
  check('[owner] sweep: 4 points is under 1 whole point, untouched', { s: (await bal('LOW1')) === 4 ? 200 : 500, t: o }, true);
  check('[owner] sweep: member with no join date is treated as long-standing (10 -> 8)', { s: (await bal('LEG1')) === 8 ? 200 : 500, t: o }, true);
  const pool = JSON.parse((await call('admin', 'GET', L + 'pool/total')).t);
  check('[owner] pool total equals what was taken (20+3+2 = 25)', { s: pool === 25 ? 200 : 500, t: String(pool) }, true);
  check('[owner] run summary was recorded', { s: JSON.parse((await call('admin', 'GET', L + 'decay_runs/2026-11/points')).t) === 25 ? 200 : 500, t: '' }, true);
  o = sweep({}, true);
  check('[owner] running it again the same month takes nothing more', { s: (await bal('OLD1')) === 80 && (await bal('OLD2')) === 14 ? 200 : 500, t: o }, true);
  await seed();
  await call('admin', 'PUT', S + 'decay/enabled', false);
  o = sweep({}, true);
  check('[owner] switched off in Settings: nothing is taken', { s: (await bal('OLD1')) === 100 ? 200 : 500, t: o }, true);

  // =====================================================================
  // 11. EVERYTHING ELSE BEHAVES EXACTLY AS BEFORE
  // =====================================================================
  await t('other apps: write a nested value (dashboard)', 'anon', 'PUT', '/dashboard/abc', { x: 1 }, true);
  await t('other apps: read (dashboard)', 'anon', 'GET', '/dashboard', undefined, true);
  await t('other apps: wipe a whole top-level node (already blocked today)', 'anon', 'DELETE', '/dashboard', undefined, false);
  await t('debug area for remote tasks still writable', 'anon', 'PUT', '/_debug/diag', 'hello', true);
  await t('lead form still writes', 'anon', 'POST', '/key_leads/leads', { source: 'x', email: 'a@example.com' }, true);
  await t('page-view tracker still writes (key without a period)', 'anon', 'POST', '/key_pageviews/hits/index_html', { t: 1 }, true);
  await t('pet game stays locked to anonymous visitors', 'anon', 'PUT', '/petgame/pets/p1', { name: 'x' }, false);
  await t('pet game stays locked even to the owner token (unchanged)', 'owner', 'PUT', '/petgame/pets/p1', { name: 'x' }, false);

  console.log('\n' + pass + ' passed, ' + fail + ' failed');
  process.exit(fail ? 1 : 0);
})().catch(e => { console.log('TEST HARNESS ERROR', e); process.exit(2); });
