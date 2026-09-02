#!/bin/bash
# Pull St Rita's real brand assets + photos from their live site (stritaretreat.com)
# and the statue frame from their YouTube video. This container is egress-blocked
# from both, so the runner does it and commits the files back.
set +e
OUT=.github/db-task/fetched/st-ritas/img
mkdir -p "$OUT"
NOTES=.github/db-task/fetched/yt/assets.txt
: > "$NOTES"
UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36'
CDN=https://cdn.prod.website-files.com/697c3a303419b908ce7938f2

get () {  # get <url> <outfile>
  C=$(curl -sL -A "$UA" -e https://www.stritaretreat.com/ --max-time 90 -o "$2" -w '%{http_code}' "$1")
  echo "$C  $(wc -c < "$2" 2>/dev/null || echo 0)  $2" >> "$NOTES"
  [ "$C" = "200" ] || rm -f "$2"
}

# --- brand: the rose (St Rita's own emblem) ---
get "$CDN/69ab54636501e61d751efd45_St-Rita-Rose_Parchment.svg" "$OUT/rose-parchment.svg"
get "$CDN/69ab50deaf9a2b26ec41fa3e_St-Rita-Rose-Blue.svg"      "$OUT/rose-blue.svg"
get "$CDN/69aac177ead73bdd4af4d8e5_st_ritas_white_rose_favicon_32.png" "$OUT/rose-32.png"

# --- photographs of the actual place ---
get "$CDN/69aab17b281424604b23e5be_St-Rita_Home-OG_02-17-2026_crop-opt.jpg"          "$OUT/raw-hero.jpg"
get "$CDN/699531d439ba60222a37249c_St-Rita_Galllery-image_Statue_02-17-26-opt.jpg"   "$OUT/raw-statue.jpg"
get "$CDN/699531d439823a38b12f242b_St-Rita_Galllery-image_Entrance_02-17-26_opt.jpg" "$OUT/raw-entrance.jpg"
get "$CDN/699531d4909ce9a6b8410cf9_St-Rita_Gallery-Image_Gathering_02-17-26_crop-opt.jpg" "$OUT/raw-gathering.jpg"
get "$CDN/699531d4f591a13a44df7568_St-Rita_Galllery-image_02-17-26_crop-opt.jpg"     "$OUT/raw-grounds.jpg"
get "$CDN/69ab36f761eb876af71a99df_St-Rita_Tile-Image_Group_02-17-26_crop-opt.jpg"   "$OUT/raw-group.jpg"

# --- the statue-at-the-grotto frame from their YouTube video ---
get "https://i.ytimg.com/vi/llcRsfSUhvs/sddefault.jpg" "$OUT/raw-grotto.jpg"

# --- downscale + recompress so they can be inlined in a single-file page ---
echo "---- resized ----" >> "$NOTES"
for f in "$OUT"/raw-*.jpg; do
  [ -f "$f" ] || continue
  b=$(basename "$f" .jpg); b=${b#raw-}
  if [ "$b" = "hero" ]; then W=1800; Q=76; else W=900; Q=74; fi
  convert "$f" -auto-orient -resize "${W}x>" -strip -interlace Plane -quality $Q "$OUT/$b.jpg" 2>>"$NOTES"
  echo "$b  $(identify -format '%wx%h' "$OUT/$b.jpg" 2>/dev/null)  $(wc -c < "$OUT/$b.jpg" 2>/dev/null) bytes" >> "$NOTES"
  rm -f "$f"
done

echo "---- rose svg head ----" >> "$NOTES"
head -c 700 "$OUT/rose-parchment.svg" >> "$NOTES" 2>/dev/null; echo >> "$NOTES"

# --- their real page copy, for accuracy (not to be copied verbatim) ---
for P in about stays-and-retreats availability contact faqs; do
  curl -sL -A "$UA" --max-time 60 "https://www.stritaretreat.com/$P" \
    -o ".github/db-task/fetched/yt/page-$P.html"
  echo "page $P $(wc -c < ".github/db-task/fetched/yt/page-$P.html") bytes" >> "$NOTES"
done

ls -la "$OUT" >> "$NOTES"

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -A "$OUT" .github/db-task/fetched/yt
git commit -m "source material: St Rita's brand rose, real photos, page copy" || { echo "nothing to commit"; exit 0; }
for i in 1 2 3 4; do git push origin HEAD:claude/master-file-e6ofy0 && break; sleep $((i*3)); git pull --rebase origin claude/master-file-e6ofy0; done
cat "$NOTES"
