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
  function signIn(email, pin, salt) {
    if (!window.crypto || !crypto.subtle) return Promise.reject(new Error('This browser cannot check a PIN.'));
    return Promise.all([getKey(), derive(pin, salt)]).then(function (a) {
      if (!a[0]) throw new Error('Sign-in is not set up yet.');
      return fetch(IDT + '/accounts:signInWithPassword?key=' + encodeURIComponent(a[0]), { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email: email, password: a[1], returnSecureToken: true }) });
    }).then(function (r) {
      return r.json().then(function (j) {
        if (!r.ok) { var m = (j && j.error && j.error.message) || ''; var e = new Error(/TOO_MANY/i.test(m) ? 'Too many tries. Wait a few minutes.' : 'That PIN is not right.'); e.bad = !/TOO_MANY/i.test(m); throw e; }
        st = { idToken: j.idToken, refreshToken: j.refreshToken, exp: Date.now() + (Number(j.expiresIn) || 3600) * 1000 - 60000, email: email };
        saveSt(); return st;
      });
    });
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
  /* The PIN screen is the LVR dashboard PIN screen: deep blue glow, six dots, round frosted keys with the phone-style letters, a delete arrow. */
  var css = '#rrGate{position:fixed;inset:0;z-index:2147483000;color:#fff;overflow:auto;-webkit-overflow-scrolling:touch;font:400 17px/1.4 Lato,system-ui,-apple-system,sans-serif;' +
    'background:radial-gradient(ellipse 90% 70% at 50% 30%,rgba(14,72,168,.55) 0%,transparent 65%),radial-gradient(ellipse 60% 52% at 15% 80%,rgba(0,105,230,.30) 0%,transparent 58%),radial-gradient(ellipse 55% 48% at 85% 18%,rgba(36,12,140,.35) 0%,transparent 56%),radial-gradient(ellipse 45% 38% at 68% 68%,rgba(0,180,255,.16) 0%,transparent 50%),#050b16}' +
    '#rrGate .in{min-height:100%;box-sizing:border-box;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:max(34px,env(safe-area-inset-top,34px)) 18px 30px;text-align:center}' +
    '#rrGate h1{font-size:12px;font-weight:500;letter-spacing:.04em;color:rgba(255,255,255,.4);margin:0 0 6px}#rrGate p{color:rgba(255,255,255,.55);margin:0 0 26px;font-size:14px}' +
    '#rrGate .idrow{margin:0 0 22px;text-align:left;width:260px}#rrGate .idrow label{display:block;font-size:13px;font-weight:600;color:rgba(255,255,255,.6);margin:0 0 5px}' +
    '#rrGate .idrow input{width:100%;box-sizing:border-box;font:600 20px Lato,system-ui,sans-serif;padding:10px 12px;border-radius:12px;border:1.5px solid rgba(255,255,255,.35);background:rgba(255,255,255,.08);color:#fff;text-transform:lowercase}' +
    '#rrGate .dots{display:flex;gap:20px;justify-content:center;margin:0 0 44px;height:14px}#rrGate .dots i{width:14px;height:14px;border-radius:50%;border:1.5px solid rgba(255,255,255,.6);background:transparent;transition:background .12s,transform .1s}#rrGate .dots i.on{background:#fff;border-color:#fff;transform:scale(1.05)}#rrGate .dots.err i{background:#FF453A;border-color:#FF453A;transform:scale(1.1)}' +
    '#rrGate .dots.shake{animation:rrsh .4s}@keyframes rrsh{20%,60%{transform:translateX(-8px)}40%,80%{transform:translateX(8px)}}' +
    '#rrGate .msg{min-height:22px;font-weight:600;font-size:14px;margin:18px 0 0;color:rgba(255,255,255,.85)}' +
    '#rrGate .pad{display:grid;grid-template-columns:repeat(3,78px);gap:14px 20px;margin:0 auto}' +
    '#rrGate .pad button{width:78px;height:78px;border-radius:50%;border:0;background:rgba(255,255,255,.175);-webkit-backdrop-filter:blur(20px) saturate(180%);backdrop-filter:blur(20px) saturate(180%);color:#fff;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:0;cursor:pointer;-webkit-tap-highlight-color:transparent;user-select:none;touch-action:manipulation;font-family:Lato,system-ui,sans-serif}' +
    '#rrGate .pad button:active,#rrGate .pad button.pressed{background:rgba(255,255,255,.58);color:#000}#rrGate .pad button.z{grid-column:2}#rrGate .pad button.d{font-size:28px;font-weight:400}' +
    '#rrGate .pkn{font-size:32px;font-weight:300;line-height:1;display:block;color:inherit}#rrGate .pkl{font-size:10px;font-weight:600;letter-spacing:2.5px;color:rgba(255,255,255,.9);margin-top:2px;display:block;line-height:1;text-transform:uppercase}#rrGate .pad button:active .pkl,#rrGate .pad button.pressed .pkl{color:#000}' +
    '#rrGate .skip{margin-top:26px;background:none;border:1px solid rgba(255,255,255,.25);border-radius:10px;color:rgba(255,255,255,.55);font:400 14px Lato,system-ui,sans-serif;letter-spacing:.01em;cursor:pointer;padding:8px 20px}' +
    '@media(max-height:700px){#rrGate .in{justify-content:flex-start;padding-top:max(26px,env(safe-area-inset-top,26px))}#rrGate .pad{grid-template-columns:repeat(3,66px);gap:10px 16px}#rrGate .pad button{width:66px;height:66px}#rrGate .pkn{font-size:27px}#rrGate .pkl{font-size:9px}#rrGate .dots{margin-bottom:24px}#rrGate p{margin-bottom:14px}#rrGate .msg{margin-top:10px}#rrGate .skip{margin-top:12px}}';
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
    var pin = '', busy = false;
    function paintDots() { var d = dots.children; for (var i = 0; i < 6; i++) d[i].className = i < pin.length ? 'on' : ''; }
    function bad(t) { msg.textContent = t; dots.classList.add('err'); dots.classList.remove('shake'); void dots.offsetWidth; dots.classList.add('shake'); setTimeout(function () { pin = ''; dots.classList.remove('err'); paintDots(); }, 600); }
    function press(k) {
      if (busy) return;
      if (k === 'del') { pin = pin.slice(0, -1); paintDots(); return; }
      if (pin.length >= 6) return;
      pin += k; msg.textContent = ''; paintDots();
      if (pin.length === 6) submit();
    }
    function submit() {
      var email = o.email, salt = o.salt;
      if (o.askId) { var id = idIn.value.trim().toLowerCase(); if (!/^[a-z][a-z0-9]{0,19}$/.test(id)) { bad('Type your restaurant ID first (like w1).'); return; } var m = o.askId.make(id); email = m.email; salt = m.salt; try { localStorage.setItem('rrLastId', id); } catch (e) {} }
      busy = true; msg.textContent = 'Checking...';
      signIn(email, pin, salt).then(function () { g.remove(); document.body.style.overflow = ''; o.onOK(); })
        .catch(function (e) { bad(e && e.message ? e.message : 'Could not check the PIN. Try again.'); })
        .then(function () { busy = false; });
    }
    var LET = { '1': ' ', '2': 'ABC', '3': 'DEF', '4': 'GHI', '5': 'JKL', '6': 'MNO', '7': 'PQRS', '8': 'TUV', '9': 'WXYZ', '0': '+' };
    function keyBtn(k, cls) { var b = mk('button', cls || null); b.type = 'button'; b.setAttribute('aria-label', k); b.appendChild(mk('span', 'pkn', k)); b.appendChild(mk('span', 'pkl', LET[k] === ' ' ? '\u00a0' : LET[k])); b.addEventListener('click', function () { press(k); }); return b; }
    ['1', '2', '3', '4', '5', '6', '7', '8', '9'].forEach(function (k) { pad.appendChild(keyBtn(k)); });
    pad.appendChild(keyBtn('0', 'z'));
    var dl = mk('button', 'd', '\u232b'); dl.type = 'button'; dl.setAttribute('aria-label', 'Delete the last digit'); dl.addEventListener('click', function () { press('del'); }); pad.appendChild(dl);
    inn.appendChild(pad); inn.appendChild(msg);
    if (o.onSkip) { var sk = mk('button', 'skip', o.onSkip.label); sk.type = 'button'; sk.addEventListener('click', function () { g.remove(); document.body.style.overflow = ''; o.onSkip.fn(); }); inn.appendChild(sk); }
    document.addEventListener('keydown', function kd(e) {
      if (!document.getElementById('rrGate')) { document.removeEventListener('keydown', kd); return; }
      if (e.metaKey || e.ctrlKey || e.altKey || (idIn && document.activeElement === idIn)) return;
      if (/^[0-9]$/.test(e.key)) press(e.key); else if (e.key === 'Backspace') press('del');
    });
    document.body.appendChild(g); document.body.style.overflow = 'hidden';
    if (idIn && !idIn.value) idIn.focus();
  }
  window.RR = { DB: DB, derive: derive, signIn: signIn, token: token, db: db, signedIn: signedIn, email: email, signOut: signOut, gate: gate,
    TREASURER: { email: 'treasurer@kt-rr.invalid', salt: 'kt-rr-treasurer-v1' }, restaurant: function (id) { return { email: 'rr-' + id + '@kt-rr.invalid', salt: 'kt-rr-restaurant-v1:' + id }; },
    key: function (n) { return 'e' + ('0000000' + n).slice(-7); } };
})();
