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
     redemptions/<id>         { mkey, rid, offer, rewards, at }   written once, owner only
   The split rule: share = min( floor(pool / approved), cap ); issued = share * approved; the leftover is never issued. */
(function (root) {
  'use strict';
  var KR = { MIN_OFFER: 15, MAX_POOL: 1000000 };
  var BASE = 'key_rewards';

  // ---------- pure helpers ----------
  KR.split = function (pool, cap, n) {
    pool = Math.floor(+pool); cap = Math.floor(+cap); n = Math.floor(+n);
    if (!(pool >= 1) || !(cap >= 1) || !(n >= 1)) return { share: 0, issued: 0, leftover: Math.max(0, pool || 0), approved: Math.max(0, n || 0) };
    var share = Math.min(Math.floor(pool / n), cap);
    return { share: share, issued: share * n, leftover: pool - share * n, approved: n };
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
      var rec = { rid: e.rid, title: String(e.title || 'Event').trim().slice(0, 80) || 'Event', pool: pool, cap: cap, opensAt: o, closesAt: c, status: 'draft', createdAt: now() };
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
    api.closeEvent = function (eid) {
      return Promise.all([api.getEvent(eid), api.listCheckins(eid)]).then(function (r) {
        var ev = r[0], cks = r[1];
        if (!ev) throw new Error('Event not found.');
        if (ev.status === 'closed') throw new Error('This event is already closed.');
        if (ev.status !== 'open') throw new Error('Open the event before closing it.');
        var ok = cks.filter(function (x) { return x.status === 'approved'; });
        var s = KR.split(ev.pool, ev.cap, ok.length), t = now(), up = {};
        ok.forEach(function (x) { if (s.share > 0) up['shares/' + eid + '/' + x.mkey] = { rewards: s.share, at: t }; });
        up['events/' + eid + '/status'] = 'closed'; up['events/' + eid + '/closedAt'] = t;
        up['events/' + eid + '/approvedCount'] = s.approved; up['events/' + eid + '/share'] = s.share;
        up['events/' + eid + '/issued'] = s.issued; up['events/' + eid + '/leftover'] = s.leftover;
        return store.update(BASE, up).then(function () { return Object.assign({ eventId: eid, pool: ev.pool, cap: ev.cap, rejected: cks.filter(function (x) { return x.status === 'rejected'; }).length, pending: cks.filter(function (x) { return x.status === 'pending'; }).length }, s); });
      });
    };
    api.getShare = function (eid, mkey) { return store.get(P('shares/' + eid + '/' + mkey)); };

    // A member's balance in this ledger = shares received - redemptions (owner/staff view; needs the owner to read all events)
    api.balanceOf = function (mkey) {
      return Promise.all([api.listEvents(), store.get(P('redemptions'))]).then(function (r) {
        var closed = r[0].filter(function (e) { return e.status === 'closed' && e.issued > 0; });
        return Promise.all(closed.map(function (e) { return api.getShare(e.id, mkey); })).then(function (sh) {
          var got = sh.reduce(function (a, s) { return a + (s ? s.rewards : 0); }, 0);
          var used = list(r[1]).filter(function (x) { return x.mkey === mkey; }).reduce(function (a, x) { return a + x.rewards; }, 0);
          return { received: got, redeemed: used, available: got - used };
        });
      });
    };
    api.redeem = function (o) {
      var rewards = +o.rewards;
      if (!isInt(rewards) || rewards < KR.MIN_OFFER) return Promise.reject(new Error('Every offer is at least ' + KR.MIN_OFFER + ' rewards.'));
      if (!o.mkey || !o.rid) return Promise.reject(new Error('Choose a member and a restaurant.'));
      return api.balanceOf(o.mkey).then(function (b) {
        if (b.available < rewards) throw new Error('Not enough rewards: this member has ' + b.available + '.');
        var id = 'x' + KR.newKey(10), rec = { mkey: o.mkey, rid: o.rid, offer: String(o.offer || 'Free food offer').slice(0, 80), rewards: rewards, at: now() };
        return store.set(P('redemptions/' + id), rec).then(function () { return Object.assign({ id: id }, rec); });
      });
    };
    api.listRedemptions = function () { return store.get(P('redemptions')).then(list).then(function (a) { return a.sort(function (x, y) { return y.at - x.at; }); }); };

    api.summary = function () {
      return Promise.all([api.listRestaurants(), api.listEvents(), store.get(P('checkins')), api.listRedemptions()]).then(function (r) {
        var rests = r[0], evs = r[1], ck = r[2] || {}, reds = r[3];
        var tot = { restaurants: rests.length, events: evs.length, open: 0, closed: 0, checkins: 0, approved: 0, pending: 0, rejected: 0, issued: 0, leftover: 0, redeemed: 0, outstanding: 0, pools: 0 };
        evs.forEach(function (e) {
          if (e.status === 'open') tot.open++; if (e.status === 'closed') { tot.closed++; tot.issued += e.issued || 0; tot.leftover += e.leftover || 0; tot.pools += e.pool; }
          var c = ck[e.id] || {}; Object.keys(c).forEach(function (k) { tot.checkins++; tot[c[k].status] = (tot[c[k].status] || 0) + 1; });
        });
        reds.forEach(function (x) { tot.redeemed += x.rewards; });
        tot.outstanding = Math.max(0, tot.issued - tot.redeemed);
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
                for (k = 0; k < n; k++) { (function (k) { var mk = 'demo' + KR.newKey(12); ps.push(store.set(P('checkins/' + e.id + '/' + mk), { t: e.opensAt + 60000 * (k + 1), name: firsts[k % firsts.length], status: k % 9 === 8 ? 'rejected' : 'approved' })); })(k); }
                return Promise.all(ps).then(function () { return api.closeEvent(e.id); });
              });
          });
          return c2.then(function () { return rest; });
        }).then(function (rest) { made[rest.name] = rest; });
      });
      // one event that is open right now, with pending check-ins to approve
      return chain.then(function () {
        return api.createEvent({ rid: made['Harbor Table'].id, title: 'Friday dinner rush', pool: 2000, cap: 15, opensAt: t0 - H, closesAt: t0 + 3 * H });
      }).then(function (e) {
        return api.openEvent(e.id).then(function () {
          var ps = [], k; for (k = 0; k < 7; k++) { (function (k) { ps.push(store.set(P('checkins/' + e.id + '/live' + KR.newKey(12)), { t: t0 - 50 * 60000 + k * 240000, name: firsts[(k + 3) % firsts.length], status: k < 3 ? 'approved' : 'pending' })); })(k); }
          return Promise.all(ps);
        });
      });
    };
    return api;
  };

  if (typeof module !== 'undefined' && module.exports) module.exports = KR; else root.KR = KR;
})(typeof window !== 'undefined' ? window : (typeof globalThis !== 'undefined' ? globalThis : this));
