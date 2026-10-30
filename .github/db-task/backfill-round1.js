// One-time: put the members who joined before Round One into the leaderboard registry (lvr_points/round1/<key>)
// as approved, with first name + last initial. Prints counts only, never names or emails.
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const j = async (m, p, b) => { const r = await fetch(DB + p + '.json', { method: m, headers: { 'Content-Type': 'application/json' }, body: b === undefined ? undefined : JSON.stringify(b) }); return { ok: r.ok, body: await r.json().catch(() => null) }; };
const short = n => { const p = String(n || '').trim().split(/\s+/).filter(Boolean); return !p.length ? 'Member' : p.length === 1 ? p[0] : p[0] + ' ' + p[p.length - 1][0].toUpperCase() + '.'; };
(async () => {
  const members = (await j('GET', '/lvr_rewards')).body || {};
  const reg = (await j('GET', '/lvr_points/round1')).body || {};
  let added = 0, had = 0;
  for (const k of Object.keys(members)) {
    if (reg[k]) { had++; continue; }
    const m = members[k] || {};
    const r = await j('PUT', '/lvr_points/round1/' + encodeURIComponent(k), { name: short(m.name), at: Number(m.joinedAt) || Date.now(), status: m.status === 'pending' ? 'pending' : m.status === 'rejected' ? 'rejected' : 'approved' });
    if (r.ok) added++;
  }
  console.log('members: ' + Object.keys(members).length + ', already in registry: ' + had + ', added: ' + added);
})();
