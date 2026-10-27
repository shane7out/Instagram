#!/bin/bash
# Live-verify keytechnologies.si picked up today's push (my-account.html,
# rewards.html pointing at /lvr_rewards instead of /lvr_points/wallets).
set -e
node <<'NODE'
const https = require('https');
function get(url) {
  return new Promise((resolve) => {
    https.get(url, { timeout: 15000 }, r => {
      let d = ''; r.on('data', c => d += c); r.on('end', () => resolve({ status: r.statusCode, body: d }));
    }).on('error', e => resolve({ error: e.message }));
  });
}
(async () => {
  const acct = await get('https://keytechnologies.si/my-account.html');
  console.log('my-account.html: status', acct.status, '| has /lvr_rewards ref:', (acct.body||'').indexOf('/lvr_rewards') !== -1, '| has fbFindByToken:', (acct.body||'').indexOf('fbFindByToken') !== -1);

  const rwd = await get('https://keytechnologies.si/rewards.html');
  console.log('rewards.html: status', rwd.status, '| posts to /lvr_rewards:', (rwd.body||'').indexOf('LVR_REWARDS_DB_URL') !== -1, '| old wallets ref gone:', (rwd.body||'').indexOf('lvr_points/wallets') === -1);
})();
NODE
