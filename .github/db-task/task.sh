#!/bin/bash
# Check the Private Table site status + the pill's href on the live dashboard.
set +e
echo "--- private-table-lv.web.app ---"
curl -s -o pt.html -w "status=%{http_code} size=%{size_download} final_url=%{url_effective}\n" -L "https://private-table-lv.web.app"
echo "title: $(grep -o '<title>[^<]*</title>' pt.html | head -1)"
head -c 200 pt.html; echo
echo "--- pill href on live dashboard ---"
curl -s "https://lvr-data-a60c1.web.app" -o dash.html
echo "dash size: $(wc -c < dash.html)"
grep -o '<a href="[^"]*private-table[^"]*"[^>]*>' dash.html | head -2
python3 - <<'PY'
t=open('dash.html',encoding='utf-8',errors='replace').read()
i=t.find('private-table')
print(repr(t[max(0,i-350):i+150]) if i>=0 else 'NO private-table link found')
PY
