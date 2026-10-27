#!/bin/bash
# Fetch higher-quality candidate food photos (Public Domain / CC0 only, large, from Wikimedia Commons) for review.
mkdir -p sites/key-technologies/img/food-candidates
node <<'NODE'
const fs = require('fs');
const OUT = 'sites/key-technologies/img/food-candidates';
const sleep = ms => new Promise(r => setTimeout(r, ms));
const UA = { headers: { 'User-Agent': 'KeyTechnologiesDemo/1.0 (contact via keytechnologies.si)' } };
const TERMS = {
  pizza: ['pizza Unsplash', 'margherita pizza', 'pepperoni pizza'], sushi: ['sushi Unsplash', 'salmon sushi nigiri'], teriyaki: ['chicken rice bowl', 'teriyaki Unsplash'],
  friedrice: ['fried rice Unsplash', 'fried rice shrimp'], garlic: ['garlic bread Unsplash', 'bread Unsplash cheese'], sundae: ['sundae Unsplash', 'ice cream Unsplash'],
  churros: ['churros Unsplash', 'churro'], gyoza: ['dumplings Unsplash', 'gyoza'], boba: ['bubble tea Unsplash', 'milk tea Unsplash'], poke: ['poke bowl Unsplash', 'salmon bowl Unsplash'],
  ribs: ['ribs Unsplash', 'barbecue Unsplash'], tacos: ['taco Unsplash', 'tacos food'], nachos: ['nachos food Unsplash', 'nachos plate'], salmon: ['salmon Unsplash', 'grilled salmon']
};
const strip = s => String(s || '').replace(/<[^>]*>/g, '').replace(/\s+/g, ' ').trim().slice(0, 120);
(async () => {
  const credits = {};
  for (const [slug, terms] of Object.entries(TERMS)) {
   let cand = [];
   for (const term of terms) {
    let j = null;
    for (let t = 0; t < 4 && !j; t++) {
      await sleep(3000 + t * 3000);
      try { const rr = await fetch('https://commons.wikimedia.org/w/api.php?action=query&format=json&generator=search&gsrnamespace=6&gsrlimit=40&gsrsearch=' + encodeURIComponent(term + ' Unsplash filetype:bitmap') + '&prop=imageinfo&iiprop=url|size|mime|extmetadata&iiurlwidth=800', UA); if (rr.ok) j = await rr.json(); } catch (e) {}
    }
    if (!j) { console.log(slug + ' / ' + term + ': search failed'); continue; }
    cand = cand.concat(Object.values((j.query && j.query.pages) || {}).map(p => { const ii = (p.imageinfo || [])[0]; if (!ii) return null; const m = ii.extmetadata || {}; return { title: p.title, ii, lic: (m.LicenseShortName || {}).value || '', artist: strip((m.Artist || {}).value) }; })
      .filter(c => c && c.ii.mime === 'image/jpeg' && c.ii.width >= 1200 && c.ii.height >= 800 && /^(cc0|public domain|pd)/i.test(c.lic)));
   }
   const seen = {}; cand = cand.filter(c => !seen[c.title] && (seen[c.title] = 1)).sort((a, b) => (b.ii.width * b.ii.height) - (a.ii.width * a.ii.height)).slice(0, 3);
    let n = 0;
    for (const c of cand) { try { await sleep(900); const r = await fetch(c.ii.thumburl, UA); if (!r.ok) continue; n++; const f = slug + '-' + n + '.jpg'; fs.writeFileSync(OUT + '/' + f, Buffer.from(await r.arrayBuffer())); credits[f] = { license: c.lic, author: c.artist, source: c.ii.descriptionurl, title: c.title }; } catch (e) {} }
    console.log(slug + ': ' + n + ' saved');
  }
  fs.writeFileSync(OUT + '/credits2.json', JSON.stringify(credits, null, 1));
})();
NODE
git config user.name "github-actions"; git config user.email "actions@users.noreply.github.com"
git add sites/key-technologies/img/food-candidates
git commit -m "Higher-quality candidate food photos for review" -q && git push -q origin HEAD:claude/master-file-e6ofy0 && echo "committed and pushed"
