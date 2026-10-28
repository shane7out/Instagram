#!/bin/bash
# Fetch FOOD-only candidate photos (Public Domain / CC0, large, mostly professional Unsplash uploads on Wikimedia Commons).
mkdir -p sites/key-technologies/img/food-candidates10
node <<'NODE'
const fs = require('fs');
const OUT = 'sites/key-technologies/img/food-candidates10';
const sleep = ms => new Promise(r => setTimeout(r, ms));
const UA = { headers: { 'User-Agent': 'KeyTechnologiesDemo/1.0 (contact via keytechnologies.si)' } };
const TERMS = {
  latte: ['latte art Unsplash', 'latte art', 'cappuccino Unsplash', 'flat white coffee'], coffee: ['coffee cup Unsplash', 'coffee Unsplash', 'espresso Unsplash', 'cafe coffee cup saucer'],
  coffee2: ['coffee and croissant Unsplash', 'coffee and pastry', 'coffee beans cup Unsplash', 'cafe latte Unsplash']
};
const strip = s => String(s || '').replace(/<[^>]*>/g, '').replace(/\s+/g, ' ').trim().slice(0, 120);
(async () => {
  const credits = {};
  for (const [slug, terms] of Object.entries(TERMS)) {
    let cand = [];
    for (const term of terms) {
      let j = null;
      for (let t = 0; t < 4 && !j; t++) {
        await sleep(2800 + t * 3000);
        try { const rr = await fetch('https://commons.wikimedia.org/w/api.php?action=query&format=json&generator=search&gsrnamespace=6&gsrlimit=40&gsrsearch=' + encodeURIComponent(term + ' filetype:bitmap') + '&prop=imageinfo&iiprop=url|size|mime|extmetadata&iiurlwidth=800', UA); if (rr.ok) j = await rr.json(); } catch (e) {}
      }
      if (!j) { console.log(slug + ' / ' + term + ': search failed'); continue; }
      cand = cand.concat(Object.values((j.query && j.query.pages) || {}).map(p => { const ii = (p.imageinfo || [])[0]; if (!ii) return null; const m = ii.extmetadata || {}; return { title: p.title, ii, lic: (m.LicenseShortName || {}).value || '', artist: strip((m.Artist || {}).value) }; })
        .filter(c => c && c.ii.mime === 'image/jpeg' && c.ii.width >= 1400 && c.ii.height >= 900 && /^(cc0|public domain|pd)/i.test(c.lic)));
      if (cand.length >= 3) break;
    }
    const seen = {}; cand = cand.filter(c => !seen[c.title] && (seen[c.title] = 1)).sort((a, b) => (b.ii.width * b.ii.height) - (a.ii.width * a.ii.height)).slice(0, 4);
    let n = 0;
    for (const c of cand) { try { await sleep(900); const r = await fetch(c.ii.thumburl, UA); if (!r.ok) continue; n++; const f = slug + '-' + n + '.jpg'; fs.writeFileSync(OUT + '/' + f, Buffer.from(await r.arrayBuffer())); credits[f] = { license: c.lic, author: c.artist, source: c.ii.descriptionurl, title: c.title }; } catch (e) {} }
    console.log(slug + ': ' + n + ' saved');
  }
  fs.writeFileSync(OUT + '/credits12.json', JSON.stringify(credits, null, 1));
})();
NODE
git config user.name "github-actions"; git config user.email "actions@users.noreply.github.com"
git add sites/key-technologies/img/food-candidates10
git commit -m "Coffee candidate photos, round nine" -q && git push -q origin HEAD:claude/master-file-e6ofy0 && echo "committed and pushed"
