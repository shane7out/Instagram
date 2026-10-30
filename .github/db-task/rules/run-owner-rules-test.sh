#!/bin/bash
# Test the STAGED owner-only LVR rules (lvr-rules-owner.json) in the Firebase
# Realtime Database emulator (nothing touches the real database).
# Independent of run-rules-test.sh; it does not run the live page-view check.
#
# The staged rules contain the literal placeholder __OWNER_UID__ (the deploy
# script substitutes the real owner uid). Here it is replaced with TESTOWNER,
# the uid that test-owner-rules.js puts into its unsigned test tokens.
set -e
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK=/tmp/rules-owner-test
rm -rf "$WORK"; mkdir -p "$WORK"; cd "$WORK"
cp "$HERE/lvr-rules-owner.json" .
cp "$HERE/test-extra-rules.json" .
cp "$HERE/test-owner-rules.js" .
cp "$HERE/../decay/monthly-decay.js" .

# Assemble a full ruleset: the staged fragment (placeholder -> TESTOWNER) + the live
# catch-all ($rest, copied exactly) + a stand-in for the pet game's locked-down node.
node -e '
const fs=require("fs");
const raw=fs.readFileSync("lvr-rules-owner.json","utf8");
if(!raw.includes("__OWNER_UID__")){console.error("placeholder __OWNER_UID__ not found in the staged rules");process.exit(3);}
const sub=raw.split("__OWNER_UID__").join("TESTOWNER");
if(sub.includes("__OWNER_UID__")){console.error("placeholder left over");process.exit(3);}
const a=JSON.parse(sub);
const b=JSON.parse(fs.readFileSync("test-extra-rules.json","utf8"));
fs.writeFileSync("database.rules.json",JSON.stringify({rules:Object.assign({},a,b)},null,1));
'
cat > firebase.json <<'JSON'
{ "database": { "rules": "database.rules.json" }, "emulators": { "database": { "port": 9000 }, "ui": { "enabled": false } } }
JSON
npm init -y >/dev/null 2>&1
npm i firebase-tools --no-audit --no-fund --loglevel=error 2>&1 | tail -2
set +e
npx firebase emulators:exec --only database --project demo-lvr "node test-owner-rules.js" > out.txt 2>&1
CODE=$?
grep -E "^(PASS|FAIL)|passed|Error|rules" out.txt | head -400
echo "exit code: $CODE"
exit $CODE
