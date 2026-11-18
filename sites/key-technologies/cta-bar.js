/* Phone-only sticky "Get My Free Review" bar. Appears after the visitor scrolls a little, hides when the form is on screen or the menu is open. */
(function () {
  var st = document.createElement('style');
  st.textContent = '.ktcta{display:none;position:fixed;left:0;right:0;bottom:0;z-index:30;padding:10px 16px calc(10px + env(safe-area-inset-bottom));background:rgba(15,23,30,.96);border-top:1px solid #37475a;backdrop-filter:blur(8px)}' +
    '.ktcta a{display:block;text-align:center;text-decoration:none;font:900 16px Lato,system-ui,sans-serif;color:#0f171e;background:#00a8e1;border-radius:12px;padding:14px 16px}' +
    '.ktcta a:active{background:#33bce8}' +
    '@media(max-width:760px){.ktcta.on{display:block}.ktcta-pad body{padding-bottom:76px}}';
  document.head.appendChild(st);
  var bar = document.createElement('div'); bar.className = 'ktcta'; bar.id = 'ktCta';
  bar.innerHTML = '<a href="/#lead-short">Get My Free Review</a>';
  document.body.appendChild(bar);
  var formVisible = false, targets = [document.getElementById('lead-short'), document.getElementById('contact')].filter(Boolean);
  if ('IntersectionObserver' in window && targets.length) {
    var io = new IntersectionObserver(function (es) { es.forEach(function (e) { e.target._v = e.isIntersecting; }); formVisible = targets.some(function (t) { return t._v; }); update(); });
    targets.forEach(function (t) { io.observe(t); });
  }
  function menuOpen() { var b = document.getElementById('burgerBtn'); return b && b.getAttribute('aria-expanded') === 'true'; }
  function update() {
    var on = window.scrollY > 500 && !formVisible && !menuOpen();
    bar.classList.toggle('on', on); document.documentElement.classList.toggle('ktcta-pad', on);
  }
  window.addEventListener('scroll', update, { passive: true });
  document.addEventListener('click', function () { setTimeout(update, 50); });
  update();
})();
