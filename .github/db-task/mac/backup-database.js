#!/usr/bin/env node
// Weekly database backup (runs on YOUR Mac; files stay on YOUR Mac in ~/lvr-backups, never uploaded anywhere).
// Signs in with the owner's saved sign-in token (no password is stored: ~/.lvr/owner-refresh holds a renewable token), reads every data area one at a time,
// and writes one gzip file per area into ~/lvr-backups/<date>/. Keeps the newest 12 weekly folders. Prints only counts and sizes, never data.
const fs = require('fs'), path = require('path'), os = require('os'), zlib = require('zlib');
const DB = process.env.BACKUP_DB || 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const TOKEN_URL = process.env.BACKUP_TOKEN_URL || 'https://securetoken.googleapis.com/v1/token';
const HOME = os.homedir(), OUTROOT = process.env.BACKUP_OUT || path.join(HOME, 'lvr-backups');
const NODES = ['dashboard', 'dashboard_crec', 'dashboard_adv_crec', 'dashboard_exp_crec', 'dashboard_infl_crec', 'dashboard_deleted', 'dashboard_rest_stg_crec',
  'lvr_points', 'lvr_rewards', 'lvr_instagram_index', 'lvr_coupons', 'key_leads', 'key_pageviews', 'kt_crm', 'key_rewards', 'lvr_member_private', 'lvr_refcodes', '_deals'];
(async () => {
  let idToken = '';
  try {
    const rt = fs.readFileSync(path.join(HOME, '.lvr', 'owner-refresh'), 'utf8').trim();
    const key = await (await fetch(DB + '/ownerAuth/apiKey.json')).json();
    const r = await fetch(TOKEN_URL + '?key=' + encodeURIComponent(key), { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: 'grant_type=refresh_token&refresh_token=' + encodeURIComponent(rt) });
    if (r.ok) { const j = await r.json(); idToken = j.id_token || ''; if (j.refresh_token && j.refresh_token !== rt) fs.writeFileSync(path.join(HOME, '.lvr', 'owner-refresh'), j.refresh_token, { mode: 0o600 }); }
  } catch (e) {}
  if (!idToken) console.log('NOTE: no owner sign-in token, so the owner-only areas (leads, page views, CRM) will be skipped. Run backup-setup.sh again to sign in.');
  const stamp = new Date().toISOString().slice(0, 10), dir = path.join(OUTROOT, stamp); fs.mkdirSync(dir, { recursive: true });
  let ok = 0, skipped = 0, total = 0;
  for (const n of NODES) {
    try {
      const r = await fetch(DB + '/' + n + '.json' + (idToken ? '?auth=' + encodeURIComponent(idToken) : ''));
      if (!r.ok) { console.log('skipped ' + n + ' (HTTP ' + r.status + ')'); skipped++; continue; }
      const t = await r.text(); if (t === 'null') { skipped++; continue; }
      const gz = zlib.gzipSync(Buffer.from(t)); fs.writeFileSync(path.join(dir, n + '.json.gz'), gz, { mode: 0o600 }); ok++; total += gz.length;
      console.log('saved ' + n + ' (' + Math.round(t.length / 1024) + ' KB, ' + Math.round(gz.length / 1024) + ' KB zipped)');
    } catch (e) { console.log('failed ' + n + ': ' + e.message); skipped++; }
    await new Promise(r => setTimeout(r, 300));
  }
  // keep the newest 12 weekly folders
  try { const all = fs.readdirSync(OUTROOT).filter(d => /^\d{4}-\d{2}-\d{2}$/.test(d)).sort(); all.slice(0, Math.max(0, all.length - 12)).forEach(d => fs.rmSync(path.join(OUTROOT, d), { recursive: true, force: true })); } catch (e) {}
  console.log('BACKUP DONE: ' + ok + ' areas saved (' + Math.round(total / 1024) + ' KB), ' + skipped + ' skipped -> ' + dir);
  process.exit(ok ? 0 : 1);
})().catch(e => { console.log('BACKUP FAILED: ' + e.message); process.exit(1); });
