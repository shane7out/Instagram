#!/bin/bash
# Run on the Mac. Installs the evidence-protection database rules for the
# points program (receipts, photos, redemptions, credit ledger, member
# balances) WITHOUT touching the rules for any of your other apps.
#
# Safety:
#  1. Downloads your CURRENT live rules and saves a copy on this Mac only
#     (~/lvr-rules-backups/) - the copy is never uploaded anywhere.
#  2. Replaces only these four sections: lvr_points, lvr_rewards,
#     lvr_instagram_index, lvr_coupons. Everything else is left exactly as is.
#  3. Reads the result back and runs live checks. If anything looks wrong it
#     puts your old rules back automatically.
#  4. To undo later by hand:  bash undo-rules.sh
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
node <<'NODE'
const { execSync } = require('child_process');
const fs = require('fs'), os = require('os'), path = require('path');
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const FRAG = 'https://raw.githubusercontent.com/shane7out/Instagram/claude/master-file-e6ofy0/.github/db-task/rules/lvr-rules-fragment.json';
const SECTIONS = ['lvr_points', 'lvr_rewards', 'lvr_instagram_index', 'lvr_coupons'];
const mask = s => String(s).replace(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g, '[EMAIL]');
const out = [];
const log = s => { const m = mask(s); out.push(m); console.log(m); };
let TOKEN = '';
try { TOKEN = execSync('gcloud auth print-access-token', { stdio: ['ignore', 'pipe', 'ignore'] }).toString().trim(); } catch (e) {}
const rulesUrl = () => `${DB}/.settings/rules.json?access_token=${encodeURIComponent(TOKEN)}`;
const put = body => fetch(rulesUrl(), { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body });
async function report() {
  try { await fetch(`${DB}/_debug/rulesdeploy.json`, { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(out.join('\n').slice(0, 6000)) }); console.log('\nSENT result - tell Claude it is done'); } catch (e) {}
}
async function status(label, url, opts) {
  try { const r = await fetch(url, opts); return r.status; } catch (e) { return 'err'; }
}
(async () => {
  if (!TOKEN) { log('No gcloud login found - nothing changed.'); return report(); }
  // 1. current rules + local backup
  const r0 = await fetch(rulesUrl());
  const liveText = await r0.text();
  let live;
  try { live = JSON.parse(liveText); } catch (e) { log('Could not read current rules as plain JSON - nothing changed.'); return report(); }
  if (!live.rules) { log('Unexpected rules format - nothing changed.'); return report(); }
  const dir = path.join(os.homedir(), 'lvr-rules-backups'); fs.mkdirSync(dir, { recursive: true });
  const stamp = new Date().toISOString().replace(/[:.]/g, '-');
  const backup = path.join(dir, `rules-before-${stamp}.json`);
  fs.writeFileSync(backup, liveText);
  fs.writeFileSync(path.join(dir, 'LATEST-BEFORE.json'), liveText);
  log(`Saved a copy of your current rules on this Mac: ${backup}`);
  log(`Current rules sections: ${Object.keys(live.rules).length}`);
  // 2. merge
  const fragText = await (await fetch(FRAG)).text();
  let frag; try { frag = JSON.parse(fragText); } catch (e) { log('Could not read the new rules file - nothing changed.'); return report(); }
  for (const k of SECTIONS) if (!frag[k]) { log('New rules file is missing section ' + k + ' - nothing changed.'); return report(); }
  const merged = JSON.parse(liveText);
  for (const k of SECTIONS) merged.rules[k] = frag[k];
  const before = Object.keys(live.rules).filter(k => !SECTIONS.includes(k)).sort().join(',');
  const after = Object.keys(merged.rules).filter(k => !SECTIONS.includes(k)).sort().join(',');
  if (before !== after) { log('Safety check failed (other sections changed) - nothing changed.'); return report(); }
  // 3. deploy
  const pr = await put(JSON.stringify(merged));
  const pt = await pr.text();
  log('Upload of new rules -> HTTP ' + pr.status + (pr.status === 200 ? '' : ' ' + pt.slice(0, 300)));
  if (pr.status !== 200) { log('Rules were rejected by Firebase, so your old rules are still in place.'); return report(); }
  // 4. verify
  const back = await (await fetch(rulesUrl())).json();
  let ok = true;
  for (const k of SECTIONS) if (JSON.stringify(back.rules[k]) !== JSON.stringify(frag[k])) { ok = false; log('Readback mismatch in ' + k); }
  const probes = [
    ['members readable', await status('', `${DB}/lvr_rewards.json?shallow=true`), 200],
    ['receipts readable', await status('', `${DB}/lvr_points/receipts.json?shallow=true`), 200],
    ['catalog readable', await status('', `${DB}/lvr_points/catalog.json?shallow=true`), 200],
    ['other app (key_leads) readable', await status('', `${DB}/key_leads/leads.json?shallow=true`), 200],
    // deletes of a key that does not exist: harmless either way, but the new rules answer 'denied'
    ['deleting a receipt is blocked', await status('', `${DB}/lvr_points/receipts/zz_probe_none.json`, { method: 'DELETE' }), 401],
    ['deleting a receipt photo is blocked', await status('', `${DB}/lvr_points/receipt_photos/zz_probe_none.json`, { method: 'DELETE' }), 401],
  ];
  for (const [name, got, want] of probes) {
    const good = got === want || (want === 401 && got === 403);
    if (!good) ok = false;
    log((good ? 'OK   ' : 'FAIL ') + name + ' (HTTP ' + got + ')');
  }
  if (!ok) {
    const rb = await put(liveText);
    log('A check failed - PUT your old rules back automatically -> HTTP ' + rb.status);
    return report();
  }
  log('ALL CHECKS PASSED. New rules are live. To undo: bash undo-rules.sh');
  await report();
})();
NODE
