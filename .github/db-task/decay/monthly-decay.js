// Monthly "community fund" return: on the 1st of each month, a set percentage
// of every member's unused points goes back to the community pool.
// Safe to run more than once in a month: each member's return is claimed with a
// create-only record first, so nobody is ever charged twice for the same month.
// Never prints names, emails or tokens. Only counts and totals.
const DB = process.env.DB_URL || 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const NS = process.env.DB_NS ? '&ns=' + process.env.DB_NS : '';
const DRY = process.env.DRY_RUN === '1';
const FORCE = process.env.FORCE === '1';
const DAY = 86400000;

async function call(method, path, body, q) {
  const r = await fetch(DB + path + '.json?' + (q || 'print=silent') + NS, {
    method, headers: { 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body)
  });
  return r;
}
async function get(path) { const r = await call('GET', path, undefined, 'x=1'); if (!r.ok) throw new Error('read failed ' + path + ' ' + r.status); return r.json(); }

function laNow() {
  const parts = new Intl.DateTimeFormat('en-US', { timeZone: 'America/Los_Angeles', year: 'numeric', month: '2-digit', day: '2-digit' }).formatToParts(new Date());
  const g = t => parts.find(p => p.type === t).value;
  return { key: g('year') + '-' + g('month'), day: parseInt(g('day'), 10) };
}

(async () => {
  const now = laNow();
  const run = process.env.RUN_KEY || now.key;
  const cfg = Object.assign({ enabled: false, percent: 20, graceDays: 30 }, await get('/lvr_points/settings/decay') || {});
  console.log('run month ' + run + (DRY ? ' (DRY RUN: nothing is changed)' : ''));
  if (cfg.enabled !== true) { console.log('Monthly return is switched off in Settings. Nothing to do.'); return; }
  if (!FORCE && !process.env.RUN_KEY && now.day > 3) { console.log('Today is not the 1st-3rd of the month. Nothing to do.'); return; }
  const pct = Math.max(1, Math.min(50, Number(cfg.percent) || 20));
  const grace = Math.max(0, Math.min(365, Number(cfg.graceDays)));
  console.log('rate ' + pct + '%, first return only after ' + grace + ' days of membership');

  const members = await get('/lvr_rewards') || {};
  let eligible = 0, taken = 0, pointsTotal = 0, tooNew = 0, already = 0, failed = 0;
  for (const mk of Object.keys(members)) {
    const m = members[mk] || {};
    const pts = Number(m.points) || 0;
    if (pts < 1) continue;
    // Accounts without a join date (the very first testers) count as long-standing.
    if (m.joinedAt && Date.now() - m.joinedAt < grace * DAY) { tooNew++; continue; }
    const take = Math.floor(pts * pct / 100);
    if (take < 1) continue;
    eligible++;
    if (DRY) { taken++; pointsTotal += take; continue; }
    const enc = encodeURIComponent(mk);
    const claim = await call('PUT', '/lvr_points/decay_by_member/' + enc + '/' + run,
      { amount: take, before: pts, after: pts - take, percent: pct, at: { '.sv': 'timestamp' } });
    if (!claim.ok) { already++; continue; }            // already returned this month
    const dec = await call('PUT', '/lvr_rewards/' + enc + '/points', { '.sv': { increment: -take } });
    if (!dec.ok) { failed++; continue; }
    await call('PUT', '/lvr_points/pool/total', { '.sv': { increment: take } });
    taken++; pointsTotal += take;
  }
  console.log('members with a balance and past the grace period: ' + eligible);
  console.log('too new (grace period): ' + tooNew + ', already done this month: ' + already + ', failed: ' + failed);
  console.log((DRY ? 'WOULD return ' : 'Returned ') + pointsTotal + ' points from ' + taken + ' members to the community fund.');
  if (!DRY && failed === 0) {
    await call('PUT', '/lvr_points/decay_runs/' + run, { members: taken, points: pointsTotal, percent: pct, at: { '.sv': 'timestamp' } });
  }
  if (failed) process.exitCode = 1;
})().catch(e => { console.log('ERROR: ' + e.message); process.exit(1); });
