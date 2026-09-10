#!/bin/bash
# Second batch of Instagram handle suggestions for Bad IG records.
#
# Two kinds here:
#   corrections  - the stored handle is wrong; a different one is right
#   confirmations - the stored handle is actually fine and the flag looks stale.
#                   Accepting one of these writes the same handle back and clears
#                   the Bad IG flag, which is the point.
#
# Every entry was corroborated against the account itself plus a second source
# (own website, Yelp listing, or a matching street address).
#
# Deliberately left out because nothing could be confirmed as theirs:
#   50080 Nevada Coffee Co   - only a Turkish account by that name
#   50075 Black Drop Coffee  - accounts in NJ, LA, Greece, Chile; none in Vegas
#   1286  Aisha Bites        - stored @sushabites matches nothing; no account found
#   1540  Sweet Stuff Girl   - nearest is @sweet_stuff_dessert_studio, name doesn't match
#   50078 Pour House Coffee  - the Vegas @pourcoffeehouse reads as closed; the other is Tri-State
#   50079 Brew Bar LV        - no such account; @brewteabar is a different business
#   50817 Trap Wingz         - aggregator pages only
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"
TS=$(date -u +%s)

curl -s -X PATCH -H "Content-Type: application/json" "$DB/dashboard/igsuggest.json" -d "{
  \"50074\": {\"ig\":\"sambalatte\",\"conf\":\"high\",\"ts\":$TS,
    \"note\":\"Stored @sambalattelv. The roastery's account is just @sambalatte - 6.7K followers, 750 S Rampart Blvd.\",
    \"src\":\"instagram.com/sambalatte + sambalatte.com\"},

  \"1577\": {\"ig\":\"potonfire_lasvegas\",\"conf\":\"high\",\"ts\":$TS,
    \"note\":\"Stored @potonfirelasvegas - missing the underscore. Vegas branch of a Chino/Eastvale group, 4355 W Spring Mountain Rd.\",
    \"src\":\"instagram.com/potonfire_lasvegas + thepotonfire.com + Yelp\"},

  \"50315\": {\"ig\":\"sonrisagrill.lv\",\"conf\":\"high\",\"ts\":$TS,
    \"note\":\"Stored @sonrisagrill.nv - it is .lv. 1.6K followers, 30 Via Brianza, Lake Las Vegas.\",
    \"src\":\"instagram.com/sonrisagrill.lv + sonrisagrill.com\"},

  \"50204\": {\"ig\":\"whiskfulthinkingcakeslv\",\"conf\":\"high\",\"ts\":$TS,
    \"note\":\"Stored @whiskfulthinkingcakes - the real one ends in lv. 21K followers, 5035 S Fort Apache.\",
    \"src\":\"instagram.com/whiskfulthinkingcakeslv + whiskfulthinkingcakes.com + Yelp\"},

  \"50125\": {\"ig\":\"nanas_house_of_soul_food_\",\"conf\":\"high\",\"ts\":$TS,
    \"note\":\"Stored handle is missing the trailing underscore. Easy one to lose.\",
    \"src\":\"instagram.com/nanas_house_of_soul_food_\"},

  \"1304\": {\"ig\":\"barrilelparce\",\"conf\":\"high\",\"ts\":$TS,
    \"note\":\"Stored @barrileparce - it is barril, with the second l. Colombian, 1927 N Decatur Blvd. Record name says Barrel; the business spells it Barril.\",
    \"src\":\"instagram.com/barrilelparce + barrilelparce.godaddysites.com + Yelp\"},

  \"50360\": {\"ig\":\"aguas_el_chavo\",\"conf\":\"high\",\"ts\":$TS,
    \"note\":\"Stored @aguas_el_chaavo - doubled a. Bio matches the record name exactly, 3.8K followers, Santa Ana CA + Las Vegas.\",
    \"src\":\"instagram.com/aguas_el_chavo\"},

  \"50395\": {\"ig\":\"eatsnooze\",\"conf\":\"high\",\"ts\":$TS,
    \"note\":\"Already correct - @eatsnooze is the live brand account, 166K followers, and both Vegas locations sit under it. The Bad IG flag looks stale; accepting clears it.\",
    \"src\":\"instagram.com/eatsnooze + snoozeeatery.com Nevada locations\"},

  \"50745\": {\"ig\":\"domdemarcos\",\"conf\":\"high\",\"ts\":$TS,
    \"note\":\"Already correct - 4K followers, 1,372 posts, matches domdemarcos.com. Flag looks stale.\",
    \"src\":\"instagram.com/domdemarcos + domdemarcos.com\"},

  \"1357\": {\"ig\":\"mollytea_lv\",\"conf\":\"high\",\"ts\":$TS,
    \"note\":\"Already correct - tagged Las Vegas, 3400 S Jones Blvd. Flag looks stale.\",
    \"src\":\"instagram.com/mollytea_lv + Yelp\"},

  \"50221\": {\"ig\":\"bowltasticfood\",\"conf\":\"high\",\"ts\":$TS,
    \"note\":\"Already correct - tagged Las Vegas, bio says LV Ballpark Section 107. Small account, 174 followers, which may be why it got flagged.\",
    \"src\":\"instagram.com/bowltasticfood\"},

  \"1272\": {\"ig\":\"peruchi_lv\",\"conf\":\"high\",\"ts\":$TS,
    \"note\":\"Already correct - PERU-CHI, hibachi with a Peruvian twist, serves the 702 Fri-Sun. Flag looks stale.\",
    \"src\":\"instagram.com/peruchi_lv\"},

  \"1451\": {\"ig\":\"tikibaroceandrive\",\"conf\":\"medium\",\"ts\":$TS,
    \"note\":\"Already correct as a handle - the account exists, 384 followers. Worth a glance though: the bio reads 'Ocean Drive', which is not obviously a Las Vegas address.\",
    \"src\":\"instagram.com/tikibaroceandrive\"},

  \"1453\": {\"ig\":\"sushimon.maryland\",\"conf\":\"high\",\"ts\":$TS,
    \"note\":\"Already correct - 1.1K followers, 9770 S Maryland Pkwy. An @sushimon_maryland also exists with an underscore; the dot one is the active AYCE account.\",
    \"src\":\"instagram.com/sushimon.maryland + monrestaurantgroup.com + Yelp\"},

  \"1185\": {\"ig\":\"bobacafe.lv\",\"conf\":\"high\",\"ts\":$TS,
    \"note\":\"Already correct - 11K followers, 5625 S Rainbow Blvd. Flag looks stale.\",
    \"src\":\"instagram.com/bobacafe.lv\"},

  \"1352\": {\"ig\":\"picanha_lv\",\"conf\":\"medium\",\"ts\":$TS,
    \"note\":\"Already correct and tagged Las Vegas. Their bigger account is @picanhasteakrestaurant (17K, 7480 S Rainbow) if you would rather point at that one.\",
    \"src\":\"instagram.com/picanha_lv + picanhasteakrestaurant.com + Yelp\"},

  \"1198\": {\"ig\":\"chefsromakitchenlv\",\"conf\":\"high\",\"ts\":$TS,
    \"note\":\"Already correct - matches chefsromakitchen.com, two locations, Southern Highlands and Henderson. Flag looks stale.\",
    \"src\":\"instagram.com/chefsromakitchenlv + chefsromakitchen.com\"},

  \"1172\": {\"ig\":\"nellieslivelv\",\"conf\":\"high\",\"ts\":$TS,
    \"note\":\"Already correct - Nellie's Live!, a Jonas family restaurant. Note the older Nellie's Southern Kitchen on the Strip shows as closed on Yelp, so this is the current concept.\",
    \"src\":\"instagram.com/nellieslivelv + nelliessouthernkitchen.com\"}
}" > /dev/null

echo "== dashboard/igsuggest =="
curl -s "$DB/dashboard/igsuggest.json" | jq -r 'to_entries|sort_by(.key)[]|"  \(.key)  @\(.value.ig)  [\(.value.conf)]"'
echo "total suggestions: $(curl -s "$DB/dashboard/igsuggest.json" | jq 'keys|length')"
echo "badig still flagged: $(curl -s "$DB/dashboard/badig.json" | jq 'keys|length')"
