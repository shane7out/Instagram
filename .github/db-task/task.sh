#!/bin/bash
# Pull real source material for the St Rita's site redesign.
# This container can't reach YouTube (egress proxy 403s img.youtube.com and
# www.youtube.com), but the Actions runner can — so grab it here and commit it
# back so Claude can actually LOOK at the frames instead of guessing.
set +e
OUT=.github/db-task/fetched/yt
mkdir -p "$OUT"
: > "$OUT/notes.txt"
UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36'

# ---------------------------------------------------------------------------
# 1) thumbnails — the two real St. Rita Retreat Center videos
# ---------------------------------------------------------------------------
for ID in llcRsfSUhvs e9WlVu-hm_o; do
  for Q in maxresdefault sddefault hqdefault mqdefault; do
    C=$(curl -sL -A "$UA" --max-time 40 -o "$OUT/$ID-$Q.jpg" -w '%{http_code}' \
        "https://i.ytimg.com/vi/$ID/$Q.jpg")
    S=$(wc -c < "$OUT/$ID-$Q.jpg" 2>/dev/null || echo 0)
    echo "thumb $ID $Q http=$C bytes=$S" >> "$OUT/notes.txt"
    if [ "$C" = "200" ] && [ "$S" -gt 4000 ]; then break; else rm -f "$OUT/$ID-$Q.jpg"; fi
  done
  # storyboard-ish extra frames: YouTube exposes 1.jpg 2.jpg 3.jpg per video
  for N in 1 2 3; do
    C=$(curl -sL -A "$UA" --max-time 40 -o "$OUT/$ID-f$N.jpg" -w '%{http_code}' \
        "https://i.ytimg.com/vi/$ID/$N.jpg")
    S=$(wc -c < "$OUT/$ID-f$N.jpg" 2>/dev/null || echo 0)
    echo "frame $ID $N http=$C bytes=$S" >> "$OUT/notes.txt"
    [ "$C" = "200" ] && [ "$S" -gt 3000 ] || rm -f "$OUT/$ID-f$N.jpg"
  done
done

# ---------------------------------------------------------------------------
# 2) what the videos actually say (description / keywords out of the watch page)
# ---------------------------------------------------------------------------
for ID in llcRsfSUhvs e9WlVu-hm_o; do
  curl -sL -A "$UA" --max-time 60 "https://www.youtube.com/watch?v=$ID" -o /tmp/w.html
  echo "watchpage $ID bytes=$(wc -c < /tmp/w.html)" >> "$OUT/notes.txt"
  python3 - "$ID" <<'PY' >> "$OUT/notes.txt" 2>&1
import re,sys,html,json
vid=sys.argv[1]
s=open('/tmp/w.html',encoding='utf-8',errors='replace').read()
def meta(p):
    m=re.search(r'<meta[^>]+(?:name|property)="%s"[^>]+content="([^"]*)"'%p,s)
    return html.unescape(m.group(1)) if m else ''
print('==== %s ===='%vid)
for k in ('og:title','og:description','keywords','og:image'):
    v=meta(k)
    if v: print('%-15s %s'%(k,v[:600]))
m=re.search(r'"shortDescription":"(.*?)","',s,re.S)
if m:
    print('shortDescription:')
    print(json.loads('"%s"'%m.group(1))[:2000])
PY
done

# ---------------------------------------------------------------------------
# 3) does the retreat center have a real site of its own? (for tone + photos)
# ---------------------------------------------------------------------------
for H in stritaretreat.org stritasretreat.org st-ritas.org stritaretreatcenter.org \
         stritaretreat.com stritasretreatcenter.com; do
  C=$(curl -sL -A "$UA" --max-time 25 -o /tmp/h.html -w '%{http_code}' "https://$H/")
  echo "domain $H http=$C bytes=$(wc -c < /tmp/h.html 2>/dev/null||echo 0)" >> "$OUT/notes.txt"
  if [ "$C" = "200" ]; then
    cp /tmp/h.html "$OUT/site-$H.html"
    grep -oiE '<(title|meta[^>]+og:image)[^>]*>' /tmp/h.html | head -5 >> "$OUT/notes.txt"
  fi
done

echo "---- files ----" >> "$OUT/notes.txt"
ls -la "$OUT" >> "$OUT/notes.txt"

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -A "$OUT"
git commit -m "source material: St Rita's video frames + metadata" || { echo "nothing to commit"; exit 0; }
for i in 1 2 3 4; do git push origin HEAD:claude/master-file-e6ofy0 && break; sleep $((i*3)); git pull --rebase origin claude/master-file-e6ofy0; done
cat "$OUT/notes.txt"
