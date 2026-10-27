#!/bin/bash
# Test the LVR evidence-protection rules in the Firebase Realtime Database
# emulator (nothing touches the real database).
set -e
ROOT="$PWD"
WORK=/tmp/rules-test
rm -rf "$WORK"; mkdir -p "$WORK"; cd "$WORK"
java -version 2>&1 | head -1
cp "$ROOT/.github/db-task/rules/lvr-rules-fragment.json" .
cp "$ROOT/.github/db-task/rules/test-rules.js" .

# Assemble a full ruleset: the fragment + the live catch-all ($rest, copied
# exactly) + a stand-in for the pet game's locked-down node.
node -e '
const frag = JSON.parse(require("fs").readFileSync("lvr-rules-fragment.json","utf8"));
const rules = Object.assign({}, frag, {
  petgame: { "$other": { ".read": false, ".write": false } },
  "$rest": {
    ".read": true,
    ".write": "newData.exists() && (!data.child('customrecords').exists() || newData.child('customrecords').exists()) && (!data.child('staging_approved').exists() || newData.child('staging_approved').exists()) && (!data.child('staging_added').exists() || newData.child('staging_added').exists()) && (!data.child('records').exists() || newData.child('records').exists())"
  }
});
require("fs").writeFileSync("database.rules.json", JSON.stringify({ rules }, null, 1));
'
cat > firebase.json <<'JSON'
{ "database": { "rules": "database.rules.json" }, "emulators": { "database": { "port": 9000 }, "ui": { "enabled": false } } }
JSON
npm init -y >/dev/null 2>&1
npm i firebase-tools --no-audit --no-fund --loglevel=error 2>&1 | tail -3
npx firebase emulators:exec --only database --project demo-lvr "node test-rules.js" 2>&1 | grep -v "^$" | tail -120
