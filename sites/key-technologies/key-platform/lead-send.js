/* Sends a lead two ways at once: saved to the lead database, and an email alert through Formspree.
   The visitor sees success if EITHER worked (the lead is not lost), and an error only if BOTH failed.
   The email alert never shows the database-only server-timestamp placeholder; it gets a readable submittedAt instead.
   Usage: KTLead.send(databaseUrl, formspreeUrl, data[, extraFieldsForTheEmail]).then(ok).catch(failed)
   No tracking, no other network calls. */
(function () {
  function post(url, body, accept) {
    var h = { 'Content-Type': 'application/json' };
    if (accept) h.Accept = 'application/json';
    return fetch(url, { method: 'POST', headers: h, body: JSON.stringify(body) }).then(function (r) {
      if (!r.ok) throw new Error('HTTP ' + r.status);
      return true;
    });
  }
  function emailCopy(data, extra) {
    var m = {}, k;
    for (k in data) {
      var v = data[k];
      // drop Firebase server-timestamp placeholders, e.g. {".sv":"timestamp"}
      if (v && typeof v === 'object' && !Array.isArray(v) && v['.sv']) continue;
      m[k] = v;
    }
    if (extra) for (k in extra) m[k] = extra[k];
    m.submittedAt = new Date().toISOString();
    // a readable email subject so alerts are easy to tell apart in the inbox
    if (!m._subject) {
      var who = String(data.name || data.restaurant || data.email || 'someone').slice(0, 60);
      var what = String(data.source || 'website').replace(/[-_]+/g, ' ');
      m._subject = 'New lead: ' + who + ' (' + what + ')';
    }
    return m;
  }
  // The three qualifier answers (what the business does, what they want done, when to start) come from the form that was just submitted,
  // so every page's own send code saves and emails them without being edited.
  var lastForm = null;
  document.addEventListener('submit', function (e) { if (e.target && e.target.elements && e.target.elements.businessDoes) lastForm = e.target; }, true);
  function addQualifiers(data) {
    if (!lastForm) return;
    [['businessDoes', 160], ['wantDone', 600], ['startWhen', 60]].forEach(function (p) {
      var el = lastForm.elements[p[0]];
      if (el && !data[p[0]]) data[p[0]] = String(el.value || '').trim().slice(0, p[1]);
    });
  }
  function send(dbUrl, fsUrl, data, extra) {
    addQualifiers(data);
    // forms ask for first and last name; keep one combined "name" too so the lead list and email alerts keep working
    try { if (window.KTTrack && window.KTTrack.pid && window.KTTrack.pid()) data.pid = window.KTTrack.pid(); } catch (e) {}   // lets the owner see which visits this person made
    if (!data.name && (data.firstName || data.lastName)) data.name = (String(data.firstName || '') + ' ' + String(data.lastName || '')).trim().slice(0, 80);
    var db = dbUrl ? post(dbUrl, data, false) : Promise.reject(new Error('no database'));
    var al = fsUrl ? post(fsUrl, emailCopy(data, extra), true) : Promise.reject(new Error('no alert'));
    return Promise.all([
      db.then(function () { return true; }, function () { return false; }),
      al.then(function () { return true; }, function () { return false; })
    ]).then(function (res) {
      if (!res[0] && !res[1]) throw new Error('could not send');
      // visitor counter: record only THAT a form was sent and which one (its name), never what was typed
      try { if (window.KTTrack) window.KTTrack.lead(String(data.source || 'form')); } catch (e) {}
      return { saved: res[0], alerted: res[1] };
    });
  }

  // Shared rules for every lead form that has First name / Last name fields: first name, last name, business name (where the form has the field), email and
  // phone are all required. Runs before the form's own handler and stops the send, saying which field to fix.
  function phoneOk(v) { var d = String(v || '').replace(/\D/g, ''); return d.length >= 7 && d.length <= 15; }
  function emailOk(v) { return /^\S+@\S+\.\S+$/.test(String(v || '').trim()); }
  function problem(f) {
    var chk = [['firstName', function (v) { return !!v.trim(); }, 'Please enter your first name.'],
               ['lastName', function (v) { return !!v.trim(); }, 'Please enter your last name.'],
               ['business', function (v) { return !!v.trim(); }, 'Please enter your business name.'],
               ['businessDoes', function (v) { return v.trim().length >= 3; }, 'Please tell us what your business does.'],
               ['wantDone', function (v) { return v.trim().length >= 5; }, 'Please tell us what you want done.'],
               ['startWhen', function (v) { return !!v.trim(); }, 'Please choose when you want to start.'],
               ['email', emailOk, 'Please enter a valid email.'],
               ['phone', phoneOk, 'Please enter a phone number we can reach you on (with area code).']];
    for (var i = 0; i < chk.length; i++) {
      var el = f.elements[chk[i][0]];
      if (el && !chk[i][1](el.value || '')) return { el: el, msg: chk[i][2] };
    }
    return null;
  }
  document.addEventListener('submit', function (e) {
    var f = e.target;
    if (!f || !f.elements || !f.elements.firstName) return;
    var honey = f.elements.website;
    if (honey && honey.value) return; // robots fill the hidden field: let the form's own handler deal with it
    var bad = problem(f);
    if (!bad) return;
    e.preventDefault(); e.stopImmediatePropagation();
    var st = f.querySelector('.form-status') || f.querySelector('[role="status"]');
    if (st) { st.textContent = bad.msg; st.className = 'form-status err'; }
    try { bad.el.focus(); } catch (er) {}
  }, true);
  window.KTLead = { send: send };
})();
