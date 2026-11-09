/* Light/Dark toggle button for the header of every public Key Technologies page. The choice is remembered in this browser (localStorage kt_look = "dark";
   no entry means the default light look). The styles for the two looks live in kt-light.css under html[data-look="light"]. */
(function () {
  var SUN = '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/></svg>';
  var MOON = '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z"/></svg>';
  function isLight() { return document.documentElement.getAttribute('data-look') === 'light'; }
  function build() {
    var host = document.querySelector('.nav-cta') || document.querySelector('header .wrap');
    if (!host || document.getElementById('kt-theme-btn')) return;
    var b = document.createElement('button'); b.id = 'kt-theme-btn'; b.type = 'button';
    function paint() { var l = isLight(); b.setAttribute('aria-label', l ? 'Switch to the dark look' : 'Switch to the light look'); b.title = l ? 'Dark look' : 'Light look'; b.innerHTML = l ? MOON : SUN; }
    b.addEventListener('click', function () {
      try {
        if (isLight()) { document.documentElement.removeAttribute('data-look'); localStorage.setItem('kt_look', 'dark'); }
        else { document.documentElement.setAttribute('data-look', 'light'); localStorage.removeItem('kt_look'); }
      } catch (e) { if (isLight()) document.documentElement.removeAttribute('data-look'); else document.documentElement.setAttribute('data-look', 'light'); }
      var m = document.querySelector('meta[name=theme-color]'); if (m) m.setAttribute('content', isLight() ? '#ffffff' : '#0f171e');
      paint();
    });
    paint(); host.insertBefore(b, host.firstChild);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', build); else build();
})();
