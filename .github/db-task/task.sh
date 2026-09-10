#!/bin/bash
# Probe before sweeping: can the runner (a) find a restaurant's Instagram from a
# search engine, (b) find its website and scrape the handle off it, and
# (c) tell a real Instagram profile from a dead one? Verification is the whole
# game - a suggestion nobody checked is worse than no suggestion.
set +e
OUT=.github/db-task/fetched
mkdir -p "$OUT"
NOTES="$OUT/ig-probe.txt"
: > "$NOTES"
UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36'

# ---- (c) first: what does a real vs a fake profile look like? ---------------
echo "==== instagram profile fingerprinting ====" >> "$NOTES"
for H in herbsandrye nobu pinkboxdoughnuts zzzz_definitely_not_a_real_handle_9911 qqqq_nope_8842; do
  CODE=$(curl -sL -A "$UA" --max-time 45 -o /tmp/ig.html -w '%{http_code}' "https://www.instagram.com/$H/")
  SZ=$(wc -c < /tmp/ig.html 2>/dev/null || echo 0)
  OGT=$(grep -o '<meta property="og:title" content="[^"]*"' /tmp/ig.html 2>/dev/null | head -1 | sed 's/.*content="//;s/"$//')
  OGD=$(grep -o '<meta property="og:description" content="[^"]*"' /tmp/ig.html 2>/dev/null | head -1 | sed 's/.*content="//;s/"$//' | cut -c1-90)
  NF=$(grep -c "Page Not Found\|isn't available\|Sorry, this page" /tmp/ig.html 2>/dev/null)
  echo "  @$H  http=$CODE bytes=$SZ notfound_markers=$NF" >> "$NOTES"
  echo "      og:title = ${OGT:-<none>}" >> "$NOTES"
  echo "      og:desc  = ${OGD:-<none>}" >> "$NOTES"
done

# ---- (a) search-engine extraction ------------------------------------------
echo "" >> "$NOTES"
echo "==== bing: instagram handles + website, for real bad-IG records ====" >> "$NOTES"
probe_name () {
  NAME="$1"
  Q=$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote_plus(sys.argv[1]))" "$NAME Las Vegas instagram")
  curl -sL -A "$UA" --max-time 45 -o /tmp/b.html "https://www.bing.com/search?q=$Q"
  echo "  --- $NAME (bing $(wc -c </tmp/b.html) bytes) ---" >> "$NOTES"
  python3 - "$NAME" >> "$NOTES" 2>&1 <<'PY'
import re,sys,html,collections
s=open('/tmp/b.html',encoding='utf-8',errors='replace').read()
s=html.unescape(s)
hs=re.findall(r'instagram\.com/([A-Za-z0-9._]{2,30})', s)
skip={'p','reel','reels','explore','accounts','stories','tv','directory','about','legal','developer','privacy'}
c=collections.Counter(h.lower().rstrip('.') for h in hs if h.lower() not in skip)
print("      ig candidates:", c.most_common(5) or "none")
# a plausible official website: skip the aggregators
sites=re.findall(r'https?://([a-z0-9.-]+\.[a-z]{2,})/?', s.lower())
bad=('bing.com','microsoft.com','msn.com','instagram.com','facebook.com','yelp.com','tripadvisor',
     'doordash','ubereats','grubhub','opentable','youtube.com','google.','wikipedia','x.com','twitter',
     'linkedin','pinterest','tiktok','zomato','allmenus','menupix','restaurantji','mapquest','yellowpages')
cand=[d for d in dict.fromkeys(sites) if not any(b in d for b in bad)]
print("      website candidates:", cand[:5] or "none")
PY
}
probe_name "Trap Wingz"
probe_name "Daikon Vegan Sushi"
probe_name "McMullans Irish Pub"
probe_name "Scarpetta"
probe_name "The Sand Dollar Downtown"
probe_name "Backyard Bbq Village"

# ---- (b) scrape a real restaurant site for its own IG link -----------------
echo "" >> "$NOTES"
echo "==== scraping a website for its instagram link ====" >> "$NOTES"
for SITE in https://www.sanddollarlv.com/ https://mcmullansirishpub.com/ https://herbsandrye.com/; do
  CODE=$(curl -sL -A "$UA" --max-time 45 -o /tmp/w.html -w '%{http_code}' "$SITE")
  H=$(grep -o 'instagram\.com/[A-Za-z0-9._]\{2,30\}' /tmp/w.html 2>/dev/null | head -3 | tr '\n' ' ')
  echo "  $SITE http=$CODE bytes=$(wc -c </tmp/w.html 2>/dev/null||echo 0) -> ${H:-no ig link found}" >> "$NOTES"
done

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -A "$OUT"
git commit -m "probe: can the runner find and verify instagram handles" || { echo "nothing to commit"; exit 0; }
for i in 1 2 3 4; do git push origin HEAD:claude/master-file-e6ofy0 && break; sleep $((i*3)); git pull --rebase origin claude/master-file-e6ofy0; done
cat "$NOTES"
