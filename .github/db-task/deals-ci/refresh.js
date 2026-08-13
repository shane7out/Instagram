// Laptop-free Deals refresh — runs in GitHub Actions.
//  1. Reads the RTDB flag the site's round button sets (or runs if data is stale / FORCE=1)
//  2. Fetches the live site, checks every Craigslist listing, drops dead ones
//  3. Rewrites the date line ("Aug 13, 4:05 PM" — no "Updated" word) and injects the
//     inline round refresh button right after the time
//  4. Redeploys index.html to Firebase Hosting using the FIREBASE_SA_KEY repo secret
//     (all other files are carried over server-side by hash — nothing else re-uploads)
//  5. Stamps _deals/updated so the page (and the pressed button) knows it finished
// No npm dependencies. Node 18+.
'use strict';
const crypto = require('crypto');
const zlib = require('zlib');

const DBROOT = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const SITE = 'classiccarsforsale-co';
const API = 'https://firebasehosting.googleapis.com/v1beta1';
const PROJECT = 'lvr-data-a60c1';
const LIVE = 'https://classiccarsforsale-co.web.app';
const STALE_MS = 3 * 3600 * 1000; // auto-refresh if data older than 3h

async function jf(url, opt) {
  const r = await fetch(url, opt);
  const t = await r.text();
  let d; try { d = JSON.parse(t); } catch (e) { d = { raw: t }; }
  return { status: r.status, json: d, text: t };
}

function nowLA() {
  return new Date().toLocaleString('en-US', {
    timeZone: 'America/Los_Angeles', month: 'short', day: 'numeric',
    hour: 'numeric', minute: '2-digit',
  });
}

// ---------- the page-side block (inline round button after the time) ----------
const MARK = 'DEALS-REFRESH-v2';
const PAGE_CSS = `<style>/*${MARK}*/`
  + `#lastupd{font-size:clamp(17px,4vw,24px)!important;font-weight:800!important;line-height:1.25!important;color:#0d47a1!important;display:flex;align-items:center;gap:8px}`
  + `#refreshbtn{display:inline-flex;align-items:center;justify-content:center;width:34px;height:34px;border-radius:50%;`
  + `border:2px solid #0d47a1;background:#fff;color:#0d47a1;font-size:18px;font-weight:800;cursor:pointer;padding:0;line-height:1;flex:none}`
  + `#refreshbtn.busy{animation:spinbtn 1s linear infinite;opacity:.75}`
  + `@keyframes spinbtn{to{transform:rotate(360deg)}}`
  + `</style>`;
const PAGE_JS = `<script>/*${MARK}*/\n`
  + `(function(){\n`
  + `var DB='${DBROOT}/_deals';\n`
  + `var lu=document.getElementById('lastupd');if(!lu)return;\n`
  + `var btn=document.createElement('button');btn.id='refreshbtn';btn.title='Refresh listings';\n`
  + `btn.setAttribute('aria-label','Refresh listings');btn.innerHTML='\\u27F3';\n`
  + `lu.appendChild(btn);\n`
  + `function setTxt(t){lu.childNodes[0].nodeValue=t;}\n`
  + `if(lu.childNodes[0].nodeType!==3){lu.insertBefore(document.createTextNode(''),lu.firstChild);}\n`
  + `function fmt(ts){var d=new Date(ts);return d.toLocaleDateString('en-US',{month:'short',day:'numeric'})+', '+d.toLocaleTimeString('en-US',{hour:'numeric',minute:'2-digit'});}\n`
  + `var base=null;\n`
  + `fetch(DB+'/updated.json').then(function(r){return r.json();}).then(function(ts){if(ts){base=ts;setTxt(fmt(ts)+' ');}}).catch(function(){});\n`
  + `btn.onclick=function(){\n`
  + ` if(btn.classList.contains('busy'))return;\n`
  + ` btn.classList.add('busy');\n`
  + ` setTxt('Refreshing\\u2026 (up to ~20 min) ');\n`
  + ` fetch(DB+'/refresh_request.json',{method:'PUT',body:JSON.stringify(Date.now())}).then(function(){\n`
  + `  var n=0;var iv=setInterval(function(){n++;\n`
  + `   fetch(DB+'/updated.json').then(function(r){return r.json();}).then(function(ts){\n`
  + `    if(ts&&base&&ts>base){clearInterval(iv);location.replace('/?r='+Date.now());}\n`
  + `    else if(ts&&!base){base=ts;}\n`
  + `    else if(n>=120){clearInterval(iv);btn.classList.remove('busy');setTxt('Timed out \\u2014 try again ');}\n`
  + `   }).catch(function(){});\n`
  + `  },15000);\n`
  + ` }).catch(function(){btn.classList.remove('busy');setTxt('No connection \\u2014 try again ');});\n`
  + `};\n`
  + `})();\n`
  + `</script>`;

function patchPage(html, dateStr) {
  // strip any v1 leftovers (old fixed-corner button + old tab) and any prior v2 block
  html = html.replace(/<style>\/\*DEALS-REFRESH-v1\*\/[\s\S]*?<\/style>\n?/g, '');
  html = html.replace(/<script>\/\*DEALS-REFRESH-v1\*\/[\s\S]*?<\/script>\n?/g, '');
  html = html.replace(new RegExp(`<style>/\\*${MARK}\\*/[\\s\\S]*?</style>\\n?`, 'g'), '');
  html = html.replace(new RegExp(`<script>/\\*${MARK}\\*/[\\s\\S]*?</script>\\n?`, 'g'), '');
  html = html.replace(/\s*<a class="tablink"[^>]*>↻ Refresh<\/a>/g, '');
  // baked date: time only, no "Updated"
  html = html.replace(/(<div class="lastupd" id="lastupd">)[^<]*/, '$1' + dateStr + ' ');
  // inject block before </body>
  html = html.replace(/<\/body>/, PAGE_CSS + '\n' + PAGE_JS + '\n</body>');
  return html;
}

// ---------- dead-listing pruning ----------
const DEAD_RE = /this posting has been (deleted|flagged)|this posting has expired|page not found/i;
async function isDead(url) {
  for (let attempt = 0; attempt < 2; attempt++) {
    try {
      const r = await fetch(url, { redirect: 'follow', headers: { 'User-Agent': 'Mozilla/5.0' } });
      if (r.status === 404 || r.status === 410) return true;
      if (!r.ok) return false;            // blocked/rate-limited — keep the listing
      const body = await r.text();
      return DEAD_RE.test(body);
    } catch (e) { /* network hiccup — retry once */ }
  }
  return false;                           // uncertain — keep
}

async function pruneDead(html) {
  const a = html.indexOf('<!--GRID:START-->'), b = html.indexOf('<!--GRID:END-->');
  if (a < 0 || b < 0) { console.log('grid markers missing — skip prune'); return { html, dropped: 0, kept: -1 }; }
  const grid = html.slice(a, b);
  const cards = grid.match(/<article class="card"[\s\S]*?<\/article>/g) || [];
  console.log('cards found: ' + cards.length);
  const results = new Array(cards.length).fill(false);
  let idx = 0;
  const CONC = 6;
  async function worker() {
    while (idx < cards.length) {
      const i = idx++;
      const m = cards[i].match(/href="(https:\/\/[^"]*craigslist[^"]*)"/);
      results[i] = m ? await isDead(m[1]) : false;
      await new Promise(res => setTimeout(res, 250));
    }
  }
  await Promise.all(Array.from({ length: CONC }, worker));
  const keep = cards.filter((c, i) => !results[i]);
  const dropped = cards.length - keep.length;
  // reindex data-ri sequentially
  const rebuilt = keep.map((c, i) => c.replace(/data-ri="\d+"/, `data-ri="${i}"`)).join('');
  const newGrid = '<!--GRID:START-->' + rebuilt;
  const html2 = html.slice(0, a) + newGrid + html.slice(b);
  console.log(`dropped ${dropped} dead listing(s), kept ${keep.length}`);
  return { html: html2, dropped, kept: keep.length };
}

// ---------- main ----------
(async () => {
  // 0) due?
  const req = (await jf(`${DBROOT}/_deals/refresh_request.json`)).json;
  const handled = (await jf(`${DBROOT}/_deals/refresh_handled.json`)).json;
  const updated = (await jf(`${DBROOT}/_deals/updated.json`)).json;
  const now = Date.now();
  const flagDue = req != null && req !== handled;
  const staleDue = !updated || (now - updated) > STALE_MS;
  const force = process.env.FORCE === '1';
  console.log(JSON.stringify({ req, handled, updated, flagDue, staleDue, force }));
  if (!flagDue && !staleDue && !force) { console.log('not due — exiting.'); return; }

  const KEYRAW = process.env.FIREBASE_SA_KEY;
  if (!KEYRAW) { console.log('FIREBASE_SA_KEY secret is not set — cannot deploy. Exiting (no-op).'); return; }
  let KEY;
  try { KEY = JSON.parse(KEYRAW); } catch (e) { console.log('FIREBASE_SA_KEY is not valid JSON'); process.exit(1); }

  // 1) service-account JWT -> access token
  const iat = Math.floor(now / 1000);
  const hdr = Buffer.from(JSON.stringify({ alg: 'RS256', typ: 'JWT' })).toString('base64url');
  const clm = Buffer.from(JSON.stringify({
    iss: KEY.client_email, scope: 'https://www.googleapis.com/auth/cloud-platform',
    aud: 'https://oauth2.googleapis.com/token', iat, exp: iat + 3600,
  })).toString('base64url');
  const sig = crypto.createSign('RSA-SHA256').update(hdr + '.' + clm).sign(KEY.private_key, 'base64url');
  const tok = await jf('https://oauth2.googleapis.com/token', {
    method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: 'grant_type=' + encodeURIComponent('urn:ietf:params:oauth:grant-type:jwt-bearer')
      + '&assertion=' + hdr + '.' + clm + '.' + sig,
  });
  if (!tok.json.access_token) { console.log('TOKEN FAILED: ' + JSON.stringify(tok.json).slice(0, 300)); process.exit(1); }
  const H = { Authorization: 'Bearer ' + tok.json.access_token, 'x-goog-user-project': PROJECT };

  // 2) current live version + its full file manifest (path -> hash)
  let r = await jf(`${API}/sites/${SITE}/releases?pageSize=1`, { headers: H });
  const liveVersion = r.json.releases && r.json.releases[0] && r.json.releases[0].version && r.json.releases[0].version.name;
  if (!liveVersion) { console.log('NO LIVE VERSION: ' + JSON.stringify(r.json).slice(0, 300)); process.exit(1); }
  console.log('live version: ' + liveVersion);
  const manifest = {};
  let pageToken = '';
  do {
    r = await jf(`${API}/${liveVersion}/files?pageSize=1000${pageToken ? '&pageToken=' + pageToken : ''}`, { headers: H });
    (r.json.files || []).forEach(f => { manifest[f.path] = f.hash; });
    pageToken = r.json.nextPageToken || '';
  } while (pageToken);
  console.log('live manifest: ' + Object.keys(manifest).length + ' files');
  if (!manifest['/index.html']) { console.log('manifest missing /index.html — abort'); process.exit(1); }

  // 3) fetch live index.html, prune dead listings, apply UI patch
  let html = await (await fetch(`${LIVE}/index.html?ci=` + now)).text();
  console.log('fetched index.html: ' + html.length + ' bytes');
  const pr = await pruneDead(html);
  html = patchPage(pr.html, nowLA());

  // 4) deploy: new version, manifest = live files with /index.html swapped
  const gz = zlib.gzipSync(Buffer.from(html), { level: 9 });
  const hash = crypto.createHash('sha256').update(gz).digest('hex');
  manifest['/index.html'] = hash;
  r = await jf(`${API}/sites/${SITE}/versions`, { method: 'POST', headers: { ...H, 'Content-Type': 'application/json' }, body: '{}' });
  const version = r.json.name;
  if (!version) { console.log('VERSION FAILED: ' + JSON.stringify(r.json).slice(0, 300)); process.exit(1); }
  r = await jf(`${API}/${version}:populateFiles`, {
    method: 'POST', headers: { ...H, 'Content-Type': 'application/json' },
    body: JSON.stringify({ files: manifest }),
  });
  if (r.status !== 200) { console.log('POPULATE FAILED: ' + JSON.stringify(r.json).slice(0, 400)); process.exit(1); }
  const need = r.json.uploadRequiredHashes || [];
  console.log('upload required: ' + need.length);
  if (need.includes(hash)) {
    const up = await fetch(r.json.uploadUrl + '/' + hash, {
      method: 'POST', headers: { ...H, 'Content-Type': 'application/octet-stream' }, body: gz,
    });
    if (up.status !== 200) { console.log('UPLOAD FAILED ' + up.status); process.exit(1); }
    console.log('uploaded index.html');
  }
  r = await jf(`${API}/${version}?update_mask=status`, {
    method: 'PATCH', headers: { ...H, 'Content-Type': 'application/json' },
    body: JSON.stringify({ status: 'FINALIZED' }),
  });
  if (r.status !== 200) { console.log('FINALIZE FAILED: ' + JSON.stringify(r.json).slice(0, 300)); process.exit(1); }
  r = await jf(`${API}/sites/${SITE}/releases?versionName=` + version, { method: 'POST', headers: H });
  if (r.status !== 200) { console.log('RELEASE FAILED: ' + JSON.stringify(r.json).slice(0, 300)); process.exit(1); }
  console.log('RELEASED ✅');

  // 5) stamp completion so the page/button sees it
  await fetch(`${DBROOT}/_deals/updated.json`, { method: 'PUT', body: JSON.stringify(Date.now()) });
  if (req != null) await fetch(`${DBROOT}/_deals/refresh_handled.json`, { method: 'PUT', body: JSON.stringify(req) });
  console.log(`DONE — dropped ${pr.dropped}, kept ${pr.kept}, date set to "${nowLA()}"`);
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
