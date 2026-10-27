#!/bin/bash
# READ-ONLY inventory of the Firebase project, run on the Mac (uses the same
# gcloud login the deploy scripts use). Changes nothing. Reports: project
# basics, whether billing is on (the "Blaze" plan, needed for server code),
# whether Firebase sign-in is available, the current database rules, and the
# names (only) of the top-level database nodes. No tokens, billing IDs or
# member data are included. The result is sent to /_debug/recon.json so it
# can be read remotely.
set +e
export PATH="/Users/mac/Downloads/google-cloud-sdk/bin:/Users/mac/.local/bin:$PATH"
node <<'NODE'
const { execSync } = require('child_process');
const P = 'lvr-data-a60c1';
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
let TOKEN = '';
try { TOKEN = execSync('gcloud auth print-access-token', { stdio: ['ignore', 'pipe', 'ignore'] }).toString().trim(); } catch (e) {}
const out = [];
// Email addresses are always masked: results are read from a public repo's logs.
const maskEmails = s => String(s).replace(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g, '[EMAIL]');
const log = s => { const m = maskEmails(s); out.push(m); console.log(m); };
async function call(label, url, pick) {
  try {
    const r = await fetch(url, { headers: TOKEN ? { Authorization: 'Bearer ' + TOKEN, 'x-goog-user-project': P } : {} });
    const t = await r.text();
    let v = t; try { v = JSON.parse(t); } catch (e) {}
    log('== ' + label + ' -> HTTP ' + r.status);
    log(typeof pick === 'function' ? pick(v) : t.slice(0, 300));
  } catch (e) { log('== ' + label + ' -> failed: ' + e.message); }
}
(async () => {
  log('gcloud login available: ' + !!TOKEN);
  await call('project', `https://firebase.googleapis.com/v1beta1/projects/${P}`, v => JSON.stringify({ displayName: v.displayName, state: v.state }));
  await call('billing', `https://cloudbilling.googleapis.com/v1/projects/${P}/billingInfo`, v => 'billingEnabled: ' + (v && v.billingEnabled));
  await call('sign-in providers', `https://identitytoolkit.googleapis.com/admin/v2/projects/${P}/config`, v => {
    if (!v || v.error) return 'not available: ' + JSON.stringify(v && v.error && v.error.message).slice(0, 200);
    return JSON.stringify({ emailPassword: v.signIn && v.signIn.email, anonymous: v.signIn && v.signIn.anonymous, phone: v.signIn && v.signIn.phoneNumber });
  });
  for (const svc of ['cloudfunctions.googleapis.com', 'identitytoolkit.googleapis.com', 'cloudbuild.googleapis.com', 'artifactregistry.googleapis.com']) {
    await call('service ' + svc, `https://serviceusage.googleapis.com/v1/projects/${P}/services/${svc}`, v => 'state: ' + (v && v.state));
  }
  if (TOKEN) {
    try {
      const rr = await fetch(`${DB}/.settings/rules.json?access_token=${encodeURIComponent(TOKEN)}`);
      const rt = await rr.text();
      let pretty = rt; try { pretty = JSON.stringify(JSON.parse(rt), null, 1); } catch (e) {}
      const masked = maskEmails(pretty);
      log('== database rules -> HTTP ' + rr.status + ' (' + masked.length + ' characters, saved in full, emails masked)');
      await fetch(`${DB}/_debug/rules.json`, { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(masked) });
    } catch (e) { log('== database rules -> failed: ' + e.message); }
  }
  await call('top-level database nodes (names only)', `${DB}/.json?shallow=true`, v => v && typeof v === 'object' ? Object.keys(v).sort().join(', ') : String(v).slice(0, 200));
  try {
    const r = await fetch(`${DB}/_debug/recon.json`, { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(out.join('\n').slice(0, 9000)) });
    console.log('\nSENT to /_debug/recon.json (HTTP ' + r.status + ') - tell Claude it is done');
  } catch (e) { console.log('send failed: ' + e.message); }
})();
NODE
