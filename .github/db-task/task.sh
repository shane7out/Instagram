#!/bin/bash
# Test the LVR evidence-protection rules in the Firebase Realtime Database
# emulator (nothing touches the real database).
set -e
ROOT="$PWD"
WORK=/tmp/rules-test
rm -rf "$WORK"; mkdir -p "$WORK"; cd "$WORK"
cp "$ROOT/.github/db-task/rules/lvr-rules-fragment.json" .
cp "$ROOT/.github/db-task/rules/test-extra-rules.json" .
cp "$ROOT/.github/db-task/rules/test-rules.js" .

# Assemble a full ruleset: the fragment + the live catch-all ($rest, copied
# exactly) + a stand-in for the pet game's locked-down node.
node -e 'const fs=require("fs");const a=JSON.parse(fs.readFileSync("lvr-rules-fragment.json","utf8"));const b=JSON.parse(fs.readFileSync("test-extra-rules.json","utf8"));fs.writeFileSync("database.rules.json",JSON.stringify({rules:Object.assign({},a,b)},null,1));'
cat > firebase.json <<'JSON'
{ "database": { "rules": "database.rules.json" }, "emulators": { "database": { "port": 9000 }, "ui": { "enabled": false } } }
JSON
npm init -y >/dev/null 2>&1
npm i firebase-tools --no-audit --no-fund --loglevel=error 2>&1 | tail -2
set +e
npx firebase emulators:exec --only database --project demo-lvr "node test-rules.js" > out.txt 2>&1
CODE=$?
grep -E "^(PASS|FAIL)|passed|Error|rules" out.txt | head -150
echo "exit code: $CODE"
exit 0

# ---- live check: what does the page-view log actually contain?
node <<'NODE'
const https = require('https');
const get = p => new Promise(res => https.get('https://lvr-data-a60c1-default-rtdb.firebaseio.com' + p, r => { let d = ''; r.on('data', c => d += c); r.on('end', () => res(d)); }).on('error', () => res('null')));
(async () => {
  console.log('\n===== LIVE PAGE-VIEW LOG =====');
  const top = JSON.parse(await get('/key_pageviews.json?shallow=true') || 'null');
  console.log('children of key_pageviews:', top ? Object.keys(top).join(', ') : 'none');
  const hits = JSON.parse(await get('/key_pageviews/hits.json?shallow=true') || 'null');
  console.log('page keys under hits:', hits ? Object.keys(hits).join(', ') : 'none');
  if (hits) for (const k of Object.keys(hits)) {
    const n = JSON.parse(await get('/key_pageviews/hits/' + encodeURIComponent(k) + '.json?shallow=true') || 'null');
    console.log('  ' + k + ': ' + (n ? Object.keys(n).length : 0) + ' views');
  }
})();
NODE
