#!/usr/bin/env node
// Dealership staff-page reader (runs on YOUR Mac, writes a CSV on YOUR Mac; nothing here is ever uploaded to the public repo).
// For each dealership website in the list it politely opens the dealership's OWN public "meet our team / staff" page and keeps the sales people
// it shows (name, job title, and an email ONLY if the page itself prints one next to that person; no phone numbers are collected). It never guesses email addresses, never opens login pages,
// social media or review sites, obeys the site's robots.txt, waits between requests and stops when a site says no.
// Usage: node scrape-dealer-staff.js <dealers.csv> <out.csv> [maxDealers]
const fs = require('fs');
const UA = 'Mozilla/5.0 (compatible; KeyTechnologiesResearch/1.0; one polite visit per page)';
const DELAY = Number(process.env.SCRAPE_DELAY || 2500), TIMEOUT = 15000;
const ROLE = /(sales\s*(consultant|professional|associate|advisor|adviser|representative|rep|executive|specialist|manager|director|person)|general\s*(sales\s*)?manager|general manager|internet\s*(sales\s*)?(manager|director|consultant|specialist|advisor|coordinator)|bdc|business development|brand\s*(specialist|ambassador)|product\s*(specialist|expert|genius|advisor)|client\s*advisor|customer\s*(advisor|experience)|fleet|owner|dealer principal|finance\s*(manager|director)|new\s*car\s*manager|used\s*car\s*manager|sales\s*&?\s*leasing)/i;
const SALESY = /(sales|consultant|brand|product|advisor|adviser|bdc|internet|manager|owner|principal|specialist|finance|fleet)/i;
const NOTNAME = /^(meet|our|the|team|staff|sales|service|parts|finance|department|contact|call|text|email|phone|home|new|used|inventory|specials|about|us|directions|hours|view|read|more|schedule|get|apply|value|your|trade|privacy|policy|terms|menu|search|find|shop|book|certified|pre-owned|toyota|honda|ford|chevrolet|nissan|hyundai|kia|bmw|mercedes|audi|lexus|subaru|mazda|volkswagen|jeep|dodge|ram|gmc|buick|cadillac|tesla|infiniti|acura|las|vegas|nevada|henderson)$/i;
const PATHS = ['/meet-our-staff', '/meet-our-team', '/staff', '/about-us/staff', '/about-us/meet-our-team', '/about/staff', '/dealership/staff.htm', '/dealership/meet-our-staff.htm', '/staff.aspx', '/our-team', '/meet-the-team', '/our-staff', '/team', '/about-us/our-team', '/dealership/staff'];
const sleep = ms => new Promise(r => setTimeout(r, ms));
function parseCsv(text) { const rows = []; let row = [], f = '', q = false; text = text.replace(/^﻿/, '');
  for (let i = 0; i < text.length; i++) { const c = text[i];
    if (q) { if (c === '"') { if (text[i + 1] === '"') { f += '"'; i++; } else q = false; } else f += c; }
    else if (c === '"') q = true; else if (c === ',') { row.push(f); f = ''; } else if (c === '\n') { row.push(f); rows.push(row); row = []; f = ''; } else if (c !== '\r') f += c; }
  if (f || row.length) { row.push(f); rows.push(row); } return rows.filter(r => r.some(x => x.trim())); }
const cell = v => { v = v == null ? '' : String(v); return /[",\n\r]/.test(v) ? '"' + v.replace(/"/g, '""') + '"' : v; };
async function get(url) {
  const ctl = new AbortController(); const t = setTimeout(() => ctl.abort(), TIMEOUT);
  try { const r = await fetch(url, { headers: { 'User-Agent': UA, 'Accept': 'text/html,application/xhtml+xml' }, redirect: 'follow', signal: ctl.signal });
    const ct = r.headers.get('content-type') || ''; const body = r.ok && (!ct || /html|xml|text/i.test(ct)) ? await r.text() : ''; return { status: r.status, url: r.url, body }; }
  catch (e) { return { status: 0, url, body: '', err: e.name === 'AbortError' ? 'timeout' : (e.cause && e.cause.code) || e.message }; }
  finally { clearTimeout(t); } }
// robots.txt: only "User-agent: *" rules, only Disallow/Allow prefixes
function robotsAllows(txt, path) {
  if (!txt) return true; let on = false, dis = [], allow = [];
  for (const raw of txt.split(/\r?\n/)) { const l = raw.replace(/#.*/, '').trim(); if (!l) continue; const m = l.match(/^([a-z-]+)\s*:\s*(.*)$/i); if (!m) continue;
    const k = m[1].toLowerCase(), v = m[2].trim();
    if (k === 'user-agent') on = v === '*'; else if (on && k === 'disallow' && v) dis.push(v); else if (on && k === 'allow' && v) allow.push(v); }
  const best = (arr) => arr.filter(p => path.startsWith(p.replace(/\*.*$/, ''))).reduce((a, p) => Math.max(a, p.length), -1);
  return best(allow) >= best(dis); }
function toLines(html) {
  html = html.replace(/<script[\s\S]*?<\/script>|<style[\s\S]*?<\/style>|<!--[\s\S]*?-->/gi, ' ');
  // keep mailto/tel targets visible as text so they stay next to the person
  html = html.replace(/<a\b[^>]*href=["']mailto:([^"'?\s]+)[^>]*>/gi, ' [[mail:$1]] ').replace(/<a\b[^>]*href=["']tel:([^"'\s]+)[^>]*>/gi, ' [[tel:$1]] ');
  html = html.replace(/<(br|\/p|\/div|\/li|\/h[1-6]|\/tr|\/td|\/section|\/article|\/span)\b[^>]*>/gi, '\n').replace(/<[^>]+>/g, ' ');
  html = html.replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&').replace(/&#39;|&apos;/g, "'").replace(/&quot;/g, '"').replace(/&#x27;/g, "'");
  return html.split('\n').map(s => s.replace(/\s+/g, ' ').trim()).filter(Boolean); }
function looksLikeName(s) {
  s = s.replace(/\[\[(mail|tel):[^\]]*\]\]/g, '').trim(); if (s.length < 5 || s.length > 40 || /[\d@:/]/.test(s)) return null;
  const parts = s.split(/\s+/); if (parts.length < 2 || parts.length > 4) return null;
  if (!parts.every(p => /^[A-Z][a-zA-Z.'’-]+$/.test(p) || /^(jr|sr|ii|iii)\.?$/i.test(p))) return null;
  if (parts.some(p => NOTNAME.test(p))) return null; if (ROLE.test(s)) return null; return s; }
function extractPeople(html) {
  const lines = toLines(html), out = [], seen = new Set();
  const nearby = (i, kind) => { for (let j = i; j <= Math.min(lines.length - 1, i + 5); j++) { const m = lines[j].match(new RegExp('\\[\\[' + kind + ':([^\\]]+)\\]\\]')); if (m) return m[1]; if (j > i && looksLikeName(lines[j].replace(/\[\[(mail|tel):[^\]]*\]\]/g, ''))) break; } return ''; };
  for (let i = 0; i < lines.length; i++) {
    let name = null, role = '';
    const clean = lines[i].replace(/\[\[(mail|tel):[^\]]*\]\]/g, '').trim();
    const m = clean.match(/^(.{4,40}?)\s*[-–—|,]\s*(.{3,60})$/);   // "Name - Title" / "Name, Title"
    if (m && looksLikeName(m[1]) && ROLE.test(m[2])) { name = looksLikeName(m[1]); role = m[2]; }
    else if (looksLikeName(clean)) { for (let j = i + 1; j <= i + 3 && j < lines.length; j++) { const c2 = lines[j].replace(/\[\[(mail|tel):[^\]]*\]\]/g, '').trim(); if (ROLE.test(c2) && c2.length <= 70) { name = looksLikeName(clean); role = c2; break; } if (looksLikeName(c2)) break; } }
    if (!name || !SALESY.test(role)) continue;
    const key = name.toLowerCase(); if (seen.has(key)) continue; seen.add(key);
    let email = nearby(i, 'mail'); if (email && !/^[^@\s]+@[^@\s]+\.[a-z]{2,}$/i.test(email)) email = '';
    out.push({ name, role: role.replace(/\s+/g, ' '), email: email.toLowerCase(), phone: nearby(i, 'tel') }); }
  return out; }
function staffLinks(html, base) {
  const found = []; const re = /<a\b[^>]*href=["']([^"'#]+)["'][^>]*>([\s\S]*?)<\/a>/gi; let m;
  while ((m = re.exec(html))) { const href = m[1], txt = m[2].replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
    if (/(meet|our)[-_ ]?(the[-_ ]?)?(team|staff|people)|^staff|\/staff|\/team|sales[-_ ]team/i.test(href + ' ' + txt) && !/service|parts|careers|jobs|reviews|mailto|tel:/i.test(href + txt)) {
      try { const u = new URL(href, base); if (u.origin === new URL(base).origin) found.push(u.href); } catch (e) {} } }
  return [...new Set(found)].slice(0, 4); }
(async () => {
  const [inFile, outFile, maxArg] = process.argv.slice(2); if (!inFile || !outFile) { console.log('usage: node scrape-dealer-staff.js dealers.csv out.csv [maxDealers]'); process.exit(1); }
  if (typeof fetch !== 'function') { console.log('This needs Node 18 or newer (type: node -v).'); process.exit(1); }
  const rows = parseCsv(fs.readFileSync(inFile, 'utf8')); const head = rows[0].map(h => h.trim().toLowerCase()); const col = (r, k) => { const i = head.indexOf(k); return i < 0 ? '' : (r[i] || '').trim(); };
  let dealers = rows.slice(1).map(r => ({ name: col(r, 'dealership'), website: col(r, 'website'), address: [col(r, 'address'), col(r, 'city'), col(r, 'zip')].filter(Boolean).join(', '), phone: col(r, 'main_phone') })).filter(d => /^https?:\/\//i.test(d.website));
  if (maxArg) dealers = dealers.slice(0, Number(maxArg));
  const outCols = ['dealership', 'person_name', 'role', 'email', 'address', 'website', 'source_url', 'confidence', 'notes'];
  const out = [outCols.join(',')]; const report = []; let people = 0;
  for (let n = 0; n < dealers.length; n++) {
    const d = dealers[n]; let origin; try { origin = new URL(d.website).origin; } catch (e) { continue; }
    process.stdout.write(`[${n + 1}/${dealers.length}] ${d.name} ... `);
    const rb = await get(origin + '/robots.txt'); await sleep(DELAY); const robots = rb.status === 200 ? rb.body : '';
    const tried = []; let best = null, why = 'no staff page found';
    const home = robotsAllows(robots, '/') ? await get(d.website) : { status: 0, body: '', err: 'robots' }; await sleep(DELAY);
    let cand = home.body ? staffLinks(home.body, home.url || d.website) : []; cand = cand.concat(PATHS.map(p => origin + p));
    cand = [...new Set(cand)].slice(0, 9);
    for (const u of cand) {
      let path = '/'; try { path = new URL(u).pathname; } catch (e) {}
      if (!robotsAllows(robots, path)) { why = 'robots.txt says no'; continue; }
      const r = await get(u); tried.push(path + '=' + r.status); await sleep(DELAY);
      if (r.status === 403 || r.status === 429) { why = 'site blocked automated visits (HTTP ' + r.status + ')'; break; }
      if (r.status !== 200 || !r.body) continue;
      const ppl = extractPeople(r.body);
      if (ppl.length >= 2) { best = { url: r.url, ppl }; break; }
      if (/<script[^>]*src=[^>]*(staff|team)|data-react|__NEXT_DATA__|window\.__/i.test(r.body) && why === 'no staff page found') why = 'page may load names with JavaScript (not readable by this simple reader)'; }
    if (best) { people += best.ppl.length; best.ppl.forEach(p => out.push([d.name, p.name, p.role, p.email, d.address, d.website, best.url, p.email ? 'email published on page' : 'name and title only', ''].map(cell).join(','))); console.log(best.ppl.length + ' people'); report.push(d.name + ': ' + best.ppl.length + ' people (' + best.url + ')'); }
    else { console.log('none (' + why + ')'); report.push(d.name + ': none (' + why + '; tried ' + (tried.join(' ') || 'nothing') + ')'); }
    fs.writeFileSync(outFile, out.join('\n') + '\n'); }
  fs.writeFileSync(outFile.replace(/\.csv$/, '') + '-report.txt', report.join('\n') + '\n');
  console.log('\nDone: ' + people + ' people from ' + report.filter(r => !/: none/.test(r)).length + ' of ' + dealers.length + ' dealerships.\nFile: ' + outFile); })();
