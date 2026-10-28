// Read-only: for each restaurant, find its official site, then read the Instagram link and addresses from it.
const NAMES = require('./names.json');
const BAD = /yelp\.|facebook\.|tripadvisor\.|opentable\.|instagram\.|doordash\.|ubereats\.|grubhub\.|mapquest\.|google\.|bing\.|duckduckgo\.|yellowpages|wikipedia|reddit\.|timeout\.|eater\.|reviewjournal|lasvegassun|vegas411|vegasinc|postmates|seamless|restaurantji|zomato|foursquare|trip\.com|tiktok|youtube|pinterest|twitter|x\.com|chamberofcommerce|nextdoor|resy\.|sevenrooms|toasttab|order\./i;
const UA = { 'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36', 'accept-language': 'en-US,en;q=0.9' };
async function get(u, ms = 15000) {
  const c = new AbortController(); const t = setTimeout(() => c.abort(), ms);
  try { const r = await fetch(u, { headers: UA, signal: c.signal, redirect: 'follow' }); return { url: r.url, status: r.status, text: await r.text() }; }
  catch (e) { return { url: u, status: 0, text: '', err: String(e.message || e) }; } finally { clearTimeout(t); }
}
function resultUrls(html) {
  const out = [];
  for (const m of html.matchAll(/uddg=([^"&]+)/g)) { try { out.push(decodeURIComponent(m[1])); } catch (e) {} }
  if (!out.length) for (const m of html.matchAll(/<a[^>]+href="(https?:\/\/[^"]+)"/g)) out.push(m[1]);
  return out;
}
function igHandles(html) {
  const s = new Set();
  for (const m of html.matchAll(/instagram\.com\/(?!p\/|reel|explore|sharer|accounts|about|developer|legal|share|tr\b)([A-Za-z0-9._]{2,30})/gi)) s.add(m[1].replace(/\.$/, ''));
  return [...s];
}
function addrs(html) {
  const txt = html.replace(/<script[\s\S]*?<\/script>|<style[\s\S]*?<\/style>/gi, ' ').replace(/<[^>]+>/g, ' ').replace(/&amp;/g, '&').replace(/&nbsp;/g, ' ').replace(/\s+/g, ' ');
  const out = new Set();
  for (const m of txt.matchAll(/(\d{2,5}\s+(?:[NSEW]\.?\s+)?[A-Za-z0-9.' -]{3,40}?(?:St|Street|Ave|Avenue|Blvd|Boulevard|Rd|Road|Dr|Drive|Pkwy|Parkway|Ln|Lane|Way|Ct|Hwy|Pl)\b[^,]{0,30},?\s*(?:Las Vegas|Henderson|North Las Vegas|Summerlin)[,\s]+(?:NV|Nevada)\s*\d{5})/gi)) out.add(m[1].trim());
  return [...out].slice(0, 12);
}
(async () => {
  for (const n of NAMES) {
    console.log('\n=== ' + n.name);
    const sites = [];
    let s = { status: 'skipped' };
    if (n.web) sites.push({ host: new URL(n.web).hostname, url: n.web });
    else {
      await new Promise(r => setTimeout(r, 9000));
      const q = (n.q || n.name) + ' Las Vegas NV official website';
      s = await get('https://html.duckduckgo.com/html/?q=' + encodeURIComponent(q));
      let urls = resultUrls(s.text);
      for (const u of urls) { try { const h = new URL(u); if (!BAD.test(h.hostname) && !sites.some(x => x.host === h.hostname)) sites.push({ host: h.hostname, url: u }); } catch (e) {} if (sites.length >= 2) break; }
    }
    if (!sites.length) { console.log('  no site found (search status ' + s.status + ')'); continue; }
    for (const site of sites.slice(0, 2)) {
      const home = await get(site.url);
      let all = home.text, extra = [];
      for (const m of home.text.matchAll(/href="([^"#]*(?:location|contact|visit|find-us|about)[^"#]*)"/gi)) { try { const u = new URL(m[1], home.url).href; if (new URL(u).hostname === new URL(home.url).hostname && !extra.includes(u)) extra.push(u); } catch (e) {} if (extra.length >= 3) break; }
      for (const u of extra) { const p = await get(u); all += '\n' + p.text; }
      console.log('  site: ' + home.url + ' (status ' + home.status + (home.err ? ', ' + home.err : '') + ')');
      console.log('  instagram: ' + (igHandles(all).join(', ') || 'none'));
      console.log('  addresses: ' + (addrs(all).join(' | ') || 'none'));
    }
  }
})();
