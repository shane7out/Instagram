#!/bin/bash
# Fetch candidate food photos that are Public Domain / CC0 / CC BY / CC BY-SA from Wikimedia Commons,
# save 800px copies plus a credits file, and commit them so they can be reviewed.
set -e
mkdir -p sites/key-technologies/img/food-candidates
node <<'NODE'
const fs = require('fs');
const OUT = 'sites/key-technologies/img/food-candidates';
const TERMS = {
  chickenbowl: 'chicken rice bowl', teriyaki: 'teriyaki chicken', poke: 'poke bowl', pizza: 'pepperoni pizza', tacos: 'tacos',
  nachos: 'nachos', ramen: 'ramen', gyoza: 'gyoza', friedrice: 'fried rice', boba: 'bubble tea', sundae: 'ice cream sundae',
  churros: 'churros', garlicbread: 'garlic bread', sushi: 'salmon sushi', hibachi: 'hibachi', icedtea: 'iced tea glass',
  bbq: 'barbecue ribs', burger: 'cheeseburger', sandwich: 'deli sandwich', pancakes: 'pancakes breakfast'
};
const OKLIC = /^(cc0|public domain|pd|cc[ -]by(-sa)?[ -]?[0-9.]*)/i;
const rank = l => /^(cc0|public domain|pd)/i.test(l) ? 0 : /^cc[ -]by[ -]?[0-9.]*$/i.test(l) ? 1 : 2;
const strip = s => String(s || '').replace(/<[^>]*>/g, '').replace(/\s+/g, ' ').trim().slice(0, 140);
(async () => {
  const credits = {};
  for (const [slug, term] of Object.entries(TERMS)) {
    const url = 'https://commons.wikimedia.org/w/api.php?action=query&format=json&generator=search&gsrnamespace=6&gsrlimit=30&gsrsearch=' + encodeURIComponent(term + ' filetype:bitmap') + '&prop=imageinfo&iiprop=url|size|mime|extmetadata&iiurlwidth=800';
    let j; try { j = await (await fetch(url, { headers: { 'User-Agent': 'KeyTechnologiesDemo/1.0 (contact via keytechnologies.si)' } })).json(); } catch (e) { console.log(slug + ': search failed'); continue; }
    const pages = Object.values((j.query && j.query.pages) || {});
    const cand = pages.map(p => { const ii = (p.imageinfo || [])[0]; if (!ii) return null; const m = ii.extmetadata || {}; const lic = (m.LicenseShortName || {}).value || ''; return { title: p.title, ii, lic, artist: strip((m.Artist || {}).value), desc: strip((m.ImageDescription || {}).value) }; })
      .filter(c => c && c.ii.mime === 'image/jpeg' && c.ii.width >= 1000 && c.ii.height >= 700 && OKLIC.test(c.lic))
      .sort((a, b) => rank(a.lic) - rank(b.lic) || (b.ii.width * b.ii.height) - (a.ii.width * a.ii.height)).slice(0, 3);
    let n = 0;
    for (const c of cand) {
      try {
        const r = await fetch(c.ii.thumburl, { headers: { 'User-Agent': 'KeyTechnologiesDemo/1.0 (contact via keytechnologies.si)' } });
        if (!r.ok) continue;
        const buf = Buffer.from(await r.arrayBuffer()); n++;
        const f = slug + '-' + n + '.jpg'; fs.writeFileSync(OUT + '/' + f, buf);
        credits[f] = { term, title: c.title, license: c.lic, author: c.artist, source: c.ii.descriptionurl, note: c.desc.slice(0, 90) };
      } catch (e) {}
    }
    console.log(slug + ': ' + n + ' saved');
  }
  fs.writeFileSync(OUT + '/credits.json', JSON.stringify(credits, null, 1));
})();
NODE
du -sh sites/key-technologies/img/food-candidates | tail -1
git config user.name "github-actions"; git config user.email "actions@users.noreply.github.com"
git add sites/key-technologies/img/food-candidates
git commit -m "Candidate food photos (freely licensed, from Wikimedia Commons) for review" -q && git push -q origin HEAD:claude/master-file-e6ofy0 && echo "committed and pushed"
