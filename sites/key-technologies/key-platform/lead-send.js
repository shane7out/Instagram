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
  function send(dbUrl, fsUrl, data, extra) {
    var db = dbUrl ? post(dbUrl, data, false) : Promise.reject(new Error('no database'));
    var al = fsUrl ? post(fsUrl, emailCopy(data, extra), true) : Promise.reject(new Error('no alert'));
    return Promise.all([
      db.then(function () { return true; }, function () { return false; }),
      al.then(function () { return true; }, function () { return false; })
    ]).then(function (res) {
      if (!res[0] && !res[1]) throw new Error('could not send');
      return { saved: res[0], alerted: res[1] };
    });
  }
  window.KTLead = { send: send };
})();
