// Site check (runs on every push that touches sites/key-technologies): loads every real page in light and dark at phone width,
// reports horizontal overflow at 320/390/1280 and serious/critical WCAG A/AA problems (axe). Informational: it can turn the check red but never blocks the deploy.
const pw = require('playwright'); const fs = require('fs'); const path = require('path');
const root = process.env.SITE_ROOT || 'sites/key-technologies', base = process.env.SITE_URL || 'http://localhost:8765/';
const axeSrc = fs.readFileSync(require.resolve('axe-core/axe.min.js'), 'utf8');
// known / intentional: a deliberately low-contrast "before" mock-up, and two owner/preview-only pages that are not linked from the public site
const SKIP_AXE = new Set(['key-platform/demos/accessibility-ada.html']), SKIP_OVERFLOW = new Set(['key-pageviews.html', 'rewards-layout-preview.html']);
function walk(d, o = []) { for (const f of fs.readdirSync(d)) { const p = path.join(d, f); if (f === 'fonts') continue; const s = fs.statSync(p); if (s.isDirectory()) walk(p, o); else if (f.endsWith('.html')) o.push(path.relative(root, p)); } return o; }
const pages = walk(root).filter(p => !fs.readFileSync(path.join(root, p), 'utf8').slice(0, 900).includes('http-equiv="refresh"')).sort();
(async () => {
  const b = await pw.chromium.launch(); const bad = [];
  for (const p of pages) for (const theme of ['light', 'dark']) {
    const ctx = await b.newContext({ viewport: { width: 390, height: 844 } }); const pg = await ctx.newPage(); const errs = [];
    pg.on('pageerror', e => errs.push('JS error: ' + String(e).slice(0, 100)));
    pg.on('response', r => { if (r.status() >= 400 && r.url().startsWith(base)) errs.push('HTTP ' + r.status() + ' ' + r.url().slice(base.length)); });
    try {
      await pg.goto(base + p + (theme === 'dark' ? '?look=dark' : ''), { waitUntil: 'load', timeout: 25000 }); await pg.waitForTimeout(1200);
      if (!SKIP_OVERFLOW.has(p)) for (const w of [320, 390, 1280]) { await pg.setViewportSize({ width: w, height: 844 }); await pg.waitForTimeout(120); const ov = await pg.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth); if (ov > 0) errs.push('sideways scroll ' + ov + 'px at ' + w + 'px wide'); }
      await pg.setViewportSize({ width: 390, height: 844 });
      if (!SKIP_AXE.has(p)) { await pg.evaluate(async () => { for (let y = 0, n = 0; y < document.body.scrollHeight && n < 40; y += 300, n++) { window.scrollTo(0, y); await new Promise(r => setTimeout(r, 40)); } window.scrollTo(0, 0); }); await pg.waitForTimeout(2200); await pg.evaluate(axeSrc); const ax = await pg.evaluate(async () => (await axe.run(document, { resultTypes: ['violations'], runOnly: ['wcag2a', 'wcag2aa'] })).violations.filter(v => ['serious', 'critical'].includes(v.impact)).map(v => v.id + ' x' + v.nodes.length + ' ' + v.nodes[0].target.join(' ').slice(0, 50))); ax.forEach(a => errs.push('accessibility: ' + a)); }
    } catch (e) { errs.push('could not load: ' + String(e).slice(0, 80)); }
    if (errs.length) bad.push(p + ' [' + theme + '] ' + errs.join(' ; '));
    await ctx.close();
  }
  await b.close();
  console.log(pages.length + ' pages x light/dark checked; ' + bad.length + ' with problems'); bad.forEach(x => console.log('PROBLEM ' + x));
  process.exit(bad.length ? 1 : 0);
})();
