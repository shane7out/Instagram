#!/bin/bash
# Re-fetch the St Rita's photographs and downscale them with Pillow.
# (ubuntu-latest no longer ships ImageMagick, so the previous run's `convert`
#  failed and the originals were removed before anything was written.)
set +e
OUT=.github/db-task/fetched/st-ritas/img
mkdir -p "$OUT"
NOTES=.github/db-task/fetched/yt/assets.txt
: > "$NOTES"
UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36'
CDN=https://cdn.prod.website-files.com/697c3a303419b908ce7938f2

python3 -m pip install --quiet --disable-pip-version-check Pillow 2>&1 | tail -2 >> "$NOTES"

get () {
  C=$(curl -sL -A "$UA" -e https://www.stritaretreat.com/ --max-time 90 -o "$2" -w '%{http_code}' "$1")
  echo "fetch $C $(wc -c < "$2" 2>/dev/null || echo 0) $(basename "$2")" >> "$NOTES"
  [ "$C" = "200" ] || rm -f "$2"
}

get "$CDN/69aab17b281424604b23e5be_St-Rita_Home-OG_02-17-2026_crop-opt.jpg"               "$OUT/raw-hero.jpg"
get "$CDN/699531d439ba60222a37249c_St-Rita_Galllery-image_Statue_02-17-26-opt.jpg"        "$OUT/raw-statue.jpg"
get "$CDN/699531d439823a38b12f242b_St-Rita_Galllery-image_Entrance_02-17-26_opt.jpg"      "$OUT/raw-entrance.jpg"
get "$CDN/699531d4909ce9a6b8410cf9_St-Rita_Gallery-Image_Gathering_02-17-26_crop-opt.jpg" "$OUT/raw-gathering.jpg"
get "$CDN/699531d4f591a13a44df7568_St-Rita_Galllery-image_02-17-26_crop-opt.jpg"          "$OUT/raw-grounds.jpg"
get "$CDN/69ab36f761eb876af71a99df_St-Rita_Tile-Image_Group_02-17-26_crop-opt.jpg"        "$OUT/raw-group.jpg"
get "https://i.ytimg.com/vi/llcRsfSUhvs/sddefault.jpg"                                    "$OUT/raw-grotto.jpg"

python3 - "$OUT" <<'PY' >> "$NOTES" 2>&1
import sys,os,glob
from PIL import Image
out=sys.argv[1]
sizes={'hero':1700,'statue':1000,'entrance':1000,'gathering':1000,'grounds':1000,'group':1000,'grotto':900}
print("---- resized ----")
for f in sorted(glob.glob(os.path.join(out,'raw-*.jpg'))):
    name=os.path.basename(f)[4:-4]
    try:
        im=Image.open(f); im.load()
        # the YouTube frame is letterboxed 4:3 inside 640x480 with black bars - trim them
        if name=='grotto':
            im=im.crop((80,0,560,480))
        im=im.convert('RGB')
        w=sizes.get(name,1000)
        if im.width>w:
            im=im.resize((w,round(im.height*w/im.width)),Image.LANCZOS)
        dst=os.path.join(out,name+'.jpg')
        im.save(dst,'JPEG',quality=78,optimize=True,progressive=True)
        print(f"  {name:10s} {im.width}x{im.height}  {os.path.getsize(dst):,} bytes")
        os.remove(f)
    except Exception as e:
        print(f"  {name}: FAILED {e}")
PY

echo "---- final ----" >> "$NOTES"
ls -la "$OUT" >> "$NOTES"
du -sh "$OUT" >> "$NOTES"

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -A "$OUT" .github/db-task/fetched/yt
git commit -m "source material: St Rita's photographs, downscaled" || { echo "nothing to commit"; exit 0; }
for i in 1 2 3 4; do git push origin HEAD:claude/master-file-e6ofy0 && break; sleep $((i*3)); git pull --rebase origin claude/master-file-e6ofy0; done
cat "$NOTES"
