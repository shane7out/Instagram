/* Restaurant Rewards: "Where you can use it" list + in-page map. Drop <div data-rr-where></div> on a page and load this script.
   The map is an embedded map: visitors never leave the page. Example restaurants only (labeled). Key Technologies look. */
(function () {
  var PLACES = [
    { name: "Vanilla Rice's Hibachi House", tag: 'Hibachi', locs: [
      { label: 'Las Vegas', addr: '6300 W Charleston Blvd, Ste 170', city: 'Las Vegas, NV 89146' }
    ] },
    { name: "Johnny Mac's Sports Bar & Grill", tag: 'Pizza, wings and sports bar', locs: [
      { label: 'Boulder Highway', addr: '842 S Boulder Hwy', city: 'Henderson, NV 89015', tel: '702-564-2121' },
      { label: 'Water Street Tavern', addr: '117 S Water Street', city: 'Henderson, NV 89015', tel: '725-214-7317' },
      { label: 'Cedar City', addr: '2605 N Main St #130', city: 'Cedar City, UT 84721', tel: '435-708-0220' }
    ] }
  ];
  var CSS = '.rrw{--c:#232f3e;--l:#37475a;--i:#f6f8fb;--d:#aab9ca;--k:#00a8e1;--k2:#4fc8f0;font-family:Lato,system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;color:var(--i)}' +
    '.rrw h2{margin:0 0 6px;font-size:clamp(24px,4vw,32px);font-weight:900}.rrw .rrsub{color:var(--d);margin:0 0 18px;max-width:680px}' +
    '.rrgrid{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1.25fr);gap:16px;align-items:start}' +
    '.rrlist{display:grid;gap:12px;max-height:460px;overflow:auto;padding-right:2px}' +
    '.rrcard{background:var(--c);border:1px solid var(--l);border-radius:14px;padding:14px 16px}' +
    '.rrcard h3{margin:0;font-size:17px;font-weight:900;display:flex;flex-wrap:wrap;gap:6px 10px;align-items:center}' +
    '.rrbadge{font-size:11px;font-weight:900;letter-spacing:.1em;text-transform:uppercase;color:#0f171e;background:var(--k);border-radius:999px;padding:2px 9px}' +
    '.rrtag{color:var(--d);font-size:13.5px;margin:2px 0 8px}' +
    '.rrloc{display:block;width:100%;text-align:left;background:transparent;border:1px solid var(--l);border-radius:10px;padding:10px 12px;margin-top:8px;color:var(--i);font:inherit;cursor:pointer}' +
    '.rrloc:hover{border-color:var(--k2)}.rrloc[aria-pressed="true"]{border-color:var(--k);background:rgba(0,168,225,.12)}' +
    '.rrloc b{display:block;font-size:15px}.rrloc span{display:block;color:var(--d);font-size:14px}' +
    '.rrtel{display:inline-block;margin:6px 0 0 2px;color:var(--k2);font-weight:700;font-size:14px;text-decoration:none}' +
    '.rrmap{background:var(--c);border:1px solid var(--l);border-radius:14px;overflow:hidden}' +
    '.rrmap iframe{display:block;width:100%;height:400px;border:0;background:#18222d}' +
    '.rrcap{padding:10px 14px;color:var(--d);font-size:13.5px;border-top:1px solid var(--l)}.rrcap b{color:var(--i)}' +
    '.rrfine{color:var(--d);font-size:13px;margin:12px 0 0}' +
    '@media(max-width:760px){.rrgrid{grid-template-columns:1fr}.rrlist{max-height:none}.rrmap iframe{height:280px}}';

  function esc(t) { return String(t).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;'); }

  function init(box) {
    var st = document.createElement('style'); st.textContent = CSS; document.head.appendChild(st);
    var html = '<div class="rrw"><h2>Where you can use Restaurant Rewards</h2>' +
      '<p class="rrsub">One rewards balance, accepted at every participating restaurant. Tap a restaurant or an address and the map moves right here. You never leave this page.</p>' +
      '<div class="rrgrid"><div class="rrlist">';
    PLACES.forEach(function (p, pi) {
      html += '<div class="rrcard"><h3>' + esc(p.name) + ' <span class="rrbadge">Example</span></h3><p class="rrtag">' + esc(p.tag) + '</p>';
      p.locs.forEach(function (l, li) {
        html += '<button type="button" class="rrloc" data-p="' + pi + '" data-l="' + li + '" aria-pressed="false"><b>' + esc(l.label) + '</b><span>' + esc(l.addr) + ', ' + esc(l.city) + '</span></button>';
        if (l.tel) html += '<a class="rrtel" href="tel:' + esc(l.tel.replace(/[^0-9]/g, '')) + '">Call ' + esc(l.tel) + '</a>';
      });
      html += '</div>';
    });
    html += '</div><div class="rrmap"><iframe title="Map of the restaurant you picked" loading="lazy" referrerpolicy="no-referrer" sandbox="allow-scripts allow-same-origin" allowfullscreen></iframe>' +
      '<div class="rrcap" aria-live="polite">Map: <b class="rrnow"></b></div></div></div>' +
      '<p class="rrfine">Example restaurants shown for this demo. The real list is the restaurants that have joined.</p></div>';
    box.innerHTML = html;
    var frame = box.querySelector('iframe'), now = box.querySelector('.rrnow'), btns = [].slice.call(box.querySelectorAll('.rrloc'));
    function show(pi, li) {
      var p = PLACES[pi], l = p.locs[li];
      btns.forEach(function (b) { b.setAttribute('aria-pressed', (+b.dataset.p === pi && +b.dataset.l === li) ? 'true' : 'false'); });
      now.textContent = p.name + ', ' + l.label + ', ' + l.addr + ', ' + l.city;
      frame.src = 'https://www.google.com/maps?q=' + encodeURIComponent(p.name + ' ' + l.addr + ' ' + l.city) + '&z=15&output=embed';
    }
    btns.forEach(function (b) { b.addEventListener('click', function () { show(+b.dataset.p, +b.dataset.l); }); });
    var loaded = false;
    function first() { if (loaded) return; loaded = true; show(0, 0); }
    if ('IntersectionObserver' in window) {
      var io = new IntersectionObserver(function (e) { if (e[0].isIntersecting) { io.disconnect(); first(); } }, { rootMargin: '200px' });
      io.observe(box);
    } else first();
  }
  function go() { [].slice.call(document.querySelectorAll('[data-rr-where]')).forEach(init); }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', go); else go();
})();
