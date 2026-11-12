// MEMBER DATA PROTECTION steps 5-6 helpers (plan: docs/key-integration/MEMBER_DATA_PLAN.md). Used by member-data-cutover.sh on YOUR Mac with the owner sign-in token.
// Prints only COUNTS, never names, phones, emails or tokens. Every write is "add if missing" except strip(), which only runs for members whose hidden copy was re-read and matched.
const crypto = require('crypto');
const FIELDS = ['phone', 'email', 'birthday', 'anniversary'];
const digits = s => String(s || '').replace(/\D/g, '');
const sha = s => crypto.createHash('sha256').update(s).digest('hex');
const hashesFor = m => { const out = []; const d = digits(m.phone); if (d.length >= 7) out.push(sha('p:' + d)); const e = String(m.email || '').trim().toLowerCase(); if (e) out.push(sha('e:' + e)); return out; };
const shortName = n => { const p = String(n || '').trim().split(/\s+/).filter(Boolean); return (!p.length ? 'Member' : p.length === 1 ? p[0] : p[0] + ' ' + p[p.length - 1].charAt(0).toUpperCase() + '.').slice(0, 40); };

module.exports = function make(o) {
  const DB = o.DB, F = o.fetch, auth = '?auth=' + encodeURIComponent(o.idToken), log = o.log || console.log;
  const J = { 'Content-Type': 'application/json' };
  const enc = encodeURIComponent;
  const get = async p => { const r = await F(DB + p + '.json' + auth); if (!r.ok) throw new Error('read ' + r.status); return r.json(); };
  const send = async (method, p, body) => { const r = await F(DB + p + '.json' + auth, { method, headers: J, body: JSON.stringify(body) }); if (!r.ok) throw new Error(method + ' ' + r.status); return r; };

  // What would change? Counts only. Nothing is written.
  async function plan() {
    const members = (await get('/lvr_rewards')) || {}, reg = (await get('/lvr_points/round1')) || {}, priv = (await get('/lvr_member_private')) || {}, codes = (await get('/lvr_refcodes')) || {};
    const privBy = {}; Object.keys(priv).forEach(t => { if (priv[t] && priv[t].memberKey) privBy[priv[t].memberKey] = t; });
    const p = { members: 0, needHidden: 0, hiddenOK: 0, conflict: 0, needCode: 0, needRound1: 0, withPublicFields: 0, noToken: 0 };
    for (const k of Object.keys(members)) {
      const m = members[k]; if (!m || typeof m !== 'object') continue; p.members++;
      const has = FIELDS.concat('token').some(f => m[f] != null);
      if (has) p.withPublicFields++;
      if (m.token) { const pv = priv[m.token]; if (!pv) p.needHidden++; else if (pv.memberKey !== k) p.conflict++; else p.hiddenOK++; } else if (FIELDS.some(f => m[f] != null)) p.noToken++;
      if (m.refCode && codes[m.refCode] == null) p.needCode++;
      if (!reg[k] && m.status !== 'rejected') p.needRound1++;
    }
    return { p, members, reg, priv, codes };
  }

  // PHASE A (adds only): hidden record, referral code, hashed index, Round One entry for every member that lacks them.
  async function copy() {
    const { p, members, reg, priv, codes } = await plan(); const r = { hidden: 0, codes: 0, idx: 0, round1: 0, skipped: 0 };
    for (const k of Object.keys(members)) {
      const m = members[k]; if (!m || typeof m !== 'object') continue;
      if (m.token && !priv[m.token]) {
        if (FIELDS.some(f => m[f] != null)) { const h = { memberKey: k }; FIELDS.forEach(f => { if (m[f] != null) h[f] = m[f]; }); await send('PUT', '/lvr_member_private/' + enc(m.token), h); r.hidden++; } else r.skipped++;
      }
      if (m.refCode && codes[m.refCode] == null) { await send('PUT', '/lvr_refcodes/' + enc(m.refCode), k); r.codes++; }
      for (const h of hashesFor(m)) { const cur = await get('/lvr_member_idx/' + h); if (cur == null) { await send('PUT', '/lvr_member_idx/' + h, k); r.idx++; } }
      if (!reg[k] && m.status !== 'rejected') {
        const at = typeof m.joinedAt === 'number' && m.joinedAt < Date.now() ? m.joinedAt : Date.now() - 1000;
        await send('PUT', '/lvr_points/round1/' + enc(k), { name: shortName(m.name), at, status: m.status === 'pending' ? 'pending' : 'approved' }); r.round1++;
      }
    }
    return { plan: p, done: r };
  }

  // Re-read every hidden copy and compare it with the public record. Returns counts and the list of members that matched.
  async function verify() {
    const members = (await get('/lvr_rewards')) || {}; const v = { checked: 0, ok: 0, bad: 0, okKeys: [] };
    for (const k of Object.keys(members)) {
      const m = members[k]; if (!m || typeof m !== 'object' || !m.token) continue;
      const hid = await get('/lvr_member_private/' + enc(m.token)); v.checked++;
      const same = hid && hid.memberKey === k && FIELDS.every(f => m[f] == null || hid[f] === m[f]);
      if (same) { v.ok++; v.okKeys.push(k); } else v.bad++;
    }
    return v;
  }

  // PHASE C (changes existing data, only after the rules are live and verify() matched): take phone/email/birthday/anniversary/token out of the public record.
  async function strip() {
    const v = await verify(); const members = (await get('/lvr_rewards')) || {}; let stripped = 0;
    for (const k of v.okKeys) { const m = members[k]; const patch = {}; FIELDS.concat('token').forEach(f => { if (m[f] != null) patch[f] = null; }); if (Object.keys(patch).length) { await send('PATCH', '/lvr_rewards/' + enc(k), patch); stripped++; } }
    return { verified: v.ok, notVerified: v.bad, stripped };
  }

  // After the new rules: put "who invited me" on the Round One entry (the new rules allow it), for members whose record has it.
  async function refs() {
    const members = (await get('/lvr_rewards')) || {}, reg = (await get('/lvr_points/round1')) || {}; let n = 0;
    for (const k of Object.keys(members)) { const m = members[k]; if (m && m.referredBy && reg[k] && reg[k].referredBy == null) { await send('PUT', '/lvr_points/round1/' + enc(k) + '/referredBy', m.referredBy); n++; } }
    return { referredBy: n };
  }

  // Read-only outside check: what can a stranger (no sign-in) see?
  async function outside(keys) {
    const st = async p => { try { return (await F(DB + p + '.json')).status; } catch (e) { return 'err'; } };
    const res = { listMembers: await st('/lvr_rewards?shallow=true'), listPrivate: await st('/lvr_member_private'), listCodes: await st('/lvr_refcodes'), leaderboard: await st('/lvr_points/round1?shallow=true'), leakedFields: 0, memberReadable: 0 };
    for (const k of keys) { const r = await F(DB + '/lvr_rewards/' + enc(k) + '.json'); if (!r.ok) continue; res.memberReadable++; const m = await r.json(); if (m) FIELDS.concat('token').forEach(f => { if (m[f] != null) res.leakedFields++; }); }
    return res;
  }
  return { plan, copy, verify, strip, refs, outside, hashesFor };
};
