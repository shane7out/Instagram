/* Key Technologies visitor counter: first-party database, plus one outside lookup for the rough place.
   Records, in this site's own database (no ad network):
     - one record per page view: which page, when, the page that linked here (address only, no query), screen width,
       browser language, time zone, device type (phone/tablet/desktop), the in-app browser if there is one (Instagram,
       Facebook, TikTok), a campaign tag if the link had one (utm_*), a random tab id that is forgotten when the tab
       closes, and a random visitor id kept on this device so a returning visitor is recognised;
     - the rough place and network (2026-11-27, Shane's decision): the visitor's IP address, city, region, country, a
       map spot (rounded to about a mile) and the internet provider, from one lookup to ipwho.is (or ipapi.co if that
       fails). That lookup is the only outside service the counter uses, and the result is kept on the device for 12 hours;
     - how long the page was actually in view and how far down it was scrolled;
     - which main buttons and links were pressed (name only), which form was sent (the form's name only, never
       what was typed), and which addresses led to the "page not found" page;
     - if a visitor then sends one of our forms, the form carries the same visitor id, so the owner can see which visits
       that person made (only the owner can read any of this).
   NEVER collected: anything typed into a form by this script, cookies, fingerprints. It stays off when the visitor has Do Not
   Track or Global Privacy Control turned on, for robots and test browsers, and for the owner's own browsers (see ?notrack=1).
   Owner switch: open any page with ?notrack=1 to stop counting that browser, ?notrack=0 to count it again. */
(function () {
  if (window.__ktPV) return;
  window.__ktPV = true;
  var DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com/key_pageviews';
  var nav = navigator, loc = location;

  // owner opt-out switch (the only thing kept on the device: a flag that says "do not count me")
  try {
    var m = /[?&]notrack=([01])\b/.exec(loc.search);
    if (m) { if (m[1] === '1') localStorage.setItem('kt_owner', '1'); else localStorage.removeItem('kt_owner'); }
    if (localStorage.getItem('kt_owner')) return;
  } catch (e) {}

  if (nav.doNotTrack === '1' || window.doNotTrack === '1' || nav.msDoNotTrack === '1' || nav.globalPrivacyControl === true) return;
  if (nav.webdriver) return;
  if (/bot|crawl|spider|slurp|headless|lighthouse|pagespeed|preview|monitor/i.test(nav.userAgent || '')) return;
  if (document.visibilityState === 'prerender') return;

  function rid(n) {
    var a = '', c = 'abcdefghijklmnopqrstuvwxyz0123456789', i;
    try { var u = new Uint8Array(n); (window.crypto || window.msCrypto).getRandomValues(u); for (i = 0; i < n; i++) a += c[u[i] % c.length]; return a; } catch (e) {}
    for (i = 0; i < n; i++) a += c[Math.floor(Math.random() * c.length)];
    return a;
  }
  // page key: the path from the site root, with "/" -> "__" and "." -> "_" (database keys cannot contain either)
  function pageKey() {
    var p = loc.pathname.replace(/^\/+/, '');
    if (!p || /\/$/.test(p)) p += 'index.html';
    if (!/\.[a-z0-9]+$/i.test(p)) p += '.html';
    return p.replace(/\//g, '__').replace(/\./g, '_').replace(/[^A-Za-z0-9_\-]/g, '-').slice(0, 150);
  }
  var page = window.KT_NOT_FOUND ? '404_html' : pageKey(); // a missing address is filed under the "not found" page, with the address kept in the event
  var vid = rid(10);
  // a random visitor id kept on this device (not a cookie, never sent anywhere except our own database)
  var pid = '';
  try { pid = localStorage.getItem('kt_pid') || ''; if (!/^[a-z0-9]{10,40}$/.test(pid)) { pid = rid(16); localStorage.setItem('kt_pid', pid); } } catch (e) { pid = ''; }
  // the app the visitor came through, when it is one of the in-app browsers (a link opened from Instagram, Facebook, TikTok ...)
  var ua = nav.userAgent || '', inapp = /Instagram/i.test(ua) ? 'instagram' : /FBAN|FBAV|FB_IAB/i.test(ua) ? 'facebook' : /TikTok|musical_ly|BytedanceWebview/i.test(ua) ? 'tiktok' : /Snapchat/i.test(ua) ? 'snapchat' : /LinkedInApp/i.test(ua) ? 'linkedin' : /Twitter/i.test(ua) ? 'x' : '';
  var sid = '';
  try { sid = sessionStorage.getItem('kt_sid') || ''; if (!sid) { sid = rid(12); sessionStorage.setItem('kt_sid', sid); } } catch (e) { sid = ''; }

  function post(path, body, keep) {
    try {
      fetch(DB + path + '.json', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body), keepalive: !!keep }).catch(function () {});
    } catch (e) {}
  }
  function clean(s, n) { return String(s || '').slice(0, n); }

  // ---------- the page view ----------
  var w = window.innerWidth || 0;
  var rec = { t: Date.now(), v: vid, w: w, dev: w && w < 600 ? 'phone' : (w && w < 1024 ? 'tablet' : 'desktop') };
  var ref = (document.referrer || '').split(/[?#]/)[0];
  if (ref) rec.ref = clean(ref, 200);
  if (sid) rec.s = sid;
  if (pid) rec.pid = pid;
  if (inapp) rec.app = inapp;
  try { var tz = Intl.DateTimeFormat().resolvedOptions().timeZone; if (tz) rec.tz = clean(tz, 60); } catch (e) {}
  if (nav.language) rec.lang = clean(nav.language, 16);
  try {
    var q = new URLSearchParams(loc.search), tag = [q.get('utm_source'), q.get('utm_medium'), q.get('utm_campaign')].filter(Boolean).join('/');
    if (tag) rec.src = clean(tag, 100);
  } catch (e) {}
  // If the database has not been given the newer rules yet it refuses the extra fields: send the plain hit again so no visit is ever lost
  var newRules = true;
  (function () {
    try {
      fetch(DB + '/hits/' + page + '.json', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(rec) }).then(function (r) {
        if (r && r.ok === false && (rec.pid || rec.app)) {
          newRules = false;
          var plain = {}; for (var k in rec) if (k !== 'pid' && k !== 'app') plain[k] = rec[k];
          post('/hits/' + page, plain, false);
        }
      }).catch(function () {});
    } catch (e) {}
  })();

  // ---------- the rough place (one outside lookup, kept on the device for 12 hours) ----------
  function lookup(cb) {
    var G = null; try { G = JSON.parse(localStorage.getItem('kt_geo') || 'null'); } catch (e) {}
    if (G && G.ip && Date.now() - (G.t || 0) < 12 * 3600 * 1000) return cb(G);
    var done = false;
    function fin(g) { if (done) return; done = true; if (g) { g.t = Date.now(); try { localStorage.setItem('kt_geo', JSON.stringify(g)); } catch (e) {} } cb(g || null); }
    function num(x) { x = Number(x); return isFinite(x) ? Math.round(x * 100) / 100 : null; }
    function second() {
      fetch('https://ipapi.co/json/').then(function (r) { return r.json(); }).then(function (j) {
        fin(j && j.ip ? { ip: j.ip, city: j.city, reg: j.region, cc: j.country_code, lat: num(j.latitude), lon: num(j.longitude), isp: j.org } : null);
      }).catch(function () { fin(null); });
    }
    try {
      fetch('https://ipwho.is/?fields=success,ip,city,region,country_code,latitude,longitude,connection').then(function (r) { return r.json(); }).then(function (j) {
        if (j && j.success !== false && j.ip) fin({ ip: j.ip, city: j.city, reg: j.region, cc: j.country_code, lat: num(j.latitude), lon: num(j.longitude), isp: j.connection && j.connection.isp });
        else second();
      }).catch(second);
    } catch (e) { second(); }
    setTimeout(function () { fin(null); }, 6000);
  }
  lookup(function (g) {
    if (!g) return;
    var e = { t: Date.now(), k: 'g', p: page, v: vid };
    if (sid) e.s = sid;
    if (pid) e.pid = pid;
    if (inapp) e.app = inapp;
    if (g.ip) e.ip = clean(g.ip, 45);
    if (g.city) e.city = clean(g.city, 80);
    if (g.reg) e.reg = clean(g.reg, 80);
    if (/^[A-Za-z]{2}$/.test(g.cc || '')) e.cc = String(g.cc).toUpperCase();
    if (typeof g.lat === 'number' && g.lat >= -90 && g.lat <= 90) e.lat = g.lat;
    if (typeof g.lon === 'number' && g.lon >= -180 && g.lon <= 180) e.lon = g.lon;
    if (g.isp) e.isp = clean(g.isp, 100);
    setTimeout(function () { if (newRules) post('/events', e, true); }, 1500);
  });

  // ---------- events (names only) ----------
  var sent = 0;
  function event(kind, name, extra) {
    if (sent > 60) return; // a page can only send so many
    sent++;
    var e = { t: Date.now(), k: kind, p: page, v: vid };
    if (sid) e.s = sid;
    if (name) e.n = clean(name, 90);
    if (extra) for (var k in extra) e[k] = extra[k];
    post('/events', e, true);
  }
  window.KTTrack = { event: function (name) { event('c', name); }, lead: function (source) { event('l', 'lead:' + clean(source, 40)); }, pid: function () { return pid; } };

  if (window.KT_NOT_FOUND) event('n', loc.pathname);

  var seen = {};
  document.addEventListener('click', function (ev) {
    var a = ev.target && ev.target.closest ? ev.target.closest('a[href]') : null;
    if (!a) return;
    var h = a.getAttribute('href') || '', name = '';
    if (/^tel:/i.test(h)) name = 'click:phone';
    else if (/^mailto:/i.test(h)) name = 'click:email';
    else if (/book\.html/.test(h)) name = 'click:book-a-call';
    else if (/^#contact$|#contact$/.test(h)) name = 'click:contact';
    else if (/partners\.html/.test(h)) name = 'click:partner-list';
    else if (/rewards\.html/.test(h)) name = 'click:rewards';
    else if (/key-platform\/demos\/([a-z0-9-]+)\.html/.test(h)) name = 'click:demo:' + RegExp.$1;
    else if (/key-platform\/(voice|email)/.test(h)) name = 'click:demo:' + RegExp.$1;
    else if (/^https?:\/\//i.test(h) && a.hostname && a.hostname !== loc.hostname) name = 'click:out:' + a.hostname.replace(/^www\./, '');
    else if (/(^|\/)(restaurants|law|real-estate|medical-dental|chiropractors-specialists|ecommerce|las-vegas|languages)\.html/.test(h)) name = 'click:page:' + h.replace(/^.*\//, '').replace(/\.html.*$/, '');
    if (!name || seen[name]) return;
    seen[name] = 1;
    event('c', name);
  }, true);

  // ---------- time in view and scroll depth ----------
  var shown = document.visibilityState !== 'hidden', since = Date.now(), total = 0, maxScroll = 0, flushes = 0, lastSecs = 0;
  function scrolled() {
    var de = document.documentElement, h = Math.max(de.scrollHeight, document.body ? document.body.scrollHeight : 0) - (window.innerHeight || 0);
    var y = window.pageYOffset || de.scrollTop || 0;
    var pct = h <= 0 ? 100 : Math.round(Math.min(100, y / h * 100));
    if (pct > maxScroll) maxScroll = pct;
  }
  window.addEventListener('scroll', scrolled, { passive: true });
  scrolled();
  function flush() {
    if (flushes >= 3) return;
    if (shown) { total += Date.now() - since; since = Date.now(); }
    var secs = Math.round(total / 1000);
    if (secs < 1 || secs <= lastSecs) return;
    lastSecs = secs;
    flushes++;
    scrolled();
    event('d', '', { dur: Math.min(secs, 86400), sc: maxScroll });
  }
  document.addEventListener('visibilitychange', function () {
    if (document.visibilityState === 'hidden') { flush(); shown = false; }
    else { shown = true; since = Date.now(); }
  });
  window.addEventListener('pagehide', function () { if (flushes < 3) { flush(); } });
})();
