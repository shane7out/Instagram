/* Key Rewards event engine (Key Technologies). One small file used by the owner dashboard, the member check-in page,
   the public demo and the automated tests. It has NO money in it: rewards are whole numbers, they can only be used for
   free-food offers at participating restaurants, and nothing is ever paid out in cash.

   Two places to keep data (a "store"):
     KR.localStore(namespace)            SANDBOX: this browser only (or memory in tests). Nothing leaves the device.
     KR.firebaseStore(base, tokenFn, o)  LIVE: the Realtime Database under /key_rewards (needs the staged rules deployed
                                         and the owner signed in; not switched on yet).

   Data layout (all under key_rewards/):
     restaurants/<rid>        { name, city, country, active, createdAt }
     events/<eid>             { rid, title, pool, cap, opensAt, closesAt, status: draft|open|closed, createdAt,
                                approvedCount, share, issued, leftover, closedAt }          (members may read one by id)
     checkins/<eid>/<mkey>    { t, name (first name only), status: pending|approved|rejected }   (anyone may create; owner reads)
     shares/<eid>/<mkey>      { rewards, at }   written once when an event closes (a member may read their own by key)
     members/<mkey>           { name, createdAt, source: owner|event }   everybody who has a ledger (owner only)
     grants/<id>              { mkey, rewards, reason, at }   rewards the owner adds to a person by hand (write once, owner only)
     wallet/<mkey>/<id>       { kind: event|grant|use, rewards, at, expiresAt?, note }   each person's own ledger (a person reads theirs by their private code)
     chats/<mkey>/messages/<id> { from: member|owner, text, t, name? }   two-way messages; chats/<mkey>/ownerSeen and memberSeen mark what was read
     invitesBy/<mkey>         <code>   each person's one free invite (write once)
     invitesPrivate/<code>    { from: mkey }   who the invite belongs to (owner only)
     invites/<code>           { fromName, createdAt, status: open|approved|rejected, approvedAt? }   public by code
     inviteClaims/<code>      { name, key, t }   a friend joining through the invite (owner only; the friend's private code is in here)
     redemptions/<id>         { mkey, rid, offer, rewards, at }   written once, owner only
   The split rule: share = min( floor(pool / approved), cap ); issued = share * approved; the leftover is never issued. */
(function (root) {
  'use strict';
  var KR = { INVITE_REWARDS: 20, INVITE_DAYS: 30, MIN_OFFER: 15, MAX_POOL: 1000000, MAX_GRANT: 1000, DAY: 86400000, SOON_DAYS: 14, DEFAULT_EXPIRY_DAYS: 90, MAX_TEXT: 500 };
  var BASE = 'key_rewards';

  // ---------- pure helpers ----------
  KR.split = function (pool, cap, n) {
    pool = Math.floor(+pool); cap = Math.floor(+cap); n = Math.floor(+n);
    if (!(pool >= 1) || !(cap >= 1) || !(n >= 1)) return { share: 0, issued: 0, leftover: Math.max(0, pool || 0), approved: Math.max(0, n || 0) };
    var share = Math.min(Math.floor(pool / n), cap);
    return { share: share, issued: share * n, leftover: pool - share * n, approved: n };
  };
  // entries: [{kind:'event'|'grant'|'use', rewards, at, expiresAt?}]. Rewards that pass their expiry date are no longer available.
  // When a person uses rewards, the ones that expire soonest are used first.
  KR.computeBalance = function (entries, now) {
    now = now == null ? Date.now() : now;
    var lots = [], uses = [], received = 0, granted = 0, used = 0, i;
    var invited = 0;
    (entries || []).forEach(function (e) { if (e.kind === 'use') uses.push({ at: e.at, n: e.rewards }); else lots.push({ at: e.at, exp: e.expiresAt || 0, rem: e.rewards }); if (e.kind === 'event') received += e.rewards; if (e.kind === 'grant') granted += e.rewards; if (e.kind === 'invite') invited += e.rewards; if (e.kind === 'use') used += e.rewards; });
    lots.sort(function (a, b) { return a.at - b.at; }); uses.sort(function (a, b) { return a.at - b.at; });
    uses.forEach(function (u) {
      var need = u.n, ok = lots.filter(function (l) { return l.at <= u.at && l.rem > 0 && (!l.exp || l.exp > u.at); }).sort(function (a, b) { return (a.exp || 9e15) - (b.exp || 9e15); });
      for (i = 0; i < ok.length && need > 0; i++) { var take = Math.min(ok[i].rem, need); ok[i].rem -= take; need -= take; }
    });
    var out = { received: received, granted: granted, invited: invited, redeemed: used, expired: 0, available: 0, expiringSoon: 0, nextExpiry: 0, lots: [] }, by = {};
    lots.forEach(function (l) {
      if (l.rem <= 0) return;
      if (l.exp && l.exp <= now) { out.expired += l.rem; return; }
      out.available += l.rem;
      var key = l.exp ? new Date(l.exp).toISOString().slice(0, 10) : 'none'; if (!by[key]) { by[key] = { rewards: 0, expiresAt: l.exp || 0 }; out.lots.push(by[key]); } by[key].rewards += l.rem; if (l.exp && l.exp < by[key].expiresAt) by[key].expiresAt = l.exp;
      if (l.exp) { if (!out.nextExpiry || l.exp < out.nextExpiry) out.nextExpiry = l.exp; if (l.exp - now <= KR.SOON_DAYS * KR.DAY) out.expiringSoon += l.rem; }
    });
    out.lots.sort(function (a, b) { return (a.expiresAt || 9e15) - (b.expiresAt || 9e15); });   // the soonest-expiring come first, and are the first to be used
    return out;
  };
  KR.newKey = function (len) {
    var c = 'abcdefghijkmnpqrstuvwxyz23456789', s = '', i, u;
    len = len || 16;
    try { u = new Uint8Array(len); (root.crypto || {}).getRandomValues(u); for (i = 0; i < len; i++) s += c[u[i] % c.length]; return s; } catch (e) {}
    try { u = require('crypto').randomBytes(len); for (i = 0; i < len; i++) s += c[u[i] % c.length]; return s; } catch (e2) {}
    for (i = 0; i < len; i++) s += c[Math.floor(Math.random() * c.length)];
    return s;
  };
  KR.slug = function (s) { return String(s || '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 24) || 'x'; };
  KR.cleanName = function (s) { return String(s || '').replace(/[<>"&]/g, '').replace(/\s+/g, ' ').trim().slice(0, 40); };
  var isInt = function (v) { return typeof v === 'number' && isFinite(v) && Math.floor(v) === v; };

  // ---------- stores ----------
  KR.memoryStore = function () {
    var db = {};
    var walk = function (path, create) { var p = String(path).split('/').filter(Boolean), o = db, i; for (i = 0; i < p.length - 1; i++) { if (typeof o[p[i]] !== 'object' || o[p[i]] === null) { if (!create) return null; o[p[i]] = {}; } o = o[p[i]]; } return { o: o, k: p[p.length - 1] }; };
    return {
      get: function (path) { var w = walk(path, false); if (!path || !String(path).replace(/\//g, '')) return Promise.resolve(JSON.parse(JSON.stringify(db))); if (!w || w.o[w.k] === undefined) return Promise.resolve(null); return Promise.resolve(JSON.parse(JSON.stringify(w.o[w.k]))); },
      set: function (path, val) { var w = walk(path, true); w.o[w.k] = JSON.parse(JSON.stringify(val)); return Promise.resolve(); },
      update: function (path, obj) { var self = this, ks = Object.keys(obj), i, ps = []; for (i = 0; i < ks.length; i++) ps.push(self.set(String(path).replace(/\/$/, '') + '/' + ks[i], obj[ks[i]])); return Promise.all(ps).then(function () {}); },
      clear: function () { db = {}; return Promise.resolve(); }, sandbox: true
    };
  };
  KR.localStore = function (ns) {
    // Every call re-reads the browser storage first and writes it back after a change, so two tabs of the same browser
    // (the dashboard and the member check-in page) always see each other's changes.
    var key = 'kr_sandbox_' + (ns || 'default'), queue = Promise.resolve();
    var run = function (fn) { var r = queue.then(fn); queue = r.catch(function () {}); return r; };   // one operation at a time
    var open = function () {
      var mem = KR.memoryStore(), v = null;
      try { v = JSON.parse(root.localStorage.getItem(key) || 'null'); } catch (e) {}
      var ks = v && typeof v === 'object' ? Object.keys(v) : [];
      return Promise.all(ks.map(function (k) { return mem.set(k, v[k]); })).then(function () { return mem; });
    };
    var save = function (mem) { return mem.get('').then(function (v) { try { root.localStorage.setItem(key, JSON.stringify(v || {})); } catch (e) {} }); };
    return {
      get: function (p) { return run(function () { return open().then(function (m) { return m.get(p); }); }); },
      set: function (p, v) { return run(function () { return open().then(function (m) { return m.set(p, v).then(function () { return save(m); }); }); }); },
      update: function (p, o) { return run(function () { return open().then(function (m) { return m.update(p, o).then(function () { return save(m); }); }); }); },
      clear: function () { try { root.localStorage.removeItem(key); } catch (e) {} return Promise.resolve(); }, sandbox: true
    };
  };
  KR.firebaseStore = function (base, tokenFn, opts) {
    opts = opts || {};
    var f = opts.fetch || (root.fetch && root.fetch.bind(root));
    var url = function (p) { var tok = tokenFn ? tokenFn() : ''; var q = []; if (opts.query) q.push(opts.query); if (tok) q.push('auth=' + encodeURIComponent(tok)); return base.replace(/\/$/, '') + '/' + String(p).replace(/^\//, '') + '.json' + (q.length ? '?' + q.join('&') : ''); };
    var run = function (method, p, body) {
      return f(url(p), { method: method, headers: { 'Content-Type': 'application/json' }, body: body === undefined ? undefined : JSON.stringify(body) }).then(function (r) {
        if (!r.ok) { var e = new Error('HTTP ' + r.status + ' ' + method + ' ' + p); e.status = r.status; throw e; }
        return r.json();
      });
    };
    return { get: function (p) { return run('GET', p); }, set: function (p, v) { return run('PUT', p, v).then(function () {}); }, update: function (p, o) { return run('PATCH', p, o).then(function () {}); }, sandbox: false };
  };

  // ---------- the engine ----------
  KR.create = function (store, clock) {
    var now = clock || function () { return Date.now(); };
    var P = function (s) { return BASE + '/' + s; };
    var list = function (o) { return o ? Object.keys(o).map(function (k) { var v = o[k]; if (v && typeof v === 'object') { v = Object.assign({ id: k }, v); } return v; }) : []; };
    var api = { store: store };

    api.addRestaurant = function (r) {
      var name = String((r && r.name) || '').trim().slice(0, 80);
      if (!name) return Promise.reject(new Error('A restaurant needs a name.'));
      var id = 'r' + KR.slug(name).replace(/-/g, '').slice(0, 10) + KR.newKey(4);
      var rec = { name: name, city: String(r.city || '').slice(0, 60), country: String(r.country || 'US').slice(0, 2).toUpperCase(), active: true, createdAt: now() };
      return store.set(P('restaurants/' + id), rec).then(function () { return Object.assign({ id: id }, rec); });
    };
    api.listRestaurants = function () { return store.get(P('restaurants')).then(list); };

    api.createEvent = function (e) {
      var pool = +e.pool, cap = +e.cap, o = +e.opensAt, c = +e.closesAt;
      if (!e.rid) return Promise.reject(new Error('Choose a restaurant.'));
      if (!isInt(pool) || pool < 1 || pool > KR.MAX_POOL) return Promise.reject(new Error('The pool must be a whole number of rewards from 1 to ' + KR.MAX_POOL + '.'));
      if (!isInt(cap) || cap < 1 || cap > pool) return Promise.reject(new Error('The per-person cap must be a whole number from 1 up to the pool.'));
      if (!(c > o)) return Promise.reject(new Error('The check-in window must end after it starts.'));
      var id = 'e' + KR.newKey(10);
      var days = e.expiresDays == null ? KR.DEFAULT_EXPIRY_DAYS : +e.expiresDays;
      if (!isInt(days) || days < 0 || days > 3650) return Promise.reject(new Error('Rewards can expire after 1 to 3650 days, or never (0).'));
      var rec = { rid: e.rid, title: String(e.title || 'Event').trim().slice(0, 80) || 'Event', pool: pool, cap: cap, opensAt: o, closesAt: c, status: 'draft', createdAt: now(), expiresDays: days };
      return store.set(P('events/' + id), rec).then(function () { return Object.assign({ id: id }, rec); });
    };
    api.getEvent = function (eid) { return store.get(P('events/' + eid)).then(function (v) { return v ? Object.assign({ id: eid }, v) : null; }); };
    api.listEvents = function () { return store.get(P('events')).then(list).then(function (a) { return a.sort(function (x, y) { return y.createdAt - x.createdAt; }); }); };
    api.openEvent = function (eid) {
      return api.getEvent(eid).then(function (ev) {
        if (!ev) throw new Error('Event not found.');
        if (ev.status !== 'draft') throw new Error('Only a draft event can be opened.');
        return store.update(P('events/' + eid), { status: 'open' }).then(function () { return Object.assign(ev, { status: 'open' }); });
      });
    };

    // A member checks in. mkey is a private random code kept on the member's device; the name is a first name only.
    api.checkIn = function (eid, who) {
      var name = KR.cleanName(who && who.name), mkey = String((who && who.mkey) || '');
      if (!name) return Promise.resolve({ ok: false, reason: 'Please enter your first name.' });
      if (!/^[A-Za-z0-9]{12,40}$/.test(mkey)) return Promise.resolve({ ok: false, reason: 'Your member code is not valid.' });
      return api.getEvent(eid).then(function (ev) {
        if (!ev) return { ok: false, reason: 'We could not find that event.' };
        var t = now();
        if (ev.status !== 'open') return { ok: false, reason: ev.status === 'closed' ? 'This event has ended.' : 'Check-in is not open yet.' };
        if (t < ev.opensAt) return { ok: false, reason: 'Check-in has not started yet.' };
        if (t > ev.closesAt) return { ok: false, reason: 'The check-in window has closed.' };
        var rec = { t: t, name: name, status: 'pending' }, put = function () { return store.set(P('checkins/' + eid + '/' + mkey), rec).then(function () { return { ok: true }; }, function () { return { ok: false, already: true, reason: 'You may already be checked in. If you are not, please ask staff for help.' }; }); };
        // Live: guests cannot read check-ins, so the database itself refuses a second check-in with the same code (write once).
        if (!store.sandbox) return put();
        return store.get(P('checkins/' + eid + '/' + mkey)).then(function (ex) { return ex ? { ok: false, reason: 'You are already checked in.', already: true } : put(); });
      });
    };
    api.listCheckins = function (eid) { return store.get(P('checkins/' + eid)).then(function (o) { return o ? Object.keys(o).map(function (k) { return Object.assign({ mkey: k }, o[k]); }).sort(function (a, b) { return a.t - b.t; }) : []; }); };
    api.review = function (eid, mkeys, status) {
      if (['approved', 'rejected', 'pending'].indexOf(status) < 0) return Promise.reject(new Error('Unknown status.'));
      return api.getEvent(eid).then(function (ev) {
        if (!ev) throw new Error('Event not found.');
        if (ev.status === 'closed') throw new Error('The event is closed; check-ins can no longer change.');
        var up = {}; (mkeys || []).forEach(function (k) { up['checkins/' + eid + '/' + k + '/status'] = status; });
        return Object.keys(up).length ? store.update(BASE, up) : Promise.resolve();
      });
    };
    api.approveAll = function (eid) { return api.listCheckins(eid).then(function (a) { return api.review(eid, a.filter(function (x) { return x.status === 'pending'; }).map(function (x) { return x.mkey; }), 'approved'); }); };

    // Close an event and issue the shares. Only approved check-ins count. One atomic update; shares are written once.
    api.closeEvent = function (eid, opts) {
      return Promise.all([api.getEvent(eid), api.listCheckins(eid), store.get(P('members'))]).then(function (r) {
        var ev = r[0], cks = r[1], have = r[2] || {};
        if (!ev) throw new Error('Event not found.');
        if (ev.status === 'closed') throw new Error('This event is already closed.');
        if (ev.status !== 'open') throw new Error('Open the event before closing it.');
        var ok = cks.filter(function (x) { return x.status === 'approved'; });
        var s = KR.split(ev.pool, ev.cap, ok.length), t = (opts && opts.at) || now(), up = {};
        var exp = ev.expiresDays ? t + ev.expiresDays * KR.DAY : 0;
        ok.forEach(function (x) {
          if (s.share > 0) { up['shares/' + eid + '/' + x.mkey] = exp ? { rewards: s.share, at: t, expiresAt: exp } : { rewards: s.share, at: t }; up['wallet/' + x.mkey + '/ev' + eid] = exp ? { kind: 'event', rewards: s.share, at: t, expiresAt: exp, note: 'Event: ' + ev.title.slice(0, 60) } : { kind: 'event', rewards: s.share, at: t, note: 'Event: ' + ev.title.slice(0, 60) }; }
          if (!have[x.mkey]) up['members/' + x.mkey] = { name: x.name, createdAt: t, source: 'event' };
        });
        up['events/' + eid + '/status'] = 'closed'; up['events/' + eid + '/closedAt'] = t;
        up['events/' + eid + '/approvedCount'] = s.approved; up['events/' + eid + '/share'] = s.share;
        up['events/' + eid + '/issued'] = s.issued; up['events/' + eid + '/leftover'] = s.leftover;
        return store.update(BASE, up).then(function () { return Object.assign({ eventId: eid, pool: ev.pool, cap: ev.cap, rejected: cks.filter(function (x) { return x.status === 'rejected'; }).length, pending: cks.filter(function (x) { return x.status === 'pending'; }).length }, s); });
      });
    };
    api.getShare = function (eid, mkey) { return store.get(P('shares/' + eid + '/' + mkey)); };

    // People: owner-added or created when an event closes. A person's balance = event shares + hand-added grants - redemptions.
    api.addMember = function (m) {
      var name = KR.cleanName(m && m.name);
      if (!name) return Promise.reject(new Error('Please enter a first name.'));
      var mkey = (m && m.mkey) || KR.newKey(16), rec = { name: name, createdAt: now(), source: 'owner' };
      return store.set(P('members/' + mkey), rec).then(function () { return Object.assign({ mkey: mkey }, rec); });
    };
    api.renameMember = function (mkey, name) {
      name = KR.cleanName(name); if (!name) return Promise.reject(new Error('Please enter a first name.'));
      return store.get(P('members/' + mkey)).then(function (m) { if (!m) throw new Error('Person not found.'); return store.update(P('members/' + mkey), { name: name }); });
    };
    api.listMembers = function () { return store.get(P('members')).then(function (o) { return o ? Object.keys(o).map(function (k) { return Object.assign({ mkey: k }, o[k]); }) : []; }); };
    api.grant = function (g) {
      var rewards = +g.rewards, reason = String(g.reason || '').trim().slice(0, 80), days = g.expiresDays == null ? KR.DEFAULT_EXPIRY_DAYS : +g.expiresDays;
      if (!isInt(rewards) || rewards < 1 || rewards > KR.MAX_GRANT) return Promise.reject(new Error('Add a whole number of rewards from 1 to ' + KR.MAX_GRANT + '.'));
      if (!reason) return Promise.reject(new Error('Choose a reason.'));
      if (!isInt(days) || days < 0 || days > 3650) return Promise.reject(new Error('Rewards can expire after 1 to 3650 days, or never (0).'));
      return store.get(P('members/' + g.mkey)).then(function (m) {
        if (!m) throw new Error('Choose a person first.');
        var id = 'g' + KR.newKey(10), t = g.at || now(), exp = days ? t + days * KR.DAY : 0;
        var rec = { mkey: g.mkey, rewards: rewards, reason: reason, at: t }; if (exp) rec.expiresAt = exp;
        var w = { kind: 'grant', rewards: rewards, at: t, note: reason }; if (exp) w.expiresAt = exp;
        var up = {}; up['grants/' + id] = rec; up['wallet/' + g.mkey + '/' + id] = w;
        return store.update(BASE, up).then(function () { return Object.assign({ id: id }, rec); });
      });
    };
    // Everybody's totals in one pass (from each person's own wallet).
    api.ledger = function () {
      return Promise.all([api.listMembers(), store.get(P('wallet'))]).then(function (r) {
        var wal = r[1] || {}, t = now(), by = {};
        var mk = function (k, m) { var ents = Object.keys(wal[k] || {}).map(function (i) { return wal[k][i]; }), b = KR.computeBalance(ents, t), last = ents.reduce(function (a, e) { return Math.max(a, e.at || 0); }, m ? m.createdAt || 0 : 0);
          return Object.assign({ mkey: k, name: m ? m.name : 'Unknown', createdAt: m ? m.createdAt : 0, source: m ? m.source : '', last: last }, b); };
        r[0].forEach(function (m) { by[m.mkey] = mk(m.mkey, m); });
        Object.keys(wal).forEach(function (k) { if (!by[k]) by[k] = mk(k, null); });
        return Object.keys(by).map(function (k) { return by[k]; });
      });
    };
    api.walletOf = function (mkey) {
      return store.get(P('wallet/' + mkey)).then(function (w) {
        var ents = Object.keys(w || {}).map(function (i) { return Object.assign({ id: i }, w[i]); });
        return { entries: ents.sort(function (a, b) { return b.at - a.at; }), balance: KR.computeBalance(ents, now()) };
      });
    };
    api.balanceOf = function (mkey) {
      return api.walletOf(mkey).then(function (w) { var b = w.balance; return { received: b.received + b.granted, redeemed: b.redeemed, available: b.available, expired: b.expired, expiringSoon: b.expiringSoon, nextExpiry: b.nextExpiry }; });
    };
    // A person's recent activity (newest first)
    api.historyOf = function (mkey) {
      return api.walletOf(mkey).then(function (w) { return w.entries.map(function (e) { return { at: e.at, rewards: e.kind === 'use' ? -e.rewards : e.rewards, text: e.note || (e.kind === 'event' ? 'Event' : e.kind === 'grant' ? 'Added' : 'Free food use'), expiresAt: e.expiresAt || 0 }; }); });
    };
    api.redeem = function (o) {
      var rewards = +o.rewards;
      if (!isInt(rewards) || rewards < KR.MIN_OFFER) return Promise.reject(new Error('Every offer is at least ' + KR.MIN_OFFER + ' rewards.'));
      if (!o.mkey || !o.rid) return Promise.reject(new Error('Choose a member and a restaurant.'));
      return api.balanceOf(o.mkey).then(function (b) {
        if (b.available < rewards) throw new Error('Not enough rewards: this person has ' + b.available + ' that have not expired.');
        var id = 'x' + KR.newKey(10), t = now(), offer = String(o.offer || 'Free food offer').slice(0, 80), rec = { mkey: o.mkey, rid: o.rid, offer: offer, rewards: rewards, at: t };
        var up = {}; up['redemptions/' + id] = rec; up['wallet/' + o.mkey + '/' + id] = { kind: 'use', rewards: rewards, at: t, note: 'Free food: ' + offer.slice(0, 60) };
        return store.update(BASE, up).then(function () { return Object.assign({ id: id }, rec); });
      });
    };

    // ---------- invite a friend (one free invite each; both earn INVITE_REWARDS that expire in INVITE_DAYS days once Shane approves) ----------
    api.myInvite = function (mkey) {
      return store.get(P('invitesBy/' + mkey)).then(function (code) { return code ? store.get(P('invites/' + code)).then(function (inv) { return inv ? Object.assign({ code: code }, inv) : null; }) : null; });
    };
    api.createInvite = function (mkey, fromName) {
      return api.myInvite(mkey).then(function (ex) {
        if (ex) return ex;
        var code = KR.newKey(8), nm = KR.cleanName(fromName) || 'A friend', rec = { fromName: nm, createdAt: now(), status: 'open' };
        return store.set(P('invitesBy/' + mkey), code)
          .then(function () { return store.set(P('invitesPrivate/' + code), { from: mkey }); })
          .then(function () { return store.set(P('invites/' + code), rec); })
          .then(function () { return Object.assign({ code: code }, rec); });
      });
    };
    api.getInvite = function (code) { return store.get(P('invites/' + code)).then(function (v) { return v ? Object.assign({ code: code }, v) : null; }); };
    // The friend joins through the link. Nothing is earned until Shane approves.
    api.claimInvite = function (code, who) {
      var name = KR.cleanName(who && who.name), key = String((who && who.key) || '');
      if (!name) return Promise.resolve({ ok: false, reason: 'Please enter your first name.' });
      if (!/^[A-Za-z0-9]{12,40}$/.test(key)) return Promise.resolve({ ok: false, reason: 'Your member code is not valid.' });
      return api.getInvite(code).then(function (inv) {
        if (!inv) return { ok: false, reason: 'We could not find that invite.' };
        if (inv.status !== 'open') return { ok: false, reason: 'This invite has already been used.' };
        var put = function () { return store.set(P('inviteClaims/' + code), { name: name, key: key, t: now() }).then(function () { return { ok: true }; }, function () { return { ok: false, reason: 'This invite may already be used, or you may already be a member.' }; }); };
        // Live: the database itself refuses a second claim (write once) and refuses someone who is already a member. In the sandbox we check here.
        if (!store.sandbox) return put();
        return Promise.all([store.get(P('inviteClaims/' + code)), store.get(P('members/' + key)), store.get(P('invitesPrivate/' + code))]).then(function (r) { if (r[0]) return { ok: false, reason: 'Someone has already joined with this invite.' }; if (r[1] || (r[2] && r[2].from === key)) return { ok: false, reason: 'You are already a member, so this invite cannot be used.' }; return put(); });
      });
    };
    // Owner: invites with a friend waiting for approval.
    api.pendingInvites = function () {
      return Promise.all([store.get(P('inviteClaims')), store.get(P('invites'))]).then(function (r) {
        var cl = r[0] || {}, inv = r[1] || {};
        return Object.keys(cl).filter(function (c) { return inv[c] && inv[c].status === 'open'; }).map(function (c) { return { code: c, fromName: inv[c].fromName, friendName: cl[c].name, t: cl[c].t }; }).sort(function (a, b) { return a.t - b.t; });
      });
    };
    api.approveInvite = function (code) {
      return Promise.all([store.get(P('inviteClaims/' + code)), store.get(P('invitesPrivate/' + code)), store.get(P('invites/' + code))]).then(function (r) {
        var cl = r[0], pv = r[1], inv = r[2];
        if (!cl || !pv || !inv) throw new Error('Invite not found.');
        if (inv.status !== 'open') throw new Error('This invite was already decided.');
        return Promise.all([store.get(P('members/' + cl.key)), store.get(P('members/' + pv.from))]).then(function (m) {
          if (m[0]) throw new Error('That person is already a member.');
          var t = now(), exp = t + KR.INVITE_DAYS * KR.DAY, up = {}, friendName = cl.name, fromName = (m[1] && m[1].name) || inv.fromName || 'a friend';
          up['members/' + cl.key] = { name: friendName, createdAt: t, source: 'invite' };
          up['wallet/' + cl.key + '/inv' + code] = { kind: 'invite', rewards: KR.INVITE_REWARDS, at: t, expiresAt: exp, note: 'Invited by ' + fromName };
          up['wallet/' + pv.from + '/inv' + code] = { kind: 'invite', rewards: KR.INVITE_REWARDS, at: t, expiresAt: exp, note: 'Friend joined: ' + friendName };
          up['invites/' + code + '/status'] = 'approved'; up['invites/' + code + '/approvedAt'] = t;
          return store.update(BASE, up).then(function () { return { friend: friendName, inviter: fromName, rewards: KR.INVITE_REWARDS, expiresAt: exp }; });
        });
      });
    };
    api.rejectInvite = function (code) {
      return store.get(P('invites/' + code)).then(function (inv) { if (!inv || inv.status !== 'open') throw new Error('This invite was already decided.'); var up = {}; up['invites/' + code + '/status'] = 'rejected'; up['invites/' + code + '/approvedAt'] = now(); return store.update(BASE, up); });
    };

    // ---------- messages (two-way) ----------
    api.sendMessage = function (mkey, m) {
      var text = String((m && m.text) || '').trim().slice(0, KR.MAX_TEXT), from = m && m.from;
      if (from !== 'member' && from !== 'owner') return Promise.reject(new Error('Unknown sender.'));
      if (!text) return Promise.reject(new Error('Type a message first.'));
      var id = 'm' + KR.newKey(10), rec = { from: from, text: text, t: now() }; var nm = KR.cleanName(m.name); if (from === 'member' && nm) rec.name = nm;
      return store.set(P('chats/' + mkey + '/messages/' + id), rec).then(function () { return Object.assign({ id: id }, rec); });
    };
    api.listThread = function (mkey) { return store.get(P('chats/' + mkey + '/messages')).then(function (o) { return o ? Object.keys(o).map(function (k) { return Object.assign({ id: k }, o[k]); }).sort(function (a, b) { return a.t - b.t; }) : []; }); };
    // Owner: every conversation, newest first, with how many messages from the person are unread.
    api.threads = function () {
      return Promise.all([store.get(P('chats')), api.listMembers()]).then(function (r) {
        var chats = r[0] || {}, names = {}; r[1].forEach(function (m) { names[m.mkey] = m.name; });
        return Object.keys(chats).map(function (k) {
          var c = chats[k], msgs = Object.keys(c.messages || {}).map(function (i) { return c.messages[i]; }).sort(function (a, b) { return a.t - b.t; }), last = msgs[msgs.length - 1];
          if (!last) return null;
          var nm = names[k] || (msgs.filter(function (m) { return m.name; })[0] || {}).name || 'Guest', seen = c.ownerSeen || 0;
          return { mkey: k, name: nm, last: last, unread: msgs.filter(function (m) { return m.from === 'member' && m.t > seen; }).length, count: msgs.length };
        }).filter(Boolean).sort(function (a, b) { return b.last.t - a.last.t; });
      });
    };
    api.markSeen = function (mkey, who) { return store.set(P('chats/' + mkey + '/' + (who === 'owner' ? 'ownerSeen' : 'memberSeen')), now()); };
    api.memberUnread = function (mkey) { return store.get(P('chats/' + mkey)).then(function (c) { c = c || {}; var seen = c.memberSeen || 0; return Object.keys(c.messages || {}).filter(function (i) { return c.messages[i].from === 'owner' && c.messages[i].t > seen; }).length; }); };
    api.listRedemptions = function () { return store.get(P('redemptions')).then(list).then(function (a) { return a.sort(function (x, y) { return y.at - x.at; }); }); };

    api.summary = function () {
      return Promise.all([api.listRestaurants(), api.listEvents(), store.get(P('checkins')), api.listRedemptions(), api.listMembers(), store.get(P('grants')), store.get(P('wallet'))]).then(function (r) {
        var rests = r[0], evs = r[1], ck = r[2] || {}, reds = r[3], gr = r[5] || {}, wal = r[6] || {};
        var inv = 0; Object.keys(wal).forEach(function (k) { Object.keys(wal[k]).forEach(function (i) { if (wal[k][i].kind === 'invite') inv += wal[k][i].rewards; }); });
        var tot = { invited: inv, members: r[4].length, granted: Object.keys(gr).reduce(function (a, k) { return a + gr[k].rewards; }, 0), restaurants: rests.length, events: evs.length, open: 0, closed: 0, checkins: 0, approved: 0, pending: 0, rejected: 0, issued: 0, leftover: 0, redeemed: 0, outstanding: 0, pools: 0 };
        evs.forEach(function (e) {
          if (e.status === 'open') tot.open++; if (e.status === 'closed') { tot.closed++; tot.issued += e.issued || 0; tot.leftover += e.leftover || 0; tot.pools += e.pool; }
          var c = ck[e.id] || {}; Object.keys(c).forEach(function (k) { tot.checkins++; tot[c[k].status] = (tot[c[k].status] || 0) + 1; });
        });
        reds.forEach(function (x) { tot.redeemed += x.rewards; });
        tot.outstanding = Math.max(0, tot.issued + tot.granted + tot.invited - tot.redeemed);
        var by = {};
        rests.forEach(function (x) { by[x.id] = { id: x.id, name: x.name, city: x.city, events: 0, issued: 0, redeemed: 0 }; });
        evs.forEach(function (e) { if (by[e.rid] && e.status === 'closed') { by[e.rid].events++; by[e.rid].issued += e.issued || 0; } });
        reds.forEach(function (x) { if (by[x.rid]) by[x.rid].redeemed += x.rewards; });
        return { totals: tot, restaurants: Object.keys(by).map(function (k) { by[k].outstanding = Math.max(0, by[k].issued - by[k].redeemed); return by[k]; }), events: evs, redemptions: reds };
      });
    };

    // SANDBOX ONLY: fictional restaurants, events and check-ins so the dashboard has something to show.
    api.seedDemo = function () {
      var t0 = now(), H = 3600000, D = 86400000, firsts = ['Ava', 'Ben', 'Cora', 'Dev', 'Eli', 'Fay', 'Gus', 'Hana', 'Ian', 'Jo', 'Kai', 'Lia', 'Max', 'Nia', 'Oz', 'Pia', 'Quin', 'Rae', 'Sam', 'Tess'];
      var specs = [['Harbor Table', 'Las Vegas', 'US', [[2000, 12, 18, 6], [1500, 10, 11, 9]]], ['Cedar Grill', 'Las Vegas', 'US', [[1000, 8, 14, 20]]], ['Blue Door Cafe', 'Henderson', 'US', [[600, 6, 9, 33]]]];
      var chain = Promise.resolve(), made = {};
      specs.forEach(function (sp) {
        chain = chain.then(function () { return api.addRestaurant({ name: sp[0], city: sp[1], country: sp[2] }); }).then(function (rest) {
          var c2 = Promise.resolve();
          sp[3].forEach(function (ev, i) {
            c2 = c2.then(function () { return api.createEvent({ rid: rest.id, title: sp[0] + ' guest night ' + (i + 1), pool: ev[0], cap: ev[1], opensAt: t0 - (ev[3] + 1) * D, closesAt: t0 - ev[3] * D + 4 * H }); })
              .then(function (e) { return api.openEvent(e.id).then(function () { return e; }); })
              .then(function (e) {
                var n = ev[2], ps = [], k;
                for (k = 0; k < n; k++) { (function (k) { var mk = 'demo' + KR.newKey(12); ps.push(store.set(P('checkins/' + e.id + '/' + mk), { t: e.opensAt + 60000 * (k + 1), name: firsts[k % firsts.length] + ' ' + String.fromCharCode(65 + ((Math.floor(k / firsts.length) * 7 + k * 3) % 26)), status: k % 9 === 8 ? 'rejected' : 'approved' })); })(k); }
                return Promise.all(ps).then(function () { return api.closeEvent(e.id, { at: e.closesAt }); });
              });
          });
          return c2.then(function () { return rest; });
        }).then(function (rest) { made[rest.name] = rest; });
      });
      // a few people the owner added by hand, with welcome rewards
      chain = chain.then(function () { var nm = ['Maria', 'Chris', 'Priya', 'Tom', 'Zoe', 'Luis', 'Nina'], c3 = Promise.resolve(); nm.forEach(function (n, i) { c3 = c3.then(function () { return api.addMember({ name: n }); }).then(function (m) { return store.update(P('members/' + m.mkey), { createdAt: t0 - i * 5 * D - H }).then(function () { return api.grant({ mkey: m.mkey, rewards: 10 + i * 5, reason: 'Welcome', at: t0 - i * 5 * D, expiresDays: i === 2 ? 20 : i === 4 ? 7 : 90 }); }); }); }); return c3; });
      chain = chain.then(function () { return api.seedWalletDemo(); });
      // one event that is open right now, with pending check-ins to approve
      return chain.then(function () {
        return api.createEvent({ rid: made['Harbor Table'].id, title: 'Friday dinner rush', pool: 2000, cap: 15, opensAt: t0 - H, closesAt: t0 + 3 * H });
      }).then(function (e) {
        return api.openEvent(e.id).then(function () {
          var ps = [], k; for (k = 0; k < 7; k++) { (function (k) { ps.push(store.set(P('checkins/' + e.id + '/live' + KR.newKey(12)), { t: t0 - 50 * 60000 + k * 240000, name: firsts[(k + 3) % firsts.length] + ' ' + String.fromCharCode(66 + k), status: k < 3 ? 'approved' : 'pending' })); })(k); }
          return Promise.all(ps);
        });
      });
    };
    // SANDBOX ONLY: a member with rewards that expire on four different dates (25 + 30 + 36 + 45 = 136).
    api.seedWalletDemo = function () {
      var t0 = now(), D = KR.DAY;
      return api.listMembers().then(function (ms) {
        var have = ms.filter(function (m) { return m.name === 'Dana' && m.source === 'owner'; })[0];
        if (have) return have;
        return api.addMember({ name: 'Dana' }).then(function (m) {
          var lots = [[25, 84, 90], [30, 69, 90], [36, 30, 90], [45, 60, 180]], c = store.update(P('members/' + m.mkey), { createdAt: t0 - 85 * D });
          lots.forEach(function (l) { c = c.then(function () { return api.grant({ mkey: m.mkey, rewards: l[0], reason: l[0] === 25 ? 'Welcome' : l[0] === 30 ? 'Thank you' : l[0] === 36 ? 'Event' : 'Thank you', at: t0 - l[1] * D, expiresDays: l[2] }); }); });
          return c.then(function () { return m; });
        });
      });
    };
    return api;
  };

  if (typeof module !== 'undefined' && module.exports) module.exports = KR; else root.KR = KR;
})(typeof window !== 'undefined' ? window : (typeof globalThis !== 'undefined' ? globalThis : this));
