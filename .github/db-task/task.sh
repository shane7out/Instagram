#!/bin/bash
# Reconcile the two rewards/points systems per Shane's direction ("the
# reward system and point system are the same thing"): /lvr_rewards is the
# canonical member store going forward (8 real members, real points). This
# backfills a personal-link `token` on every existing member (none have one
# today - the admin CRM only ever looked members up by search, never by a
# shareable link) and pulls the live lvr-rewards.html signup page's FULL
# source into the repo so it can be edited here (it currently only exists
# on the live Firebase Hosting bucket, not tracked anywhere).
set -e
node <<'NODE'
const https = require('https');
function req(method, url, body) {
  return new Promise((resolve) => {
    const u = new URL(url);
    const data = body ? JSON.stringify(body) : undefined;
    const opts = { method, headers: data ? {'Content-Type':'application/json','Content-Length':Buffer.byteLength(data)} : {} };
    const r = https.request(u, opts, (res) => {
      let d = ''; res.on('data', c => d += c); res.on('end', () => resolve({ status: res.statusCode, body: d }));
    });
    r.on('error', e => resolve({ error: e.message }));
    if (data) r.write(data);
    r.end();
  });
}

function randToken() {
  return require('crypto').randomBytes(16).toString('hex');
}

(async () => {
  console.log('=== fetch /lvr_rewards ===');
  const cur = await req('GET', 'https://lvr-data-a60c1-default-rtdb.firebaseio.com/lvr_rewards.json');
  if (cur.status !== 200) { console.log('FAILED to fetch lvr_rewards:', cur.status, cur.error); process.exit(1); }
  const members = JSON.parse(cur.body) || {};
  const keys = Object.keys(members);
  console.log('members found:', keys.length);

  console.log('\n=== backfilling token field where missing ===');
  for (const key of keys) {
    const m = members[key];
    if (m.token) { console.log(key, '(' + m.name + ')', 'already has a token — skipping'); continue; }
    const token = randToken();
    const r = await req('PATCH', 'https://lvr-data-a60c1-default-rtdb.firebaseio.com/lvr_rewards/' + encodeURIComponent(key) + '.json', { token: token });
    console.log(key, '(' + m.name + ')', '-> token ' + token, 'status', r.status);
  }

  console.log('\n=== verify ===');
  const after = await req('GET', 'https://lvr-data-a60c1-default-rtdb.firebaseio.com/lvr_rewards.json');
  const amembers = JSON.parse(after.body) || {};
  Object.keys(amembers).forEach(k => {
    console.log(k, amembers[k].name, '- has token:', !!amembers[k].token);
  });
})();
NODE

echo ""
echo "=== fetching full lvr-rewards.html source into the repo ==="
mkdir -p .github/db-task/mac
curl -sL -o .github/db-task/mac/lvr-rewards.html https://lvr-data-a60c1.web.app/lvr-rewards.html
echo "saved: $(wc -c < .github/db-task/mac/lvr-rewards.html) bytes"

git config user.name "claude-remote-hands"
git config user.email "noreply@anthropic.com"
git add .github/db-task/mac/lvr-rewards.html
if git diff --cached --quiet; then
  echo "no changes to commit (file already matches)"
else
  git commit -m "Pull live lvr-rewards.html source into the repo for editing

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01C24s48QBeAMLS2iDpVHsTf"
  git push origin HEAD:claude/master-file-e6ofy0
  echo "pushed"
fi
