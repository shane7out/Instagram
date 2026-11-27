/* Owner shortcut (Shane, 2026-11-26): tap or click the Key Technologies.si logo at the top left FIVE times in a row, quickly, and the blue PIN pad
   opens (launcher.html: after the PIN you pick which of your sites or tools to open, the Key Rewards Treasury among them). Five is on purpose so nobody gets in by tapping twice by accident. Each tap has to come within
   a second of the one before; a pause starts the count over. A single tap still just takes you to the top of the page. Nothing is shown or
   opened without the PIN: this only saves typing the address. No tracking, no network calls. */
(function () {
  var count = 0, last = 0, GAP = 1000, NEED = 5, DOOR = '/launcher.html';
  document.addEventListener('click', function (e) {
    var a = e.target && e.target.closest && e.target.closest('header a.logo, a.logo');
    if (!a) return;
    var now = Date.now();
    count = (now - last < GAP) ? count + 1 : 1;
    last = now;
    if (count >= NEED) { count = 0; last = 0; e.preventDefault(); location.href = DOOR; }
  }, true);
})();
