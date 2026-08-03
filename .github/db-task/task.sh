#!/bin/bash
# Worldwide Craigslist sweep: "batman 1966" across every CL region, filtered to trading cards.
# Results committed to .github/db-task/fetched/batman-1966-results.{json,md}
set -e
python3 - <<'PY'
import json, re, time, urllib.request, urllib.parse
from concurrent.futures import ThreadPoolExecutor, as_completed

UA = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36"}

def get(url, timeout=20):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()

areas = json.loads(get("https://reference.craigslist.org/Areas"))
print(f"areas: {len(areas)}")

Q = urllib.parse.quote("batman 1966")
def search(area):
    aid, host, desc, country = area["AreaID"], area["Hostname"], area["Description"], area["Country"]
    url = f"https://sapi.craigslist.org/web/v8/postings/search/full?batch={aid}-0-360-0-0&cc={country}&lang=en&query={Q}&searchPath=sss"
    try:
        d = json.loads(get(url)).get("data")
        if not isinstance(d, dict):
            return ("ERR", aid, host, "non-dict data")
    except Exception as e:
        return ("ERR", aid, host, str(e)[:80])
    dec = d.get("decode", {}) if isinstance(d.get("decode"), dict) else {}
    minid = dec.get("minPostingId", 0)
    locs = dec.get("locations", [])
    out = []
    for it in d.get("items", []):
        if not isinstance(it, list) or not it or not isinstance(it[0], int):
            continue
        pid = it[0] + minid if it[0] < 10**9 else it[0]
        title = it[-1] if isinstance(it[-1], str) else ""
        price, slug = "", ""
        for f in it:
            if isinstance(f, list) and f:
                if f[0] == 10 and len(f) > 1: price = f[1]
                elif f[0] == 6 and len(f) > 1: slug = f[1]
        h, sub = host, ""
        if len(it) > 4 and isinstance(it[4], str) and "~" in it[4]:
            try:
                li = int(it[4].split("~")[0].split(":")[1])
                ent = locs[li]
                if isinstance(ent, list) and len(ent) >= 2:
                    h = ent[1]
                    sub = ent[2] if len(ent) > 2 else ""
            except Exception:
                pass
        u = f"https://{h}.craigslist.org/{sub+'/' if sub else ''}sss/d/{slug}/{pid}.html" if slug else f"https://{h}.craigslist.org/sss/{pid}.html"
        out.append({"id": pid, "title": title, "price": price, "url": u, "area": desc, "country": country})
    return ("OK", aid, host, out)

results, errs = {}, 0
with ThreadPoolExecutor(max_workers=8) as ex:
    futs = [ex.submit(search, a) for a in areas]
    for i, f in enumerate(as_completed(futs)):
        try:
            st, aid, host, data = f.result()
        except Exception:
            errs += 1
            continue
        if st == "ERR":
            errs += 1
            continue
        for r in data:
            results.setdefault(r["id"], r)
        if (i + 1) % 100 == 0:
            print(f"  {i+1}/{len(areas)} areas done, {len(results)} unique so far, {errs} errors")

allhits = sorted(results.values(), key=lambda r: (r["country"], r["area"], r["title"]))
cards = [r for r in allhits if re.search(r"card|topps", r["title"], re.I)]
print(f"TOTAL unique batman-1966 hits: {len(allhits)}  |  card/topps matches: {len(cards)}  |  area errors: {errs}")
for r in cards:
    print(f"  CARD: [{r['country']}/{r['area']}] {r['price']:>7}  {r['title'][:70]}  {r['url']}")

with open(".github/db-task/fetched/batman-1966-results.json", "w") as f:
    json.dump({"query": "batman 1966", "unique_hits": len(allhits), "card_matches": len(cards),
               "errors": errs, "cards": cards, "all": allhits}, f, indent=1)
lines = ["# Batman 1966 trading cards — worldwide Craigslist sweep", "",
         f"- Unique 'batman 1966' listings: **{len(allhits)}**",
         f"- Card/Topps matches: **{len(cards)}**", f"- Regions with errors: {errs}", "", "## Card matches", ""]
for r in cards:
    lines.append(f"- **{r['price'] or 'no price'}** — [{r['title']}]({r['url']}) — {r['area']}, {r['country']}")
lines += ["", "## All other 'batman 1966' listings", ""]
for r in allhits:
    if r not in cards:
        lines.append(f"- {r['price'] or 'no price'} — [{r['title']}]({r['url']}) — {r['area']}, {r['country']}")
with open(".github/db-task/fetched/batman-1966-results.md", "w") as f:
    f.write("\n".join(lines))
PY
git config user.name "db-task"
git config user.email "actions@users.noreply.github.com"
git add .github/db-task/fetched/batman-1966-results.json .github/db-task/fetched/batman-1966-results.md
git commit -m "db-task: batman 1966 worldwide sweep results"
git push origin claude/master-file-e6ofy0
echo "results committed"
