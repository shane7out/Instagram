/* Who looked at the giveaway pages and for how long. A visitor gets a random id on this phone (no name, no tracking across other sites).
   If they later sign up, their signup carries the same id so the owner can see which page they looked at and for how many seconds. */
(function () {
  var DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com/key_visits/';
  function rnd(n, pre) { var a = new Uint8Array(n), s = pre || ''; try { crypto.getRandomValues(a); } catch (e) { for (var i = 0; i < n; i++) a[i] = Math.floor(Math.random() * 256); } for (var j = 0; j < n; j++) s += (a[j] % 36).toString(36); return s; }
  function vid() { var v = null; try { v = localStorage.getItem('kgVid'); if (!/^[a-z0-9]{16,40}$/.test(v || '')) { v = rnd(20); localStorage.setItem('kgVid', v); } } catch (e) { v = v || rnd(20); } return v; }
  function lget() { try { return JSON.parse(localStorage.getItem('kvLocal') || '{}') || {}; } catch (e) { return {}; } }
  function lset(o) { try { localStorage.setItem('kvLocal', JSON.stringify(o)); } catch (e) {} }
  function start(page, g, demo) {
    var v = vid(), pid = rnd(12), secs = 0, last = Date.now(), sent = -1, live = true;
    var rec = { page: String(page).slice(0, 40), secs: 0 }; if (g) rec.g = String(g).slice(0, 40);
    if (demo) { var o = lget(); o[v] = o[v] || {}; var r = { page: rec.page, at: Date.now(), secs: 0 }; if (g) r.g = rec.g; o[v][pid] = r; lset(o); }
    else { var b = { page: rec.page, at: { '.sv': 'timestamp' }, secs: 0 }; if (g) b.g = rec.g; try { fetch(DB + v + '/' + pid + '.json', { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(b), keepalive: true }).catch(function () {}); } catch (e) {} }
    function flush() {
      if (secs === sent) return; sent = secs;
      if (demo) { var o = lget(); if (o[v] && o[v][pid]) { o[v][pid].secs = secs; lset(o); } return; }
      try { fetch(DB + v + '/' + pid + '.json', { method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ secs: secs }), keepalive: true }).catch(function () {}); } catch (e) {}
    }
    function tick() { var n = Date.now(); if (live && !document.hidden) secs = Math.min(7200, secs + Math.round((n - last) / 1000)); last = n; }
    setInterval(function () { tick(); if (secs && secs % 5 === 0) flush(); }, 1000);
    document.addEventListener('visibilitychange', function () { tick(); if (document.hidden) flush(); });
    window.addEventListener('pagehide', function () { tick(); flush(); });
    return v;
  }
  window.KGT = { vid: vid, start: start };
})();
