#!/bin/bash
# Verify candidate YouTube video IDs are real + get their true titles/authors (oEmbed).
set -e
for ID in e9WlVu-hm_o llcRsfSUhvs nfnbRgeicSw PoAc9_pkr5I xiQWVlvHUhA 3a77VqrGoFM CcopJ09DaBY iMdkibxOuTg; do
  CODE=$(curl -s -o /tmp/o.json -w '%{http_code}' --max-time 20 \
    "https://www.youtube.com/oembed?url=https%3A//www.youtube.com/watch%3Fv%3D${ID}&format=json")
  if [ "$CODE" = "200" ]; then
    python3 -c "
import json;d=json.load(open('/tmp/o.json'))
print('OK   $ID | ' + d.get('title','?') + ' | by ' + d.get('author_name','?'))
"
  else
    echo "DEAD $ID (http $CODE)"
  fi
done
