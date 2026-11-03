/* Home pill: pops in at the top of the screen once the visitor scrolls a little, so they can always get back to the homepage.
   Used on pages whose top bar scrolls away (legal pages, Rewards menu, deal page). Pages with a sticky top bar already
   keep their own Home button in view, so they do not load this file.
   No tracking, no network calls. */
(function () {
  if (window.__ktHomePop) return;
  window.__ktHomePop = true;
  var src = (document.currentScript && document.currentScript.src) || '';
  var home = '/index.html';
  try { home = new URL('../index.html', src || location.href).pathname; } catch (e) {}

  var css = document.createElement('style');
  css.textContent =
    '.kt-home-pop{position:fixed;top:10px;right:10px;z-index:2147482000;display:inline-flex;align-items:center;gap:6px;' +
    'height:44px;padding:0 16px 0 12px;border-radius:999px;background:rgba(15,23,30,.94);color:#fff;border:1px solid #00a8e1;' +
    'font:700 15px/1 Lato,system-ui,-apple-system,Segoe UI,Roboto,sans-serif;text-decoration:none;' +
    'box-shadow:0 6px 18px rgba(0,0,0,.45);-webkit-backdrop-filter:blur(6px);backdrop-filter:blur(6px);' +
    'transform:translateY(-70px);opacity:0;visibility:hidden;transition:transform .25s ease,opacity .25s ease,visibility 0s linear .25s;}' +
    '.kt-home-pop.on{transform:translateY(0);opacity:1;visibility:visible;transition:transform .25s ease,opacity .25s ease,visibility 0s;}' +
    '.kt-home-pop:hover,.kt-home-pop:focus-visible{background:#00a8e1;color:#0f171e;outline:none;}' +
    '.kt-home-pop svg{flex:none}' +
    '@media (prefers-reduced-motion:reduce){.kt-home-pop,.kt-home-pop.on{transition:none}}';
  document.head.appendChild(css);

  var a = document.createElement('a');
  a.className = 'kt-home-pop';
  a.href = home;
  a.setAttribute('aria-label', 'Home');
  a.innerHTML = '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" ' +
    'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 11.5 12 4l9 7.5"/><path d="M5.5 10v10h13V10"/></svg><span>Home</span>';
  var nav = document.createElement('nav');
  nav.setAttribute('aria-label', 'Back to the homepage');
  nav.appendChild(a);
  document.body.appendChild(nav);

  function place() {
    // keep clear of the Rewards history bar (#hnav) when it is showing
    var h = document.getElementById('hnav');
    a.style.top = (h && h.offsetHeight ? h.offsetHeight + 10 : 10) + 'px';
  }
  function update() {
    place();
    var y = window.pageYOffset || document.documentElement.scrollTop || 0;
    if (y > 60) a.classList.add('on'); else a.classList.remove('on');
  }
  window.addEventListener('scroll', update, { passive: true });
  window.addEventListener('resize', update);
  update();
})();
