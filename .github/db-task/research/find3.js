// Read-only third pass: Instagram link context on a few official sites that were ambiguous or failed.
const UA = { 'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36', 'accept-language': 'en-US,en;q=0.9' };
async function get(u, ms = 30000) { const c = new AbortController(); const t = setTimeout(() => c.abort(), ms); try { const r = await fetch(u, { headers: UA, signal: c.signal, redirect: 'follow' }); return { status: r.status, text: await r.text(), url: r.url }; } catch (e) { return { status: 0, text: '', err: String(e.message) }; } finally { clearTimeout(t); } }
const U = [
 'https://www.ferraroslasvegas.com/', 'https://www.lotusofsiam.com/', 'https://lotusofsiam.com/locations', 'https://www.archithai.com/', 'https://archithai.com/locations',
 'https://www.doanburi.com/', 'https://www.pizzarock.com/', 'https://pizzarock.com/locations/', 'https://pizzarock.com/las-vegas/', 'https://bellagio.mgmresorts.com/en/restaurants/yellowtail-japanese-restaurant-lounge.html',
 'https://www.burgerbar.com/', 'https://hubertkeller.com/', 'https://www.metropizza.com/locations', 'https://www.metropizza.com/', 'https://komolthai.com/', 'https://www.settebello.net/locations',
 'https://www.smokingpigbbq.com/', 'https://www.holsteinsburgers.com/', 'https://holsteinsburgers.com/', 'https://www.kurasushi.com/', 'https://www.sushineko.com/', 'https://www.theirishspot.com/', 'https://vanillaricehibachi.com/contact', 'https://vanillaricehibachi.com/locations'
];
(async () => {
  for (const u of U) {
    const r = await get(u);
    console.log('\n## ' + u + ' -> ' + r.status + (r.err ? ' ' + r.err : '') + (r.url && r.url !== u ? ' (to ' + r.url + ')' : ''));
    if (!r.text) continue;
    const seen = new Set();
    for (const m of r.text.matchAll(/instagram\.com\/(?!p\/|reel|explore|sharer|accounts)([A-Za-z0-9._]{2,30})/gi)) {
      if (seen.has(m[1])) continue; seen.add(m[1]);
      const s = r.text.slice(Math.max(0, m.index - 90), m.index + 70).replace(/\s+/g, ' ');
      console.log('  IG ' + m[1] + '  ...' + s);
    }
    if (!seen.size) console.log('  no instagram link');
    const addr = new Set(); const txt = r.text.replace(/<script[\s\S]*?<\/script>|<style[\s\S]*?<\/style>/gi, ' ').replace(/<[^>]+>/g, ' ').replace(/&amp;/g, '&').replace(/\s+/g, ' ');
    for (const m of txt.matchAll(/(\d{2,5}\s+(?:[NSEW]\.?\s+)?[A-Za-z0-9.' -]{3,40}?(?:St|Street|Ave|Avenue|Blvd|Boulevard|Rd|Road|Dr|Drive|Pkwy|Parkway|Ln|Lane|Way|Hwy)\b[^,]{0,30},?\s*(?:Las Vegas|Henderson|North Las Vegas)[,\s]+(?:NV|Nevada)\s*\d{5})/gi)) addr.add(m[1]);
    if (addr.size) console.log('  addresses: ' + [...addr].slice(0, 8).join(' | '));
  }
})();
