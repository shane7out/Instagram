#!/bin/bash
# Fetch higher-quality candidate food photos (Public Domain / CC0 only, large, from Wikimedia Commons) for review.
mkdir -p sites/key-technologies/img/food-candidates
node <<'NODE'
const fs = require('fs');
const OUT = 'sites/key-technologies/img/food-candidates';
const sleep = ms => new Promise(r => setTimeout(r, ms));
const UA = { headers: { 'User-Agent': 'KeyTechnologiesDemo/1.0 (contact via keytechnologies.si)' } };
const TERMS = {
  teriyaki: 'teriyaki chicken rice bowl', friedrice: 'shrimp fried rice', salmon: 'salmon rice bowl', garlic: 'garlic bread', sundae: 'ice cream sundae',
  pizza: 'pepperoni pizza', churros: 'churros', tacos: 'tacos', nachos: 'nachos', boba: 'bubble tea', gyoza: 'gyoza dumplings', ramen: 'ramen',
  poke: 'poke bowl', pancakes: 'pancakes', burger: 'burger', coffee: 'cappuccino latte', icedtea: 'iced tea', ribs: 'bbq ribs', panini: 'panini sandwich', sushi: 'sushi nigiri'
};
const strip = s => String(s || '').replace(/<[^>]*>/g, '').replace(/\s+/g, ' ').trim().slice(0, 120);
(async () => {
  const credits = {};
  for (const [slug, term] of Object.entries(TERMS)) {
    let j = null;
    for (let t = 0; t < 4 && !j; t++) {
      await sleep(3000 + t * 3000);
      try { const rr = await fetch('https://commons.wikimedia.org/w/api.php?action=query&format=json&generator=search&gsrnamespace=6&gsrlimit=40&gsrsearch=' + encodeURIComponent(term + ' Unsplash filetype:bitmap') + '&prop=imageinfo&iiprop=url|size|mime|extmetadata&iiurlwidth=800', UA); if (rr.ok) j = await rr.json(); } catch (e) {}
    }
    if (!j) { console.log(slug + ': search failed'); continue; }
    const cand = Object.values((j.query && j.query.pages) || {}).map(p => { const ii = (p.imageinfo || [])[0]; if (!ii) return null; const m = ii.extmetadata || {}; return { title: p.title, ii, lic: (m.LicenseShortName || {}).value || '', artist: strip((m.Artist || {}).value) }; })
      .filter(c => c && c.ii.mime === 'image/jpeg' && c.ii.width >= 1500 && c.ii.height >= 1000 && /^(cc0|public domain|pd)/i.test(c.lic))
      .sort((a, b) => (b.ii.width * b.ii.height) - (a.ii.width * a.ii.height)).slice(0, 3);
    let n = 0;
    for (const c of cand) { try { await sleep(900); const r = await fetch(c.ii.thumburl, UA); if (!r.ok) continue; n++; const f = slug + '-' + n + '.jpg'; fs.writeFileSync(OUT + '/' + f, Buffer.from(await r.arrayBuffer())); credits[f] = { license: c.lic, author: c.artist, source: c.ii.descriptionurl, title: c.title }; } catch (e) {} }
    console.log(slug + ': ' + n + ' saved');
  }
  fs.writeFileSync(OUT + '/credits.json', JSON.stringify(credits, null, 1));
})();
NODE
git config user.name "github-actions"; git config user.email "actions@users.noreply.github.com"
git add sites/key-technologies/img/food-candidates
git commit -m "Higher-quality candidate food photos for review" -q && git push -q origin HEAD:claude/master-file-e6ofy0 && echo "committed and pushed"
