#!/bin/bash
# Test the STAGED Key Rewards rules (key-rewards-rules.json) and the engine against them, in the Firebase Realtime Database
# emulator (nothing touches the real database). Run locally with the proxy variables unset if needed:
#   env -u HTTPS_PROXY -u HTTP_PROXY NO_PROXY='*' bash .github/db-task/rules/run-kr-rules-test.sh
set -e
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK=/tmp/kr-rules-test
rm -rf "$WORK"; mkdir -p "$WORK"; cd "$WORK"
cp "$HERE/key-rewards-rules.json" "$HERE/test-key-rewards.js" .
cp "$HERE/../../../sites/key-technologies/key-platform/kr-engine.js" .
node -e '
const fs=require("fs");
const raw=fs.readFileSync("key-rewards-rules.json","utf8");
if(!raw.includes("__OWNER_UID__")){console.error("placeholder __OWNER_UID__ not found");process.exit(3);}
fs.writeFileSync("database.rules.json",JSON.stringify({rules:JSON.parse(raw.split("__OWNER_UID__").join("TESTOWNER"))},null,1));
'
cat > firebase.json <<'JSON'
{ "database": { "rules": "database.rules.json" }, "emulators": { "database": { "port": 9000 }, "ui": { "enabled": false } } }
JSON
npm init -y >/dev/null 2>&1
npm i firebase-tools --no-audit --no-fund --loglevel=error 2>&1 | tail -2
set +e
npx firebase emulators:exec --only database --project demo-lvr "node test-key-rewards.js" > out.txt 2>&1
CODE=$?
grep -E "^(PASS|FAIL)|passed|Error|ERROR|rules" out.txt | head -2000
echo "exit code: $CODE"
exit $CODE
