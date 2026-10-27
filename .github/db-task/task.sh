#!/bin/bash
# 1) read-only: Aspire Coffee House business info from the LVR list (no personal email); 2) fetch candidate coffee photos (freely licensed).
node <<'NODE'
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
(async () => {
  const crec = await (await fetch(DB + '/dashboard_crec.json')).json() || {};
  Object.keys(crec).map(k => crec[k]).filter(r => r && /aspire/i.test(String(r.name))).forEach(r => console.log(JSON.stringify({ n: r.name, a: r.address || null, p: r.phone || null, ig: r.instagram || null, igh: r.igHandle || null, cu: r.cuisine || r.category || null })));
})();
NODE
mkdir -p sites/key-technologies/img/food-candidates
node <<'NODE'
const fs = require('fs');
const OUT = 'sites/key-technologies/img/food-candidates';
const sleep = ms => new Promise(r => setTimeout(r, ms));
const UA = { headers: { 'User-Agent': 'KeyTechnologiesDemo/1.0 (contact via keytechnologies.si)' } };
const OKLIC = /^(cc0|public domain|pd|cc[ -]by(-sa)?[ -]?[0-9.]*)/i;
const rank = l => /^(cc0|public domain|pd)/i.test(l) ? 0 : /^cc[ -]by[ -]?[0-9.]*$/i.test(l) ? 1 : 2;
const strip = s => String(s || '').replace(/<[^>]*>/g, '').replace(/\s+/g, ' ').trim().slice(0, 140);
(async () => {
  const credits = {};
  for (const [slug, term] of Object.entries({ latte: 'latte art coffee cup', coffee: 'cappuccino coffee cafe' })) {
    let j = null;
    for (let t = 0; t < 4 && !j; t++) { await sleep(2500 + t * 3000); try { const rr = await fetch('https://commons.wikimedia.org/w/api.php?action=query&format=json&generator=search&gsrnamespace=6&gsrlimit=30&gsrsearch=' + encodeURIComponent(term + ' filetype:bitmap') + '&prop=imageinfo&iiprop=url|size|mime|extmetadata&iiurlwidth=800', UA); if (rr.ok) j = await rr.json(); } catch (e) {} }
    if (!j) { console.log(slug + ': search failed'); continue; }
    const cand = Object.values((j.query && j.query.pages) || {}).map(p => { const ii = (p.imageinfo || [])[0]; if (!ii) return null; const m = ii.extmetadata || {}; return { title: p.title, ii, lic: (m.LicenseShortName || {}).value || '', artist: strip((m.Artist || {}).value) }; })
      .filter(c => c && c.ii.mime === 'image/jpeg' && c.ii.width >= 1000 && c.ii.height >= 700 && OKLIC.test(c.lic))
      .sort((a, b) => rank(a.lic) - rank(b.lic) || (b.ii.width * b.ii.height) - (a.ii.width * a.ii.height)).slice(0, 4);
    let n = 0;
    for (const c of cand) { try { await sleep(800); const r = await fetch(c.ii.thumburl, UA); if (!r.ok) continue; n++; const f = slug + '-' + n + '.jpg'; fs.writeFileSync(OUT + '/' + f, Buffer.from(await r.arrayBuffer())); credits[f] = { license: c.lic, author: c.artist, source: c.ii.descriptionurl, title: c.title }; } catch (e) {} }
    console.log(slug + ': ' + n + ' saved');
  }
  fs.writeFileSync(OUT + '/credits.json', JSON.stringify(credits, null, 1));
})();
NODE
git config user.name "github-actions"; git config user.email "actions@users.noreply.github.com"
git add sites/key-technologies/img/food-candidates
git commit -m "Candidate coffee photos for review" -q && git push -q origin HEAD:claude/master-file-e6ofy0 && echo "committed and pushed"
