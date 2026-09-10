#!/bin/bash
# First batch of suggested Instagram handles for Bad IG records.
#
# Every one of these was looked up and corroborated against the account itself
# plus a second source (the restaurant's own site, its Yelp listing, or the
# address matching the record). Nothing here is applied automatically - each
# lands in dashboard/igsuggest for the owner to accept or dismiss.
#
# Trap Wingz (50817) was searched and deliberately left out: only aggregator
# pages came back, no account that could be confirmed as theirs.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
TS=$(date -u +%s)

curl -s -X PATCH -H "Content-Type: application/json" "$DB/dashboard/igsuggest.json" -d "{
  \"50345\": {\"ig\":\"earthlyplantbased\",\"conf\":\"high\",\"ts\":$TS,
              \"note\":\"Stored handle was @eathlyplantbased - 'earthly' misspelled. 13K followers, bio says Town Square.\",
              \"src\":\"instagram.com/earthlyplantbased + tslv.com directory + earthlyincnv.com\"},

  \"50611\": {\"ig\":\"koreahouselv\",\"conf\":\"high\",\"ts\":$TS,
              \"note\":\"Stored handle was @korehouselv - missing the 'a' in Korea. 7815 S Rainbow Blvd.\",
              \"src\":\"instagram.com/koreahouselv + koreahouselv.com + Yelp\"},

  \"50278\": {\"ig\":\"teriyakimadnesslv\",\"conf\":\"high\",\"ts\":$TS,
              \"note\":\"Stored handle was @teriyaakimadnesslv - doubled 'a'. Account is tagged Las Vegas, NV.\",
              \"src\":\"instagram.com/teriyakimadnesslv + teriyakimadness.com locations\"},

  \"1479\":  {\"ig\":\"limalimonlasvegas\",\"conf\":\"high\",\"ts\":$TS,
              \"note\":\"Stored handle was @likalimonlasvegas - 'k' where an 'm' belongs. 222 S Decatur Blvd.\",
              \"src\":\"instagram.com/limalimonlasvegas + limalimonlasvegas.com + Yelp\"},

  \"50818\": {\"ig\":\"daikonvegansushi\",\"conf\":\"high\",\"ts\":$TS,
              \"note\":\"Record had no handle at all (Yelp migration). Own site daikonvegansushi.com confirms it.\",
              \"src\":\"instagram.com/daikonvegansushi + daikonvegansushi.com\"},

  \"50608\": {\"ig\":\"laflordemichoacanicecream_\",\"conf\":\"medium\",\"ts\":$TS,
              \"note\":\"Stored handle was cut off at 24 characters. Trailing underscore is part of it. Several near-identical accounts exist - worth a look before accepting.\",
              \"src\":\"instagram.com/laflordemichoacanicecream_ (alts: laflordemichlv, laflordemichoacan_icecream)\"},

  \"50206\": {\"ig\":\"backyardbbqvillage\",\"conf\":\"medium\",\"ts\":$TS,
              \"note\":\"Stored handle was @baackyardbbqvillage - doubled 'a'. The account lists Victorville CA, but it is a travelling concession that works NV/AZ/CO and Yelp has it at 115 E Reno Ave, Las Vegas.\",
              \"src\":\"instagram.com/backyardbbqvillage + Yelp Las Vegas listing\"}
}" > /dev/null

echo "== dashboard/igsuggest now =="
curl -s "$DB/dashboard/igsuggest.json" | jq -r 'to_entries[] | "  \(.key)  @\(.value.ig)  [\(.value.conf)]"' | sort
echo "count: $(curl -s "$DB/dashboard/igsuggest.json" | jq 'keys|length')"

echo ""
echo "== these are still flagged Bad IG, as expected until accepted =="
for N in 50345 50611 50278 1479 50818 50608 50206; do
  echo "  $N badig=$(curl -s "$DB/dashboard/badig/$N.json")  igovr=$(curl -s "$DB/dashboard/igovr/$N.json")"
done
