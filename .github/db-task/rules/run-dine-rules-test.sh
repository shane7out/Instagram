#!/bin/bash
# Test the key_dine rules (receipt claims for restaurant offers) in the Firebase Realtime Database emulator. Nothing touches the real database.
set -e
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK=/tmp/rules-dine-test
rm -rf "$WORK"; mkdir -p "$WORK"; cd "$WORK"
cp "$HERE/key-rules-owner.json" "$HERE/test-dine-rules.js" .
node -e '
const fs=require("fs");
const k=JSON.parse(fs.readFileSync("key-rules-owner.json","utf8").split("__OWNER_UID__").join("TESTOWNER").split("__VIEWER_UID__").join("TESTVIEWER").split("__TREASURER_UID__").join("TESTTREASURER"));
fs.writeFileSync("database.rules.json",JSON.stringify({rules:{key_dine:k.key_dine}},null,1));'
cat > firebase.json <<'JSON'
{ "database": { "rules": "database.rules.json" }, "emulators": { "database": { "port": 9000 }, "ui": { "enabled": false } } }
JSON
npm init -y >/dev/null 2>&1
if [ -d /tmp/rules-owner-test/node_modules ]; then ln -s /tmp/rules-owner-test/node_modules node_modules; else npm i firebase-tools --no-audit --no-fund --loglevel=error 2>&1 | tail -2; fi
set +e
npx firebase emulators:exec --only database --project demo-lvr "node test-dine-rules.js" 2>&1 | grep -E "^(PASS|FAIL)|passed|Error|rules"
exit ${PIPESTATUS[0]}
