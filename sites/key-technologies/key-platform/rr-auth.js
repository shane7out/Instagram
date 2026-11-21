/* Key Rewards: PIN sign-in and database calls, shared by the Treasury page and the restaurant confirm page.
   A 6-digit PIN is turned (PBKDF2, in this browser) into the password of one sign-in account; the PIN itself is never sent or saved.
   The session lives in this tab only (sessionStorage), so a new tab or a closed browser asks for the PIN again. */
(function () {
  var DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com', IDT = 'https://identitytoolkit.googleapis.com/v1', STS = 'https://securetoken.googleapis.com/v1/token';
  var st = null, apiKey = null, SKEY = 'rrSess1';
  var enc = new TextEncoder();
  try { var raw = sessionStorage.getItem(SKEY); if (raw) st = JSON.parse(raw); } catch (e) { st = null; }
  function saveSt() { try { if (st) sessionStorage.setItem(SKEY, JSON.stringify(st)); else sessionStorage.removeItem(SKEY); } catch (e) {} }
  function getKey() {
    if (apiKey) return Promise.resolve(apiKey);
    return fetch(DB + '/ownerAuth/apiKey.json').then(function (r) { return r.json(); }).then(function (k) { apiKey = k || null; return apiKey; });
  }
  function derive(pin, salt) {
    return crypto.subtle.importKey('raw', enc.encode(pin), 'PBKDF2', false, ['deriveBits']).then(function (k) {
      return crypto.subtle.deriveBits({ name: 'PBKDF2', salt: enc.encode(salt), iterations: 150000, hash: 'SHA-256' }, k, 256);
    }).then(function (bits) {
      var u = new Uint8Array(bits), s = ''; for (var i = 0; i < u.length; i++) s += String.fromCharCode(u[i]);
      return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
    });
  }
  function signInPw(email, pw) {
    return getKey().then(function (k) {
      if (!k) throw new Error('Sign-in is not set up yet.');
      return fetch(IDT + '/accounts:signInWithPassword?key=' + encodeURIComponent(k), { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email: email, password: pw, returnSecureToken: true }) });
    }).then(function (r) {
      return r.json().then(function (j) {
        if (!r.ok) { var m = (j && j.error && j.error.message) || ''; var e = new Error(/TOO_MANY/i.test(m) ? 'Too many tries. Wait a few minutes.' : 'That PIN is not right.'); e.bad = !/TOO_MANY/i.test(m); throw e; }
        st = { idToken: j.idToken, refreshToken: j.refreshToken, exp: Date.now() + (Number(j.expiresIn) || 3600) * 1000 - 60000, email: email };
        saveSt(); return st;
      });
    });
  }
  function signIn(email, pin, salt) {
    if (!window.crypto || !crypto.subtle) return Promise.reject(new Error('This browser cannot check a PIN.'));
    return derive(pin, salt).then(function (pw) { return signInPw(email, pw); });
  }
  function refresh() {
    if (!st || !st.refreshToken) return Promise.resolve(null);
    return getKey().then(function (k) {
      return fetch(STS + '?key=' + encodeURIComponent(k), { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: 'grant_type=refresh_token&refresh_token=' + encodeURIComponent(st.refreshToken) });
    }).then(function (r) { return r.ok ? r.json() : null; }).then(function (j) {
      if (!j) { st = null; saveSt(); return null; }
      st = { idToken: j.id_token, refreshToken: j.refresh_token, exp: Date.now() + (Number(j.expires_in) || 3600) * 1000 - 60000, email: st.email };
      saveSt(); return st.idToken;
    }).catch(function () { return null; });
  }
  function token() { if (!st) return Promise.resolve(null); if (Date.now() < st.exp) return Promise.resolve(st.idToken); return refresh(); }
  /* db(method, path, body, query) -> {status, json}; path like 'rr_ledger/entries/e0000001/status'; query like 'orderBy=%22to%22&equalTo=%22w1%22' */
  function db(method, path, body, query) {
    return token().then(function (t) {
      if (!t) return { status: 401, json: null };
      var u = DB + '/' + path + '.json?auth=' + encodeURIComponent(t) + (query ? '&' + query : '');
      var o = { method: method }; if (body !== undefined) { o.headers = { 'Content-Type': 'application/json' }; o.body = JSON.stringify(body); }
      return fetch(u, o).then(function (r) { return r.text().then(function (x) { var j = null; try { j = x ? JSON.parse(x) : null; } catch (e) {} return { status: r.status, json: j }; }); });
    }).catch(function () { return { status: 0, json: null }; });
  }
  function signedIn() { return !!st; }
  function email() { return st ? st.email : null; }
  function signOut() { st = null; saveSt(); }

  /* A full-screen PIN pad. opts: {title, sub, email(optional fixed), askId(optional {label, placeholder, make(id)->{email,salt}}), salt, onOK(), onSkip({label,fn})} */
  /* The PIN screen is the LVR dashboard PIN screen: deep blue glow, six dots, round frosted keys (numbers only), a delete arrow, and a Face ID key.
     The screen is locked in place: nothing pans or shakes sideways when a key is tapped. */
  var css = '#rrGate{position:fixed;inset:0;z-index:2147483000;color:#fff;overflow-x:hidden;overflow-y:auto;overscroll-behavior:none;touch-action:manipulation;-webkit-text-size-adjust:100%;font:400 17px/1.4 Lato,system-ui,-apple-system,sans-serif;' +
    'background:radial-gradient(ellipse 90% 70% at 50% 30%,rgba(14,72,168,.55) 0%,transparent 65%),radial-gradient(ellipse 60% 52% at 15% 80%,rgba(0,105,230,.30) 0%,transparent 58%),radial-gradient(ellipse 55% 48% at 85% 18%,rgba(36,12,140,.35) 0%,transparent 56%),radial-gradient(ellipse 45% 38% at 68% 68%,rgba(0,180,255,.16) 0%,transparent 50%),#050b16}' +
    '#rrGate .in{min-height:100%;width:100%;box-sizing:border-box;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:max(34px,env(safe-area-inset-top,34px)) 16px 30px;text-align:center;overflow:hidden}' +
    '#rrGate h1{font-size:12px;font-weight:500;letter-spacing:.04em;color:rgba(255,255,255,.4);margin:0 0 6px}#rrGate p{color:rgba(255,255,255,.55);margin:0 0 26px;font-size:14px;max-width:290px}' +
    '#rrGate .idrow{margin:0 0 22px;text-align:left;width:260px}#rrGate .idrow label{display:block;font-size:13px;font-weight:600;color:rgba(255,255,255,.6);margin:0 0 5px}' +
    '#rrGate .idrow input{width:100%;box-sizing:border-box;font:600 20px Lato,system-ui,sans-serif;padding:10px 12px;border-radius:12px;border:1.5px solid rgba(255,255,255,.35);background:rgba(255,255,255,.08);color:#fff;text-transform:lowercase}' +
    '#rrGate .dots{display:flex;gap:20px;justify-content:center;margin:0 0 40px;height:14px}#rrGate .dots i{width:14px;height:14px;border-radius:50%;border:1.5px solid rgba(255,255,255,.6);background:transparent;transition:background .12s,transform .1s}#rrGate .dots i.on{background:#fff;border-color:#fff;transform:scale(1.05)}#rrGate .dots.err i{background:#FF453A;border-color:#FF453A;transform:scale(1.1)}' +
    '#rrGate .msg{width:290px;max-width:100%;height:20px;font-weight:700;font-size:13px;margin:22px 0 0;color:#FF453A;overflow:hidden;white-space:nowrap;text-overflow:ellipsis}' +
    '#rrGate .pad{display:grid;grid-template-columns:repeat(3,78px);gap:14px 20px;margin:0 auto;width:274px}' +
    '#rrGate .pad button{width:78px;height:78px;border-radius:50%;border:0;background:rgba(255,255,255,.175);-webkit-backdrop-filter:blur(20px) saturate(180%);backdrop-filter:blur(20px) saturate(180%);color:#fff;display:flex;align-items:center;justify-content:center;padding:0;font-weight:300;font-size:32px;line-height:1;cursor:pointer;-webkit-tap-highlight-color:transparent;user-select:none;-webkit-user-select:none;touch-action:manipulation;font-family:Lato,system-ui,sans-serif;transition:background .08s,color .08s}' +
    '#rrGate .pad button:active,#rrGate .pad button.pressed{background:rgba(255,255,255,.58);color:#000}#rrGate .pad button.d{font-size:28px;font-weight:400}#rrGate .pad button:focus-visible{outline:2px solid #fff;outline-offset:3px}' +
    '#rrGate .face svg{display:block}#rrGate .face .scan{opacity:0}#rrGate .face.off{opacity:.5}#rrGate .face.ready{background:rgba(20,147,255,.30);box-shadow:0 0 0 1.5px rgba(20,147,255,.65),0 0 22px rgba(20,147,255,.45);animation:rrpulse 2.6s ease-in-out infinite}#rrGate .face.ready .scan{opacity:.95;animation:rrscan 2s ease-in-out infinite}' +
    '@keyframes rrscan{0%,100%{transform:translateY(0)}50%{transform:translateY(14px)}}@keyframes rrpulse{0%,100%{box-shadow:0 0 0 1.5px rgba(20,147,255,.65),0 0 14px rgba(20,147,255,.30)}50%{box-shadow:0 0 0 1.5px rgba(20,147,255,.9),0 0 28px rgba(20,147,255,.6)}}@media(prefers-reduced-motion:reduce){#rrGate .face.ready,#rrGate .face.ready .scan{animation:none}}' +
    '#rrGate .linkb{position:absolute;left:50%;transform:translateX(-50%);bottom:max(14px,env(safe-area-inset-bottom,14px));white-space:nowrap}#rrGate .msg.ok{color:rgba(255,255,255,.7)}#rrGate .skip,#rrGate .linkb{background:none;border:0;color:rgba(255,255,255,.45);font:600 13px Lato,system-ui,sans-serif;text-decoration:underline;cursor:pointer;padding:10px;margin-top:10px}' +
    '#rrGate .offer{position:absolute;left:50%;bottom:18px;transform:translateX(-50%);background:#12243a;border:1.5px solid rgba(20,147,255,.4);border-radius:16px;padding:16px 22px;width:min(300px,calc(100% - 32px));box-sizing:border-box;text-align:center;box-shadow:0 12px 40px rgba(0,0,0,.5)}#rrGate .offer b{display:block;font-size:14px;margin-bottom:12px}#rrGate .offer .row{display:flex;gap:10px;justify-content:center}#rrGate .offer button{border:0;border-radius:10px;padding:9px 20px;font:700 13px Lato,system-ui,sans-serif;cursor:pointer}#rrGate .offer .yes{background:#1493FF;color:#fff}#rrGate .offer .no{background:rgba(255,255,255,.1);color:rgba(255,255,255,.7)}#rrGate .offer small{display:block;color:#ffb84d;font-size:12.5px;margin-top:8px}' +
    '@media(max-height:700px){#rrGate .in{justify-content:flex-start;padding-top:max(26px,env(safe-area-inset-top,26px))}#rrGate .pad{grid-template-columns:repeat(3,66px);gap:10px 16px;width:230px}#rrGate .pad button{width:66px;height:66px;font-size:27px}#rrGate .dots{margin-bottom:24px}#rrGate p{margin-bottom:14px}#rrGate .msg{margin-top:10px}#rrGate .skip{margin-top:4px}}';

  /* Face ID / Touch ID: a passkey (WebAuthn "prf" extension) unlocks a copy of this account's sign-in password that is encrypted on this phone and can only be
     decrypted with the passkey, i.e. with your face or finger. The PIN itself is never stored. Same method as the LVR report page. */
  var BIO_SALT = enc.encode('kt-rr-bio-v1');
  function rnd(n) { return crypto.getRandomValues(new Uint8Array(n)); }
  function b64(u) { var t = ''; for (var i = 0; i < u.length; i++) t += String.fromCharCode(u[i]); return btoa(t); }
  function unb64(t) { var x = atob(t), u = new Uint8Array(x.length); for (var i = 0; i < x.length; i++) u[i] = x.charCodeAt(i); return u; }
  function bioOK() { return !!(window.PublicKeyCredential && navigator.credentials && navigator.credentials.create && window.isSecureContext && window.crypto && crypto.subtle); }
  function bioKey(email) { return 'rrBio:' + email; }
  function bioGet(email) { try { return JSON.parse(localStorage.getItem(bioKey(email)) || 'null'); } catch (e) { return null; } }
  function bioDrop(email) { try { localStorage.removeItem(bioKey(email)); } catch (e) {} }
  function prfSecret(id) {
    return navigator.credentials.get({ publicKey: { challenge: rnd(32), rpId: location.hostname, allowCredentials: [{ type: 'public-key', id: id }], userVerification: 'required', timeout: 60000, extensions: { prf: { eval: { first: BIO_SALT } } } } }).then(function (a) {
      var r = a.getClientExtensionResults(), f = r && r.prf && r.prf.results && r.prf.results.first; if (!f) throw new Error('noprf'); return new Uint8Array(f);
    });
  }
  function aes(sec) { return crypto.subtle.importKey('raw', sec, 'AES-GCM', false, ['encrypt', 'decrypt']); }
  function bioSetup(email, pw) {
    return navigator.credentials.create({ publicKey: { rp: { name: 'Key Technologies', id: location.hostname }, user: { id: rnd(16), name: 'key-rewards', displayName: 'Key Rewards' }, challenge: rnd(32),
      pubKeyCredParams: [{ type: 'public-key', alg: -7 }, { type: 'public-key', alg: -257 }], authenticatorSelection: { authenticatorAttachment: 'platform', userVerification: 'required', residentKey: 'discouraged' }, timeout: 60000, extensions: { prf: {} } } }).then(function (c) {
      var x = c.getClientExtensionResults(); if (!(x && x.prf && x.prf.enabled)) throw new Error('noprf');
      var id = new Uint8Array(c.rawId);
      return prfSecret(id).then(aes).then(function (k) { var iv = rnd(12); return crypto.subtle.encrypt({ name: 'AES-GCM', iv: iv }, k, enc.encode(pw)).then(function (ct) { localStorage.setItem(bioKey(email), JSON.stringify({ id: b64(id), iv: b64(iv), ct: b64(new Uint8Array(ct)) })); }); });
    });
  }
  function bioUnlock(email) {
    var o = bioGet(email); if (!o) return Promise.reject(new Error('none'));
    return prfSecret(unb64(o.id)).then(aes).then(function (k) { return crypto.subtle.decrypt({ name: 'AES-GCM', iv: unb64(o.iv) }, k, unb64(o.ct)); }).then(function (pt) { return signInPw(email, new TextDecoder().decode(pt)); });
  }
  var FACE = '<svg viewBox="0 0 32 32" width="34" height="34" aria-hidden="true" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M4 11V8a4 4 0 0 1 4-4h3M21 4h3a4 4 0 0 1 4 4v3M28 21v3a4 4 0 0 1-4 4h-3M11 28H8a4 4 0 0 1-4-4v-3"/><path d="M12 12.5v2.2M20 12.5v2.2M16 12.5v5.2h-1.7M12 21.2c2.4 2 5.6 2 8 0"/><path class="scan" d="M7 9h18" stroke-width="1.4"/></svg>';

  function gate(o) {
    var old = document.getElementById('rrGate'); if (old) old.remove();
    if (!document.getElementById('rrGateCss')) { var s = document.createElement('style'); s.id = 'rrGateCss'; s.textContent = css; document.head.appendChild(s); }
    var g = document.createElement('div'); g.id = 'rrGate'; g.setAttribute('role', 'dialog'); g.setAttribute('aria-label', o.title);
    var inn = document.createElement('div'); inn.className = 'in'; g.appendChild(inn);
    function mk(tag, cls, txt) { var e = document.createElement(tag); if (cls) e.className = cls; if (txt != null) e.textContent = txt; return e; }
    inn.appendChild(mk('h1', null, o.title)); inn.appendChild(mk('p', null, o.sub || 'Type your 6-digit PIN.'));
    var idIn = null;
    if (o.askId) { var row = mk('div', 'idrow'), lb = mk('label', null, o.askId.label); lb.setAttribute('for', 'rrId'); idIn = mk('input'); idIn.id = 'rrId'; idIn.setAttribute('autocomplete', 'off'); idIn.setAttribute('autocapitalize', 'none'); idIn.setAttribute('spellcheck', 'false'); idIn.maxLength = 20; idIn.placeholder = o.askId.placeholder || ''; try { var last = localStorage.getItem('rrLastId'); if (last) idIn.value = last; } catch (e) {} row.appendChild(lb); row.appendChild(idIn); inn.appendChild(row); }
    var dots = mk('div', 'dots'); for (var i = 0; i < 6; i++) dots.appendChild(mk('i')); inn.appendChild(dots);
    var msg = mk('div', 'msg'); msg.setAttribute('role', 'alert');
    var pad = mk('div', 'pad');
    var pin = '', busy = false, lastPw = null, lastEmail = null;
    function paintDots() { var d = dots.children; for (var i = 0; i < 6; i++) d[i].className = i < pin.length ? 'on' : ''; }
    function bad(t) { msg.className = 'msg'; msg.textContent = t; dots.classList.add('err'); setTimeout(function () { pin = ''; dots.classList.remove('err'); paintDots(); }, 700); }
    function who() {
      if (!o.askId) return { email: o.email, salt: o.salt };
      var id = idIn.value.trim().toLowerCase(); if (!/^[a-z][a-z0-9]{0,19}$/.test(id)) return null;
      var m = o.askId.make(id); return { email: m.email, salt: m.salt, id: id };
    }
    function done() { g.remove(); document.body.style.overflow = ''; o.onOK(); }
    function offer() {
      var no = false; try { no = !!localStorage.getItem('rrBioNo'); } catch (e) {}
      if (!bioOK() || no || !lastPw || bioGet(lastEmail)) { done(); return; }
      var d = mk('div', 'offer'); d.setAttribute('role', 'dialog'); d.setAttribute('aria-label', 'Use Face ID next time'); d.appendChild(mk('b', null, 'Use Face ID next time?'));
      var r = mk('div', 'row'), y = mk('button', 'yes', 'Set up'), n = mk('button', 'no', 'Not now'); y.type = n.type = 'button'; r.appendChild(y); r.appendChild(n); d.appendChild(r);
      var sm = mk('small', null, ''); d.appendChild(sm); g.appendChild(d);
      n.addEventListener('click', function () { try { localStorage.setItem('rrBioNo', '1'); } catch (e) {} lastPw = null; done(); });
      y.addEventListener('click', function () { bioSetup(lastEmail, lastPw).then(function () { lastPw = null; done(); }).catch(function (e) { sm.textContent = /noprf/.test(String(e && e.message)) ? 'This phone cannot do Face ID for this page yet. Keep using your PIN.' : 'Face ID was not set up.'; }); });
    }
    function press(k) {
      if (busy) return;
      if (k === 'del') { pin = pin.slice(0, -1); paintDots(); return; }
      if (pin.length >= 6) return;
      pin += k; msg.textContent = ''; msg.className = 'msg'; paintDots();
      if (pin.length === 6) submit();
    }
    function submit() {
      var w = who(); if (!w) { bad('Type your restaurant ID first (like w1).'); return; }
      if (w.id) { try { localStorage.setItem('rrLastId', w.id); } catch (e) {} }
      busy = true; msg.textContent = 'Checking...'; msg.className = 'msg ok';
      derive(pin, w.salt).then(function (pw) { lastPw = pw; lastEmail = w.email; return signInPw(w.email, pw); })
        .then(function () { offer(); })
        .catch(function (e) { bad(e && e.message ? e.message : 'Could not check the PIN. Try again.'); })
        .then(function () { busy = false; });
    }
    function keyBtn(k) { var b = mk('button', null, k); b.type = 'button'; b.setAttribute('aria-label', k); b.addEventListener('click', function () { press(k); }); return b; }
    ['1', '2', '3', '4', '5', '6', '7', '8', '9'].forEach(function (k) { pad.appendChild(keyBtn(k)); });
    var fb = mk('button', 'face'); fb.type = 'button'; fb.innerHTML = FACE; pad.appendChild(fb);
    pad.appendChild(keyBtn('0'));
    var dl = mk('button', 'd', '⌫'); dl.type = 'button'; dl.setAttribute('aria-label', 'Delete the last digit'); dl.addEventListener('click', function () { press('del'); }); pad.appendChild(dl);
    function paintFace() {
      var w = who(), ready = bioOK() && !!(w && bioGet(w.email));
      fb.classList.toggle('ready', ready); fb.classList.toggle('off', !ready);
      fb.setAttribute('aria-label', ready ? 'Open with Face ID or Touch ID' : 'Face ID or Touch ID (turn it on after your first PIN sign-in)');
      if (off) off.hidden = !ready;
    }
    fb.addEventListener('click', function () {
      if (busy) return; msg.textContent = '';
      var w = who(); if (!w) { msg.textContent = 'Type your restaurant ID first (like w1).'; return; }
      if (!bioOK()) { msg.textContent = 'Face ID is not available in this browser.'; return; }
      if (!bioGet(w.email)) { msg.textContent = 'Enter your PIN once, then you can turn on Face ID.'; return; }
      busy = true;
      bioUnlock(w.email).then(function () { done(); }).catch(function (e) {
        var m = String(e && e.message), nm = String(e && e.name);
        if (/INVALID|not right|PASSWORD/i.test(m)) { bioDrop(w.email); paintFace(); msg.textContent = 'Face ID needs to be set up again. Use your PIN.'; }
        else if (!/NotAllowed|abort|cancel/i.test(nm + m)) msg.textContent = 'Face ID did not work. Use your PIN.';
      }).then(function () { busy = false; });
    });
    inn.appendChild(pad); inn.appendChild(msg);
    var off = null;
    if (bioOK()) { off = mk('button', 'linkb', 'Turn off Face ID on this phone'); off.type = 'button'; off.hidden = true; off.addEventListener('click', function () { var w = who(); if (w) bioDrop(w.email); try { localStorage.removeItem('rrBioNo'); } catch (e) {} paintFace(); msg.textContent = 'Face ID is off for this phone.'; }); inn.appendChild(off); }
    if (idIn) idIn.addEventListener('input', paintFace);
    if (o.onSkip) { var sk = mk('button', 'skip', o.onSkip.label); sk.type = 'button'; sk.addEventListener('click', function () { g.remove(); document.body.style.overflow = ''; o.onSkip.fn(); }); inn.appendChild(sk); }
    document.addEventListener('keydown', function kd(e) {
      if (!document.getElementById('rrGate')) { document.removeEventListener('keydown', kd); return; }
      if (e.metaKey || e.ctrlKey || e.altKey || (idIn && document.activeElement === idIn)) return;
      if (/^[0-9]$/.test(e.key)) press(e.key); else if (e.key === 'Backspace') press('del');
    });
    document.body.appendChild(g); document.body.style.overflow = 'hidden'; paintFace();
    if (idIn && !idIn.value) idIn.focus();
  }
  window.RR = { DB: DB, derive: derive, signIn: signIn, token: token, db: db, signedIn: signedIn, email: email, signOut: signOut, gate: gate,
    TREASURER: { email: 'treasurer@kt-rr.invalid', salt: 'kt-rr-treasurer-v1' }, restaurant: function (id) { return { email: 'rr-' + id + '@kt-rr.invalid', salt: 'kt-rr-restaurant-v1:' + id }; },
    key: function (n) { return 'e' + ('0000000' + n).slice(-7); } };
})();
