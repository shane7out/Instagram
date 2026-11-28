#!/bin/bash
# Needs: node, npm (registry), a browser through Playwright. Installs firebase-tools and firebase@10.12.0 into a scratch folder ONLY (not the repo).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
W=/tmp/dashsdk-test; mkdir -p "$W"; cd "$W"
cp "$HERE/../patched-dashboard.html" dash.html && node "$HERE/../mac/patch-dashboard-sdk-auth.js" dash.html || exit 1
cp "$HERE/test-dashboard-sdk-bridge.js" itest.js
cat > firebase.json <<'JSON'
{ "database": { "rules": "database.rules.json" }, "emulators": { "database": { "port": 9000 }, "auth": { "port": 9099 }, "ui": { "enabled": false } } }
JSON
echo '{"rules":{".read":false,".write":false}}' > database.rules.json
[ -d node_modules/firebase ] || { npm init -y >/dev/null 2>&1; npm i firebase-tools firebase@10.12.0 --no-audit --no-fund --loglevel=error 2>&1 | tail -2; }
env -u HTTPS_PROXY -u https_proxy -u JAVA_TOOL_OPTIONS NO_PROXY='*' DASH_COPY="$W/dash.html" FB_DIR="$W" LOCK_RULES="$HERE/dashboard-lock-rules.json" NODE_PATH="$(npm root -g)" \
  npx firebase emulators:exec --only auth,database --project demo-lvr "node itest.js" 2>&1 | grep -E "^(PASS|FAIL|ERR)|Error: Script"
