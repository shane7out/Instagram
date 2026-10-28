// Read-only second pass: search-result snippets for the restaurants still missing a handle, and a look at Instagram profile titles.
const UA = { 'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36', 'accept-language': 'en-US,en;q=0.9' };
const sleep = ms => new Promise(r => setTimeout(r, ms));
async function get(u, ms = 15000) { const c = new AbortController(); const t = setTimeout(() => c.abort(), ms); try { const r = await fetch(u, { headers: UA, signal: c.signal, redirect: 'follow' }); return { status: r.status, text: await r.text(), url: r.url }; } catch (e) { return { status: 0, text: '', err: String(e.message) }; } finally { clearTimeout(t); } }
const strip = h => h.replace(/<script[\s\S]*?<\/script>|<style[\s\S]*?<\/style>/gi, ' ').replace(/<[^>]+>/g, ' ').replace(/&amp;/g, '&').replace(/&#39;|&#x27;/g, "'").replace(/&quot;/g, '"').replace(/\s+/g, ' ');
const Q = [
 'Pizza Rock Las Vegas instagram', 'Metro Pizza Las Vegas all locations addresses', 'Yellowtail Bellagio Las Vegas instagram',
 'Lotus of Siam Las Vegas instagram', "Archi's Thai Kitchen Las Vegas locations addresses", 'Komol Thai Las Vegas instagram',
 'Kura Sushi Las Vegas Henderson locations addresses', 'Sushi Neko Las Vegas instagram', 'Burger Bar Hubert Keller Las Vegas instagram',
 'Lindo Michoacan Las Vegas all locations', 'Holsteins Shakes and Buns Las Vegas instagram', 'Smoking Pig BBQ Las Vegas instagram',
 'Doanburi Las Vegas instagram', "Vanilla Rice's Hibachi House Las Vegas instagram", 'Peru Chicken Las Vegas instagram', 'Poke Heaven Las Vegas instagram',
 'The Beach House Henderson restaurant instagram', "Ferraro's Ristorante Las Vegas instagram"
];
(async () => {
  for (const q of Q) {
    await sleep(10000);
    console.log('\n### ' + q);
    const r = await get('https://www.bing.com/search?q=' + encodeURIComponent(q) + '&setlang=en-US&cc=US');
    if (!r.text) { console.log('  no response ' + (r.err || r.status)); continue; }
    const blocks = [...r.text.matchAll(/<li class="b_algo"[\s\S]*?<\/li>/g)].map(m => m[0]).slice(0, 6);
    console.log('  status ' + r.status + ', results ' + blocks.length);
    for (const b of blocks) {
      const u = (b.match(/<a[^>]+href="(https?:[^"]+)"/) || [])[1] || '';
      console.log('  - ' + u.slice(0, 110) + ' :: ' + strip(b).slice(0, 260));
    }
    const igs = new Set(); for (const m of r.text.matchAll(/instagram\.com\/(?!p\/|reel|explore)([A-Za-z0-9._]{2,30})/gi)) igs.add(m[1]);
    console.log('  instagram handles on page: ' + ([...igs].join(', ') || 'none'));
  }
  console.log('\n### INSTAGRAM PROFILE TITLES');
  for (const h of ['ferraroslasvegas', 'ferraroslv', 'metropizzalv', 'holsteinslv', 'poke.heaven', 'the.irish.spot', 'hibachihouselv', 'smokingpigbbqlasvegas', 'doanburi', 'peruchickenofficial', 'thebeachhousevegas', 'lotusofsiam', 'pizzarocklv', 'sushirokulv']) {
    await sleep(3000);
    const p = await get('https://www.instagram.com/' + h + '/');
    const t = (p.text.match(/<title>([^<]*)<\/title>/) || [])[1] || '';
    const d = (p.text.match(/property="og:description" content="([^"]*)"/) || [])[1] || '';
    console.log('  ' + h + ' -> status ' + p.status + ' title: ' + t.slice(0, 100) + ' | ' + d.slice(0, 120));
  }
})();
