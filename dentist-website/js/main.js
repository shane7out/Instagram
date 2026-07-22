/* =============================================================
   Lumina Dental Studio — interactions
   Vanilla JS, no dependencies.
   ============================================================= */
(function () {
  "use strict";

  /* ---- Sticky header shadow on scroll ---- */
  const header = document.querySelector(".site-header");
  const onScroll = () => {
    if (!header) return;
    header.classList.toggle("scrolled", window.scrollY > 8);
  };
  window.addEventListener("scroll", onScroll, { passive: true });
  onScroll();

  /* ---- Mobile menu ---- */
  const toggle = document.querySelector(".nav__toggle");
  if (toggle) {
    toggle.addEventListener("click", () => {
      const open = document.body.classList.toggle("menu-open");
      toggle.setAttribute("aria-expanded", String(open));
    });
    document.querySelectorAll(".site-nav-mobile a").forEach((a) => {
      a.addEventListener("click", () => {
        document.body.classList.remove("menu-open");
        toggle.setAttribute("aria-expanded", "false");
      });
    });
  }

  /* ---- Scroll reveal via IntersectionObserver ---- */
  const reveals = document.querySelectorAll(".reveal");
  if ("IntersectionObserver" in window && reveals.length) {
    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((e) => {
          if (e.isIntersecting) {
            e.target.classList.add("in");
            io.unobserve(e.target);
          }
        });
      },
      { threshold: 0.12, rootMargin: "0px 0px -40px 0px" }
    );
    reveals.forEach((el) => io.observe(el));
  } else {
    reveals.forEach((el) => el.classList.add("in"));
  }

  /* ---- FAQ accordion ---- */
  document.querySelectorAll(".faq__item").forEach((item) => {
    const q = item.querySelector(".faq__q");
    const a = item.querySelector(".faq__a");
    if (!q || !a) return;
    q.addEventListener("click", () => {
      const isOpen = item.classList.contains("open");
      // close siblings for a clean single-open accordion
      item.closest(".faq").querySelectorAll(".faq__item.open").forEach((other) => {
        if (other !== item) {
          other.classList.remove("open");
          other.querySelector(".faq__q").setAttribute("aria-expanded", "false");
          other.querySelector(".faq__a").style.maxHeight = null;
        }
      });
      item.classList.toggle("open", !isOpen);
      q.setAttribute("aria-expanded", String(!isOpen));
      a.style.maxHeight = isOpen ? null : a.scrollHeight + "px";
    });
  });

  /* ---- Animated counters ---- */
  const counters = document.querySelectorAll("[data-count]");
  if (counters.length && "IntersectionObserver" in window) {
    const ease = (t) => 1 - Math.pow(1 - t, 3);
    const run = (el) => {
      const target = parseFloat(el.dataset.count);
      const suffix = el.dataset.suffix || "";
      const decimals = (el.dataset.count.split(".")[1] || "").length;
      const duration = 1500;
      let start;
      const step = (ts) => {
        if (!start) start = ts;
        const p = Math.min((ts - start) / duration, 1);
        const val = target * ease(p);
        el.textContent = val.toFixed(decimals) + suffix;
        if (p < 1) requestAnimationFrame(step);
        else el.textContent = target.toFixed(decimals) + suffix;
      };
      requestAnimationFrame(step);
    };
    const co = new IntersectionObserver((entries) => {
      entries.forEach((e) => {
        if (e.isIntersecting) {
          run(e.target);
          co.unobserve(e.target);
        }
      });
    }, { threshold: 0.5 });
    counters.forEach((el) => co.observe(el));
  }

  /* ---- Before / after smile slider ---- */
  document.querySelectorAll(".ba").forEach((ba) => {
    const range = ba.querySelector(".ba__range");
    const before = ba.querySelector(".ba__before");
    const line = ba.querySelector(".ba__line");
    const handle = ba.querySelector(".ba__handle");
    if (!range || !before) return;
    const apply = (v) => {
      before.style.clipPath = `inset(0 ${100 - v}% 0 0)`;
      if (line) line.style.left = v + "%";
      if (handle) handle.style.left = v + "%";
    };
    range.addEventListener("input", () => apply(+range.value));
    apply(+range.value);
  });

  /* ---- Appointment form (validation + optional backend) ---- */
  document.querySelectorAll("form[data-demo]").forEach((form) => {
    const showError = (field, msg) => {
      field.classList.add("show-err");
      const el = field.querySelector(".err");
      if (el) el.textContent = msg;
      const input = field.querySelector("input, select, textarea");
      if (input) input.classList.add("invalid");
    };
    const clearError = (field) => {
      field.classList.remove("show-err");
      const input = field.querySelector("input, select, textarea");
      if (input) input.classList.remove("invalid");
    };
    // live-clear errors as the user types
    form.querySelectorAll("input, select, textarea").forEach((input) => {
      input.addEventListener("input", () => {
        const field = input.closest(".field");
        if (field) clearError(field);
      });
    });

    form.addEventListener("submit", async (e) => {
      e.preventDefault();
      let ok = true;
      let firstBad = null;
      form.querySelectorAll("[required]").forEach((input) => {
        const field = input.closest(".field");
        if (!field) return;
        const val = input.value.trim();
        const isEmail = input.type === "email";
        const bad = !val || (isEmail && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(val));
        if (bad) {
          ok = false;
          showError(field, isEmail && val ? "Please enter a valid email." : "This field is required.");
          if (!firstBad) firstBad = input;
        } else {
          clearError(field);
        }
      });
      if (!ok) { if (firstBad) firstBad.focus(); return; }

      const btn = form.querySelector('button[type="submit"]');
      const endpoint = form.dataset.endpoint; // set to a Formspree URL to go live
      const card = form.closest(".form-card");

      if (endpoint) {
        const original = btn ? btn.textContent : "";
        if (btn) { btn.disabled = true; btn.textContent = "Sending…"; }
        try {
          const res = await fetch(endpoint, {
            method: "POST",
            body: new FormData(form),
            headers: { Accept: "application/json" },
          });
          if (!res.ok) throw new Error("Request failed");
          if (card) card.classList.add("sent");
          form.reset();
        } catch (err) {
          if (btn) { btn.disabled = false; btn.textContent = original; }
          alert("Sorry — something went wrong sending your request. Please call us at (555) 123-4567.");
        }
      } else {
        // Demo mode: no backend wired up yet
        if (card) card.classList.add("sent");
        form.reset();
      }
    });
  });

  /* ---- Back to top ---- */
  const toTop = document.querySelector(".to-top");
  if (toTop) {
    const toggleTop = () => toTop.classList.toggle("show", window.scrollY > 600);
    window.addEventListener("scroll", toggleTop, { passive: true });
    toggleTop();
    toTop.addEventListener("click", () => {
      const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
      window.scrollTo({ top: 0, behavior: reduce ? "auto" : "smooth" });
    });
  }

  /* ---- Footer year ---- */
  const yr = document.querySelector("[data-year]");
  if (yr) yr.textContent = new Date().getFullYear();
})();
