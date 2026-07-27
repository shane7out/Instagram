#!/bin/bash
# Create the LV Experiences category node (dashboard_exp_crec) and add six
# experience businesses. Own num range (60001+) so it can never collide with
# restaurants (~50xxx) or advertisers. Mirrors the crec record schema.
set -e
DB="https://lvr-data-a60c1-default-rtdb.firebaseio.com"

curl -s "$DB/dashboard_exp_crec.json" -o exp.json
echo "existing dashboard_exp_crec: $(jq -r 'if .==null then "empty (new node)" else (keys|length|tostring)+" records" end' exp.json)"
for h in gunshiphelicopters skycombatace speedvegas adrenalinemountainlv stratvegas spherevegas; do
  if grep -qi "$h" exp.json; then
    echo "GUARD: $h already present - aborting with no writes"
    exit 1
  fi
done

cat > adds.json <<'JSON'
{
  "60001": {"name":"Gunship Helicopters","instagram":"@gunshiphelicopters","num":60001,"notes":"Shoot a machine gun from an open-door helicopter"},
  "60002": {"name":"Sky Combat Ace","instagram":"@skycombatace","num":60002,"notes":"Ride and fly a stunt plane over Red Rock Canyon"},
  "60003": {"name":"SPEEDVEGAS","instagram":"@speedvegas","num":60003,"notes":"Race supercars and a Baja truck on a racetrack course"},
  "60004": {"name":"Adrenaline Mountain","instagram":"@adrenalinemountainlv","num":60004,"notes":"UTVs, monster trucks, archery, shooting, flamethrower"},
  "60005": {"name":"The STRAT","instagram":"@stratvegas","num":60005,"notes":"Tower activities incl. the SkyJump vertical zip line"},
  "60006": {"name":"Sphere","instagram":"@spherevegas","num":60006,"notes":"Immersive shows and films at the Sphere"}
}
JSON

STATUS=$(curl -s -o resp.json -w "%{http_code}" -X PATCH -H "Content-Type: application/json" \
  -d @adds.json "$DB/dashboard_exp_crec.json")
echo "PATCH status: $STATUS"

curl -s "$DB/dashboard_exp_crec.json" -o exp2.json
echo "== LV Experiences now holds: $(jq 'keys|length' exp2.json) records =="
jq -r '.[] | "  - " + .name + " (" + .instagram + ")"' exp2.json
