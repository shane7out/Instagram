/* Key Technologies visitor counter: first-party and anonymous.
   Records, in this site's own database (no third party, no ad network):
     - one record per page view: which page, when, the page that linked here (address only, no query),
       screen width, browser language, time zone (the region, not a place), device type (phone/tablet/desktop),
       a campaign tag if the link had one (utm_*), and a random tab id that is forgotten when the tab closes;
     - how long the page was actually in view and how far down it was scrolled;
     - which main buttons and links were pressed (name only), which form was sent (the form's name only, never
       what was typed), and which addresses led to the "page not found" page.
   NEVER collected: IP address, name, email, phone, anything typed into a form, cookies, fingerprints, or a
   permanent visitor id. It stays off when the visitor has Do Not Track or Global Privacy Control turned on, for
   robots and test browsers, and for the owner's own browsers (see ?notrack=1 below).
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
  try { var tz = Intl.DateTimeFormat().resolvedOptions().timeZone; if (tz) rec.tz = clean(tz, 60); } catch (e) {}
  if (nav.language) rec.lang = clean(nav.language, 16);
  try {
    var q = new URLSearchParams(loc.search), tag = [q.get('utm_source'), q.get('utm_medium'), q.get('utm_campaign')].filter(Boolean).join('/');
    if (tag) rec.src = clean(tag, 100);
  } catch (e) {}
  post('/hits/' + page, rec, false);

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
  window.KTTrack = { event: function (name) { event('c', name); }, lead: function (source) { event('l', 'lead:' + clean(source, 40)); } };

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
    else if (/(^|\/)(restaurants|law|real-estate|medical-dental|ecommerce|las-vegas|languages)\.html/.test(h)) name = 'click:page:' + h.replace(/^.*\//, '').replace(/\.html.*$/, '');
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
