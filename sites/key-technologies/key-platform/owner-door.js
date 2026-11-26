/* Owner shortcut (Shane, 2026-11-26): tap or click the Key Technologies.si logo at the top left TWICE quickly and the blue PIN pad opens
   (the Key Rewards Treasury page). A single tap still just takes you to the top of the page. Nothing is shown or opened without the PIN:
   this only saves typing the address. No tracking, no network calls. */
(function () {
  var last = 0, GAP = 500, DOOR = '/restaurant-rewards-treasury.html';
  document.addEventListener('click', function (e) {
    var a = e.target && e.target.closest && e.target.closest('header a.logo, a.logo');
    if (!a) return;
    var now = Date.now();
    if (now - last < GAP) { last = 0; e.preventDefault(); location.href = DOOR; return; }
    last = now;
  }, true);
})();
