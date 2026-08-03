// Deploy The Private Table to Firebase Hosting via REST (serial upload).
// The firebase CLI is not used on this machine - its parallel uploader drops
// connections. This mirrors the REST-overlay approach the other sites use.
// Run from the folder containing index.html:  node deploy.js

const { execSync } = require('child_process');
const fs = require('fs');
const zlib = require('zlib');
const crypto = require('crypto');

const PROJECT = 'lvr-data-a60c1';
const SITE = 'private-table-lv';
const API = 'https://firebasehosting.googleapis.com/v1beta1';

const token = execSync('gcloud auth print-access-token').toString().trim();

async function api(method, url, body, raw) {
  const headers = { Authorization: 'Bearer ' + token, 'x-goog-user-project': PROJECT };
  if (!raw) headers['Content-Type'] = 'application/json';
  else headers['Content-Type'] = 'application/octet-stream';
  const r = await fetch(url, {
    method,
    headers,
    body: raw ? body : (body ? JSON.stringify(body) : undefined),
  });
  const text = await r.text();
  let json; try { json = JSON.parse(text); } catch (e) { json = { raw: text }; }
  return { status: r.status, json };
}

(async () => {
  // 1) create the hosting site (409 = already exists, fine)
  let r = await api('POST', API + '/projects/' + PROJECT + '/sites?siteId=' + SITE);
  if (r.status === 200) console.log('site created: ' + SITE);
  else if (r.status === 409) console.log('site exists: ' + SITE);
  else { console.log('SITE CREATE FAILED ' + r.status + ': ' + JSON.stringify(r.json).slice(0, 300)); process.exit(1); }

  // 2) new version
  r = await api('POST', API + '/sites/' + SITE + '/versions', {});
  if (!r.json.name) { console.log('VERSION FAILED: ' + JSON.stringify(r.json).slice(0, 300)); process.exit(1); }
  const version = r.json.name;
  console.log('version: ' + version);

  // 3) hash the gzipped file
  const gz = zlib.gzipSync(fs.readFileSync('index.html'));
  const hash = crypto.createHash('sha256').update(gz).digest('hex');

  // 4) declare the manifest
  r = await api('POST', API + '/' + version + ':populateFiles', { files: { '/index.html': hash } });
  if (r.status !== 200) { console.log('POPULATE FAILED: ' + JSON.stringify(r.json).slice(0, 300)); process.exit(1); }

  // 5) upload if required
  const need = r.json.uploadRequiredHashes || [];
  if (need.indexOf(hash) !== -1) {
    const up = await api('POST', r.json.uploadUrl + '/' + hash, gz, true);
    if (up.status !== 200) { console.log('UPLOAD FAILED ' + up.status); process.exit(1); }
    console.log('  uploaded index.html');
  } else console.log('  content already on server');

  // 6) finalize + 7) release
  r = await api('PATCH', API + '/' + version + '?update_mask=status', { status: 'FINALIZED' });
  if (r.status !== 200) { console.log('FINALIZE FAILED: ' + JSON.stringify(r.json).slice(0, 300)); process.exit(1); }
  r = await api('POST', API + '/sites/' + SITE + '/releases?versionName=' + version);
  if (r.status !== 200) { console.log('RELEASE FAILED: ' + JSON.stringify(r.json).slice(0, 300)); process.exit(1); }

  console.log('RELEASED ✅ https://' + SITE + '.web.app');
})();
