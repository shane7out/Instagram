#!/bin/bash
# Fetch poster frames for the five embedded videos so the video cards have a real
# still behind the play button (and so they survive being inlined in one file).
set +e
OUT=.github/db-task/fetched/st-ritas/img/poster
mkdir -p "$OUT"
NOTES=.github/db-task/fetched/yt/posters.txt
: > "$NOTES"
UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36'

python3 -m pip install --quiet --disable-pip-version-check Pillow 2>&1 | tail -1 >> "$NOTES"

for ID in llcRsfSUhvs e9WlVu-hm_o xiQWVlvHUhA nfnbRgeicSw PoAc9_pkr5I; do
  for Q in maxresdefault sddefault hqdefault; do
    C=$(curl -sL -A "$UA" --max-time 60 -o "$OUT/raw-$ID.jpg" -w '%{http_code}' \
        "https://i.ytimg.com/vi/$ID/$Q.jpg")
    S=$(wc -c < "$OUT/raw-$ID.jpg" 2>/dev/null || echo 0)
    echo "$ID $Q http=$C bytes=$S" >> "$NOTES"
    if [ "$C" = "200" ] && [ "$S" -gt 5000 ]; then break; else rm -f "$OUT/raw-$ID.jpg"; fi
  done
done

python3 - "$OUT" <<'PY' >> "$NOTES" 2>&1
import sys,os,glob
from PIL import Image
out=sys.argv[1]
print("---- posters ----")
for f in sorted(glob.glob(os.path.join(out,'raw-*.jpg'))):
    vid=os.path.basename(f)[4:-4]
    try:
        im=Image.open(f); im.load(); im=im.convert('RGB')
        w,h=im.size
        # sddefault/hqdefault are 4:3 with black bars top+bottom - crop to the 16:9 middle
        want=w*9/16
        if h>want+6:
            top=round((h-want)/2); im=im.crop((0,top,w,top+round(want)))
        if im.width>720:
            im=im.resize((720,round(im.height*720/im.width)),Image.LANCZOS)
        dst=os.path.join(out,vid+'.jpg')
        im.save(dst,'JPEG',quality=74,optimize=True,progressive=True)
        print(f"  {vid}  {im.width}x{im.height}  {os.path.getsize(dst):,} bytes")
        os.remove(f)
    except Exception as e:
        print(f"  {vid}: FAILED {e}")
PY

ls -la "$OUT" >> "$NOTES"

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -A "$OUT" .github/db-task/fetched/yt
git commit -m "source material: video poster frames" || { echo "nothing to commit"; exit 0; }
for i in 1 2 3 4; do git push origin HEAD:claude/master-file-e6ofy0 && break; sleep $((i*3)); git pull --rebase origin claude/master-file-e6ofy0; done
cat "$NOTES"
