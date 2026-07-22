/* ===== SparkyLoan — front-end interactions ===== */
(function () {
  "use strict";

  // Current year in footer
  var yearEl = document.getElementById("year");
  if (yearEl) yearEl.textContent = new Date().getFullYear();

  // Mobile nav toggle
  var toggle = document.querySelector(".nav-toggle");
  var links = document.querySelector(".nav-links");
  if (toggle && links) {
    toggle.addEventListener("click", function () {
      var open = links.classList.toggle("open");
      toggle.setAttribute("aria-expanded", open ? "true" : "false");
    });
    links.addEventListener("click", function (e) {
      if (e.target.tagName === "A") {
        links.classList.remove("open");
        toggle.setAttribute("aria-expanded", "false");
      }
    });
  }

  // Multi-step request form (client-side demo only — nothing is submitted or stored)
  var form = document.getElementById("loan-form");
  if (!form) return;

  var steps = form.querySelectorAll(".form-step");

  function show(step) {
    steps.forEach(function (s) {
      s.classList.toggle("is-active", s.getAttribute("data-step") === String(step));
    });
  }

  function validate(stepEl) {
    var fields = stepEl.querySelectorAll("input, select");
    for (var i = 0; i < fields.length; i++) {
      if (!fields[i].checkValidity()) {
        fields[i].reportValidity();
        return false;
      }
    }
    return true;
  }

  form.addEventListener("click", function (e) {
    var t = e.target;
    if (t.hasAttribute("data-next")) {
      if (validate(t.closest(".form-step"))) show(2);
    } else if (t.hasAttribute("data-prev")) {
      show(1);
    } else if (t.hasAttribute("data-restart")) {
      form.reset();
      show(1);
    }
  });

  form.addEventListener("submit", function (e) {
    e.preventDefault();
    if (!validate(form.querySelector('[data-step="2"]'))) return;
    // No network request is made. This is a design demonstration.
    show("done");
  });
})();
