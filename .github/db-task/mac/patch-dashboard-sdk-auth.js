// Dashboard patch DASHBOARD OWNER LOCK, part 2a (DASHSDK01). Run by deploy-dashboard-sdk-auth.sh on the LIVE dashboard copy.
// WHY: the dashboard saves and loads almost everything through the Firebase live (WebSocket) connection, not through plain web requests,
// and that connection has never carried a sign-in. Once the database is locked to the owner, an unsigned connection sees nothing.
// WHAT THIS DOES (nothing changes until the database is actually locked; today the page behaves exactly as before):
//   1. loads Google's own firebase-auth-compat.js (same Google host and same version 10.12.0 as the two Firebase files already loaded);
//   2. makes the page's three firebase.initializeApp calls carry the public web sign-in key (read from the database spot ownerAuth/apiKey, then
//      remembered in this browser; no key is written into the page or the repo);
//   3. defines window.OWNER_AUTH_SDK, which the owner sign-in box calls after a successful email+password sign-in (and on sign-out), so the live
//      connection signs in as you too, then reloads the page once so the lists reconnect signed in. The browser keeps that sign-in by itself.
// Marker-fenced, idempotent. No PIN, data or database rule is touched.
const fs = require('fs');
const file = process.argv[2];
if (!file) { console.error('usage: node patch-dashboard-sdk-auth.js <index.html>'); process.exit(1); }
let s = fs.readFileSync(file, 'utf8');
fs.writeFileSync(file + '.bak-sdkauth', s);
if (/DASHSDK01/.test(s)) { console.log('DASHSDK01 already present, skipping'); process.exit(0); }
const anchor = '<script defer src="https://www.gstatic.com/firebasejs/10.12.0/firebase-database-compat.js"></script>';
if (s.split(anchor).length !== 2) { console.error('DASHSDK01: database-compat script tag not found exactly once (the live page differs)'); process.exit(1); }
const bridge = `
<!--DASHSDK01-START-->
<script defer src="https://www.gstatic.com/firebasejs/10.12.0/firebase-auth-compat.js"></script>
<script>
// DASHSDK01: lets the live (WebSocket) connection sign in as the owner, so the database can be locked to the owner.
(function () {
  var DBU = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com', CK = 'lvrSdkApiKey', RK = 'lvrSdkReloaded';
  function apiKey() {
    var k = null; try { k = localStorage.getItem(CK); } catch (e) {}
    if (k) return k;
    try { var x = new XMLHttpRequest(); x.open('GET', DBU + '/ownerAuth/apiKey.json', false); x.send(); if (x.status === 200) { k = JSON.parse(x.responseText); if (typeof k === 'string' && k) { try { localStorage.setItem(CK, k); } catch (e) {} return k; } } } catch (e) {}
    return null;
  }
  function wrap() {
    if (typeof firebase === 'undefined' || !firebase.initializeApp) return false;
    if (firebase.__ownerSdkWrapped) return true;
    var orig = firebase.initializeApp;
    firebase.initializeApp = function (cfg, name) {
      try { if (cfg && typeof cfg === 'object' && !cfg.apiKey && name === undefined) { var k = apiKey(); if (k) cfg = Object.assign({}, cfg, { apiKey: k }); } } catch (e) {}
      var app = name === undefined ? orig.call(firebase, cfg) : orig.call(firebase, cfg, name);
      // start the sign-in service right away so a remembered owner sign-in is restored BEFORE the page's lists first ask the database
      try { if (name === undefined && cfg && cfg.apiKey && firebase.auth) firebase.auth(); } catch (e) {}
      return app;
    };
    firebase.__ownerSdkWrapped = true; return true;
  }
  function app() {
    if (!wrap()) return null;
    if (!firebase.apps || !firebase.apps.length) firebase.initializeApp({ databaseURL: DBU, projectId: 'lvr-data-a60c1' });
    return firebase.apps[0];
  }
  window.OWNER_AUTH_SDK = {
    signIn: function (email, pw) {
      try {
        if (!app() || !firebase.auth) return;
        return firebase.auth().signInWithEmailAndPassword(email, pw).then(function () {
          var did = false; try { did = sessionStorage.getItem(RK) === '1'; sessionStorage.setItem(RK, '1'); } catch (e) {}
          if (!did) location.reload();
        }, function () {});
      } catch (e) {}
    },
    signOut: function () { try { try { sessionStorage.removeItem(RK); } catch (e) {} if (firebase.apps && firebase.apps.length && firebase.auth) firebase.auth().signOut(); } catch (e) {} }
  };
  if (!wrap()) { document.addEventListener('DOMContentLoaded', function () { if (!wrap()) setTimeout(wrap, 300); }); }
})();
</script>
<!--DASHSDK01-END-->`;
s = s.replace(anchor, () => anchor + bridge);
fs.writeFileSync(file, s);
console.log('DASHSDK01 applied');
