/*
STAGED DASHBOARD OWNER LOCK - tests for dashboard-lock-rules.json (NOT DEPLOYED).
Run: bash .github/db-task/rules/run-dashboard-lock-test.sh   (Firebase emulator, nothing live is touched)
What it proves
  - the restaurant CRM nodes (dashboard*, company_dashboard, customrecords, staging_*, records) can be read and written ONLY by the owner;
    a stranger with no sign-in and a signed-in non-owner are both refused;
  - the old "never wipe a whole node / never drop customrecords" guards still apply, even to the owner;
  - everything the lock does NOT cover behaves exactly as before: friend / helper variants, the private chef form, the
    _debug area, the Deals site nodes, lead form, page-view tracker.
*/
const NS = 'demo-lvr-default-rtdb';
const BASE = 'http://127.0.0.1:9000';
const b64u = o => Buffer.from(JSON.stringify(o)).toString('base64url');
const jwt = uid => b64u({ alg: 'none', typ: 'JWT' }) + '.' + b64u({ uid: uid, user_id: uid, sub: uid, iat: Math.floor(Date.now() / 1000) }) + '.';
const OWNER_JWT = jwt('TESTOWNER'), OTHER_JWT = jwt('SOMEONE-ELSE');
async function call(who, method, p, body) {
  const auth = who === 'owner' ? '&auth=' + OWNER_JWT : who === 'other' ? '&auth=' + OTHER_JWT : '';
  const r = await fetch(`${BASE}${p}.json?ns=${NS}${auth}`, {
    method, headers: Object.assign({ 'Content-Type': 'application/json' }, who === 'admin' ? { Authorization: 'Bearer owner' } : {}),
    body: body === undefined ? undefined : JSON.stringify(body) });
  return { s: r.status, t: await r.text() };
}
let pass = 0, fail = 0;
function check(name, res, shouldAllow) {
  const allowed = res.s === 200, ok = allowed === shouldAllow; ok ? pass++ : fail++;
  console.log((ok ? 'PASS' : 'FAIL') + '  ' + name + '  [' + (allowed ? 'allowed' : 'denied') + (ok ? '' : ', expected ' + (shouldAllow ? 'allowed' : 'denied') + ' - HTTP ' + res.s + ' ' + res.t.slice(0, 80)) + ']');
}
const t = async (name, who, method, p, body, allow) => check('[' + who + '] ' + name, await call(who, method, p, body), allow);

(async () => {
  const LOCKED = ['dashboard', 'dashboard_crec', 'dashboard_adv_crec', 'dashboard_adv_stg_crec', 'dashboard_deleted', 'dashboard_golf_crec',
    'dashboard_mdl_crec', 'dashboard_infl_crec', 'dashboard_exp_crec', 'dashboard_rest_stg_crec', 'dashboard_advertisers', 'dashboard_backup',
    'dashboard_igovr', 'dashboard_badig', 'dashboard_customrecords', 'company_dashboard', 'customrecords', 'staging_approved',
    'staging_added', 'staging_queue', 'records'];
  for (const n of LOCKED) {
    await call('admin', 'PUT', '/' + n + '/seed', { name: 'Seed Cafe', email: 'x@example.com', phone: '555' });
    await t('read ' + n, 'anon', 'GET', '/' + n, undefined, false);
    await t('read ' + n, 'other', 'GET', '/' + n + '/seed', undefined, false);
    await t('read ' + n, 'owner', 'GET', '/' + n, undefined, true);
    await t('write ' + n, 'anon', 'PUT', '/' + n + '/new1', { name: 'Evil' }, false);
    await t('write ' + n, 'other', 'PATCH', '/' + n + '/seed', { name: 'Evil' }, false);
    await t('overwrite existing row ' + n, 'anon', 'PUT', '/' + n + '/seed', { name: 'Evil' }, false);
    await t('delete row ' + n, 'anon', 'DELETE', '/' + n + '/seed', undefined, false);
    await t('write ' + n, 'owner', 'PUT', '/' + n + '/new1', { name: 'Real Cafe' }, true);
    await t('update ' + n, 'owner', 'PATCH', '/' + n + '/seed', { name: 'Seed Cafe 2' }, true);
    await t('delete row ' + n, 'owner', 'DELETE', '/' + n + '/new1', undefined, true);
  }
  // the old data-loss guards still apply to the owner
  await call('admin', 'PUT', '/dashboard', { customrecords: { a: 1 }, other: { b: 2 } });
  await t('owner cannot wipe a whole top-level node', 'owner', 'DELETE', '/dashboard', undefined, false);
  await t('owner cannot replace a node and drop customrecords', 'owner', 'PUT', '/dashboard', { other: { b: 3 } }, false);
  await t('owner can replace a node that keeps customrecords', 'owner', 'PUT', '/dashboard', { customrecords: { a: 2 }, other: { b: 3 } }, true);

  // NOT covered by the lock: behaves as before (open) - listed on purpose so a later change is a conscious one
  const OPEN = ['dashboard_cc', 'dashboard_friend', 'dashboard_advertisers_friend', 'dashboard_advertisers_friend_backup', 'guest10_dm', 'coeditor_dm', 'coeditor_infl_dm',
    'coeditor_adv_dm', 'lvr_staff_apps', 'lvr_rewards_friend', 'chef_bookings', '_debug', '_deals', 'classiccars_favs', 'classiccars_stats', 'als_favs', 'als_hidden'];
  for (const n of OPEN) {
    await t('still open (not locked): write ' + n, 'anon', 'PUT', '/' + n + '/k1', { v: 1 }, true);
    await t('still open (not locked): read ' + n, 'anon', 'GET', '/' + n + '/k1', undefined, true);
  }
  await t('names that only look similar are not locked (Dashboard_x, my_records)', 'anon', 'PUT', '/my_records/k1', { v: 1 }, true);
  await t('lead form still writes', 'anon', 'POST', '/key_leads/leads', { source: 'x', email: 'a@example.com' }, true);
  await t('page-view tracker still writes', 'anon', 'POST', '/key_pageviews/hits/index_html', { t: 1 }, true);
  console.log('\n' + pass + ' passed, ' + fail + ' failed');
  process.exit(fail ? 1 : 0);
})();
