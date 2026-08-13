// Laptop-free Deals refresh — ALS/containers-style. Runs in GitHub Actions.
// No secrets, no hosting deploy: the page reads everything it needs from RTDB.
//  1. Runs when the site's round ⟳ button set the flag, when data is stale (>3h), or FORCE=1
//  2. Fetches the live Deals page, checks every Craigslist listing it shows
//  3. Writes the dead ones to _deals/removed (the page hides them + fixes the count)
//  4. Stamps _deals/updated (the page shows this as the big time next to the ⟳)
// New-car discovery still comes from the Mac generator; this keeps the list honest
// (sold/expired cars gone, time current) around the clock.
'use strict';

const DBROOT = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const LIVE = 'https://classiccarsforsale-co.web.app';
const STALE_MS = 3 * 3600 * 1000;

async function fetchRetry(url, opt, tries) {
  tries = tries || 4;
  let lastErr;
  for (let i = 0; i < tries; i++) {
    try { return await fetch(url, opt); }
    catch (e) {
      lastErr = e;
      console.log(`fetch attempt ${i + 1}/${tries} failed for ${url}: ${e.message}${e.cause ? ' — ' + e.cause.message : ''}`);
      await new Promise(res => setTimeout(res, 2000 * (i + 1)));
    }
  }
  throw lastErr;
}

async function jf(url, opt) {
  const r = await fetchRetry(url, opt);
  const t = await r.text();
  let d; try { d = JSON.parse(t); } catch (e) { d = null; }
  return { status: r.status, json: d, text: t };
}

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

(async () => {
  // 0) due?
  const req = (await jf(`${DBROOT}/_deals/refresh_request.json`)).json;
  const handled = (await jf(`${DBROOT}/_deals/refresh_handled.json`)).json;
  const updated = (await jf(`${DBROOT}/_deals/updated.json`)).json;
  const now = Date.now();
  const reqTs = req && typeof req === 'object' ? req.req : req;
  const handledTs = handled && typeof handled === 'object' ? handled.req : handled;
  const flagDue = reqTs != null && reqTs !== handledTs;
  const staleDue = !updated || (now - updated) > STALE_MS;
  const force = process.env.FORCE === '1';
  console.log(JSON.stringify({ reqTs, handledTs, updated, flagDue, staleDue, force }));
  if (!flagDue && !staleDue && !force) { console.log('not due — exiting.'); return; }

  // 1) live page -> [slug, url] per card
  // NOTE: fetch "/" not "/index.html" — hosting's clean-URLs redirect loops on the latter
  const html = await (await fetchRetry(`${LIVE}/?ci=` + now)).text();
  console.log('fetched index.html: ' + html.length + ' bytes');
  const a = html.indexOf('<!--GRID:START-->'), b = html.indexOf('<!--GRID:END-->');
  if (a < 0 || b < 0) { console.log('grid markers missing — abort'); process.exit(1); }
  const cards = html.slice(a, b).match(/<article class="card[^"]*"[\s\S]*?<\/article>/g) || [];
  const items = cards.map(c => {
    const slug = (c.match(/data-fav="([^"]+)"/) || [])[1];
    const url = (c.match(/href="(https:\/\/[^"]*craigslist[^"]*)"/) || [])[1];
    return slug && url ? { slug, url } : null;
  }).filter(Boolean);
  console.log(`cards: ${cards.length}, checkable: ${items.length}`);

  // 2) check each listing (gentle concurrency)
  const dead = {};
  let idx = 0, checked = 0;
  const CONC = 6;
  async function worker() {
    while (idx < items.length) {
      const it = items[idx++];
      if (await isDead(it.url)) dead[it.slug] = true;
      checked++;
      await new Promise(res => setTimeout(res, 250));
    }
  }
  await Promise.all(Array.from({ length: CONC }, worker));
  const deadN = Object.keys(dead).length;
  console.log(`checked ${checked}, dead: ${deadN}` + (deadN ? ' -> ' + Object.keys(dead).slice(0, 10).join(', ') : ''));

  // 3) publish results for the page
  let r = await fetchRetry(`${DBROOT}/_deals/removed.json`, {
    method: 'PUT', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(deadN ? dead : null),
  });
  console.log('removed write: ' + r.status);
  r = await fetchRetry(`${DBROOT}/_deals/updated.json`, {
    method: 'PUT', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(Date.now()),
  });
  console.log('updated write: ' + r.status);
  if (reqTs != null) {
    await fetchRetry(`${DBROOT}/_deals/refresh_handled.json`, {
      method: 'PUT', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(reqTs),
    });
  }
  console.log(`DONE — live cars: ${items.length - deadN} of ${items.length}`);
})().catch(e => { console.log('FATAL: ' + (e.stack || e.message)); process.exit(1); });
