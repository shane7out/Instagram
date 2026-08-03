#!/bin/bash
# Check live status: Private Table site + Batman tab on the Deals site.
set +e
echo "PRIVATE TABLE: $(curl -s -o pt.html -w '%{http_code}' -L https://private-table-lv.web.app) $(grep -o '<title>[^<]*</title>' pt.html | head -1)"
curl -s https://classiccarsforsale-co.web.app/ -o d.html
curl -s https://classiccarsforsale-co.web.app/cars.json -o cars.json
echo "DEALS chip-batman: $(grep -c chip-batman d.html)"
echo "DEALS cars.json batman entries: $(grep -c clbm cars.json)"
