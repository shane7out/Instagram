// Overlay a set of files onto the live lvr-data-a60c1 hosting version,
// keeping every other live file's hash exactly as-is (same method as the
// proven spark-dating deployer). Used because ~/Downloads/lv-repo-new is
// TCC-blocked.
//
// FIX (2026-10-27): this originally only ever overlaid index.html +
// version.json - hardcoded, no matter what else was sitting in the
// directory. Every standalone tool (key-room.html, lvr-points-admin.html,
// etc.) was being downloaded + syntax-checked by its own deploy script but
// NEVER actually uploaded here, so they all 404'd live despite every
// deploy script reporting success. Now reads an optional OVERLAY_FILES env
// var (space-separated filenames in this same directory) and overlays
// those too, in addition to index.html + version.json. With no
// OVERLAY_FILES set, behavior is identical to before.
const fs = require('fs'), zlib = require('zlib'), crypto = require('crypto'), https = require('https');
const { execSync } = require('child_process');
const SITE = 'lvr-data-a60c1';
const DIR = '/Users/mac/lv-dash-work';
const TOKEN = execSync('gcloud auth print-access-token').toString().trim();
const H = { Authorization: 'Bearer ' + TOKEN, 'x-goog-user-project': SITE };

function req(method, url, headers, body) {
  return new Promise((res, rej) => {
    const u = new URL(url);
    const r = https.request({ method, hostname: u.hostname, path: u.pathname + u.search, headers: Object.assign({}, H, headers) }, resp => {
      const d = []; resp.on('data', c => d.push(c)); resp.on('end', () => {
        const buf = Buffer.concat(d);
        if (resp.statusCode >= 200 && resp.statusCode < 300) res({ status: resp.statusCode, body: buf });
        else rej(new Error(method + ' ' + url + ' -> ' + resp.statusCode + ' ' + buf.toString().slice(0, 250)));
      });
    });
    r.on('error', rej); r.setTimeout(120000, () => r.destroy(new Error('timeout')));
    if (body) r.write(body); r.end();
  });
}
async function reqR(m, u, h, b, t) { t = t || 5; for (let a = 0; a < t; a++) { try { return await req(m, u, h, b); } catch (e) { if (a === t - 1) throw e; console.error('  retry ' + (a + 1)); await new Promise(r => setTimeout(r, 2000 * (a + 1))); } } }

(async () => {
  const rel = await reqR('GET', `https://firebasehosting.googleapis.com/v1beta1/sites/${SITE}/releases?pageSize=1`);
  const release = (JSON.parse(rel.body).releases || [])[0];
  if (!release) throw new Error('no live release');
  const liveVersion = release.version.name;
  console.error('live version: ' + liveVersion);
  const vd = await reqR('GET', `https://firebasehosting.googleapis.com/v1beta1/${liveVersion}`);
  const liveConfig = JSON.parse(vd.body).config || {};
  const map = {};
  let pageToken = '';
  do {
    const fl = await reqR('GET', `https://firebasehosting.googleapis.com/v1beta1/${liveVersion}/files?pageSize=1000${pageToken ? '&pageToken=' + encodeURIComponent(pageToken) : ''}`);
    const j = JSON.parse(fl.body);
    (j.files || []).forEach(f => { map[f.path] = f.hash; });
    pageToken = j.nextPageToken || '';
  } while (pageToken);
  console.error('live manifest: ' + Object.keys(map).length + ' files');

  const BASE_FILES = ['index.html', 'version.json'];
  const EXTRA_FILES = (process.env.OVERLAY_FILES || '').split(/\s+/).filter(Boolean);
  const ALL_FILES = BASE_FILES.concat(EXTRA_FILES.filter(f => BASE_FILES.indexOf(f) === -1));

  const byHash = {}; // hash -> { buf, name }
  ALL_FILES.forEach(name => {
    const p = DIR + '/' + name;
    if (!fs.existsSync(p)) { console.error('SKIP (not found on disk): ' + name); return; }
    const gz = zlib.gzipSync(fs.readFileSync(p), { level: 9 });
    const h = crypto.createHash('sha256').update(gz).digest('hex');
    map['/' + name] = h;
    byHash[h] = { buf: gz, name };
  });
  console.error('overlaying ' + Object.keys(byHash).length + ' file(s): ' + ALL_FILES.join(', '));

  const cv = await reqR('POST', `https://firebasehosting.googleapis.com/v1beta1/sites/${SITE}/versions`, { 'Content-Type': 'application/json' }, JSON.stringify({ config: liveConfig }));
  const version = JSON.parse(cv.body).name;
  console.error('new version: ' + version);
  const entries = Object.entries(map);
  let uploadUrl = null; const need = new Set();
  for (let i = 0; i < entries.length; i += 1000) {
    const filesObj = {}; entries.slice(i, i + 1000).forEach(([p, h]) => filesObj[p] = h);
    const pf = await reqR('POST', `https://firebasehosting.googleapis.com/v1beta1/${version}:populateFiles`, { 'Content-Type': 'application/json' }, JSON.stringify({ files: filesObj }));
    const j = JSON.parse(pf.body);
    if (j.uploadUrl) uploadUrl = j.uploadUrl;
    (j.uploadRequiredHashes || []).forEach(h => need.add(h));
  }
  console.error('to upload: ' + need.size);
  for (const h of need) {
    const entry = byHash[h];
    if (!entry) { console.error('UNEXPECTED required hash ' + h.slice(0, 12)); process.exit(1); }
    await reqR('POST', uploadUrl + '/' + h, { 'Content-Type': 'application/octet-stream' }, entry.buf);
    console.error('  uploaded ' + entry.name);
  }
  await reqR('PATCH', `https://firebasehosting.googleapis.com/v1beta1/${version}?update_mask=status`, { 'Content-Type': 'application/json' }, JSON.stringify({ status: 'FINALIZED' }));
  await reqR('POST', `https://firebasehosting.googleapis.com/v1beta1/sites/${SITE}/releases?versionName=${version}`, { 'Content-Type': 'application/json' }, '{}');
  console.error('RELEASED ✅');
})().catch(e => { console.error('ERROR: ' + e.message); process.exit(1); });
