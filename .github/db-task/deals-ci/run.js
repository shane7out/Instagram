// Entry point for the no-Mac Deals pipeline. MODE controls how far it goes:
//   auth-test  - just prove the service-account token exchange + a read-only
//                Firebase Hosting API call work. Touches nothing live.
//   dry-run    - full harvest + gen.js build, but does NOT deploy. Writes the
//                generated cars.json/index.html to the workflow log for review.
//   deploy     - full harvest + gen.js build + real deploy to the live site.
'use strict';
const { getAccessToken } = require('./lib/sa-token.js');

const MODE = process.env.MODE || 'auth-test';
const SITE = 'classiccarsforsale-co';
const QUOTA_PROJECT = 'classiccarsforsale-co';

async function authTest() {
  const saJson = process.env.FIREBASE_DEALS_SA;
  if (!saJson) { console.log('FATAL: FIREBASE_DEALS_SA secret is not set'); process.exit(1); }
  console.log('got FIREBASE_DEALS_SA secret, length=' + saJson.length);
  let sa;
  try { sa = JSON.parse(saJson); } catch (e) { console.log('FATAL: FIREBASE_DEALS_SA is not valid JSON: ' + e.message); process.exit(1); }
  console.log('service account client_email: ' + sa.client_email);
  console.log('project_id: ' + sa.project_id);

  const token = await getAccessToken(saJson);
  console.log('got access token, length=' + token.length + ', prefix=' + token.slice(0, 12) + '...');

  // Read-only sanity call: list the existing Hosting releases for the site.
  // Touches nothing, just proves the token actually has permission on this project.
  const https = require('https');
  const url = `https://firebasehosting.googleapis.com/v1beta1/sites/${SITE}/releases?pageSize=1`;
  const body = await new Promise((resolve, reject) => {
    https.get(url, { headers: { Authorization: 'Bearer ' + token, 'x-goog-user-project': QUOTA_PROJECT } }, (r) => {
      let d = ''; r.on('data', (c) => (d += c)); r.on('end', () => resolve({ status: r.statusCode, body: d }));
    }).on('error', reject);
  });
  console.log('releases API status: ' + body.status);
  console.log(body.body.slice(0, 500));
  if (body.status !== 200) { console.log('FATAL: token does not have working Hosting permissions on this project'); process.exit(1); }
  console.log('AUTH TEST PASSED — service account token works for Firebase Hosting on ' + SITE);
}

(async () => {
  if (MODE === 'auth-test') { await authTest(); return; }
  console.log('MODE=' + MODE + ' not implemented yet — stopping after auth-test equivalent checks.');
  await authTest();
})().catch((e) => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
