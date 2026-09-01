// St Rita's Retreat — nav toggle and inquiry form handling

(function () {
  var toggle = document.querySelector('.nav-toggle');
  var nav = document.getElementById('primary-nav');

  if (toggle && nav) {
    var mobile = window.matchMedia('(max-width: 760px)');

    var sync = function () {
      // The menu is only collapsible on small screens; always visible above that.
      nav.hidden = mobile.matches;
      toggle.setAttribute('aria-expanded', 'false');
    };

    sync();
    mobile.addEventListener('change', sync);

    toggle.addEventListener('click', function () {
      var open = nav.hidden;
      nav.hidden = !open;
      toggle.setAttribute('aria-expanded', String(open));
    });
  }

  // No backend is wired up: confirm receipt in place and hand the visitor an
  // email fallback so an inquiry is never silently dropped.
  document.querySelectorAll('form[data-inquiry]').forEach(function (form) {
    form.addEventListener('submit', function (event) {
      event.preventDefault();

      var status = form.querySelector('.form-status');
      var name = (form.querySelector('[name="name"]') || {}).value || '';

      if (status) {
        status.hidden = false;
        status.innerHTML =
          'Thank you' + (name ? ', ' + escapeHtml(name.split(' ')[0]) : '') +
          '. Your inquiry has been prepared. This demonstration site does not ' +
          'send mail, so please email <a href="mailto:info@stritaretreat.com">' +
          'info@stritaretreat.com</a> or call ' +
          '<a href="tel:+15416600032">541-660-0032</a> to complete your request.';
        status.focus();
        status.scrollIntoView({ block: 'nearest' });
      }
    });
  });

  function escapeHtml(value) {
    return value.replace(/[&<>"']/g, function (character) {
      return {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#39;'
      }[character];
    });
  }
})();
