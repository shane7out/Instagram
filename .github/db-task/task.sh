#!/bin/bash
# Remove the five genuine duplicates.
#
# Each pair is one restaurant sitting under two record numbers. The keeper is
# the copy that carries the Instagram handle and the richer fields; the other is
# a later Yelp-migration or manual re-add.
#
#   Area 15        keep 1263  (@area15official)   delete 50808 (bare re-add)
#   Shook Shakery  keep 1289  (@shookshakery)     delete 50801 (bare re-add)
#   CC Speakeasy   keep 1296  (@ccspeakeasylv)    delete 50809 (bare re-add)
#   Oodle Noodle   keep 1358  (@oodle_noodle_lv)  delete 50913 (empty IG, badIG)
#   VIVA!          keep 50465 (@eatdrinkviva)     delete 50867 (empty IG, badIG)
#
# Deletion uses dashboard/deleted, which is how the app itself removes records -
# every render path skips anything in that map. That keeps this reversible and
# avoids rewriting customrecords, which is a 1249-entry ARRAY where removing an
# element would shift every index after it. The badig flags on the two stubs are
# cleared at the same time so they stop showing up in the Bad IG list.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

BEFORE_DEL=$(curl -s "$DB/dashboard/deleted.json" | jq 'keys|length')
BEFORE_BAD=$(curl -s "$DB/dashboard/badig.json"   | jq 'keys|length')
echo "before: deleted=$BEFORE_DEL badig=$BEFORE_BAD"

# already gone?
for N in 50801 50808 50809 50913 50867; do
  V=$(curl -s "$DB/dashboard/deleted/$N.json")
  echo "  $N currently in deleted: $V"
done

curl -s -X PATCH -H "Content-Type: application/json" \
  -d '{"50801":1,"50808":1,"50809":1,"50913":1,"50867":1}' \
  "$DB/dashboard/deleted.json" > /dev/null

# the two stubs were flagged bad-IG; that flag is meaningless once deleted
curl -s -X PATCH -H "Content-Type: application/json" \
  -d '{"50913":null,"50867":null}' \
  "$DB/dashboard/badig.json" > /dev/null

AFTER_DEL=$(curl -s "$DB/dashboard/deleted.json" | jq 'keys|length')
AFTER_BAD=$(curl -s "$DB/dashboard/badig.json"   | jq 'keys|length')
echo "after : deleted=$AFTER_DEL (was $BEFORE_DEL)  badig=$AFTER_BAD (was $BEFORE_BAD)"

echo "-- verify each is tombstoned --"
for N in 50801 50808 50809 50913 50867; do
  echo "  $N -> $(curl -s "$DB/dashboard/deleted/$N.json")"
done
echo "-- verify the keepers are untouched --"
for N in 1263 1289 1296 1358 50465; do
  echo "  $N deleted? $(curl -s "$DB/dashboard/deleted/$N.json")  $(curl -s "$DB/dashboard_crec/$N.json" | jq -c '.name? // "not in crec"')"
done
