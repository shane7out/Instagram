#!/bin/bash
# READ-ONLY count of the Rewards members (no names, phones, emails or tokens are printed; nothing is written). Shane did not see his 3 members in the Points admin.
cat > /tmp/count-members.js <<'NODE'
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const get = async p => { const r = await fetch(DB + p + '.json'); return { s: r.status, j: r.ok ? await r.json() : null }; };
(async () => {
  const m = await get('/lvr_rewards'); console.log('lvr_rewards list -> HTTP ' + m.s);
  const members = m.j && typeof m.j === 'object' ? m.j : {};
  const keys = Object.keys(members); console.log('members in lvr_rewards: ' + keys.length);
  const by = {}; let tok = 0, ph = 0, em = 0, pts = 0, src = {};
  keys.forEach(k => { const x = members[k] || {}; const st = x.status || '(none)'; by[st] = (by[st] || 0) + 1; if (x.token) tok++; if (x.phone) ph++; if (x.email) em++; pts += Number(x.points) || 0; const s = x.source || '(none)'; src[s] = (src[s] || 0) + 1; });
  console.log('by status: ' + JSON.stringify(by)); console.log('by source: ' + JSON.stringify(src));
  console.log('with token: ' + tok + ', with phone: ' + ph + ', with email: ' + em + ', total points: ' + pts);
  const r1 = await get('/lvr_points/round1'); const reg = r1.j && typeof r1.j === 'object' ? r1.j : {};
  console.log('round1 registry: ' + Object.keys(reg).length + ' entries, ' + keys.filter(k => !reg[k]).length + ' members missing from it');
  const pv = await get('/lvr_member_private'); console.log('lvr_member_private list -> HTTP ' + pv.s + (pv.j ? ' (' + Object.keys(pv.j).length + ' entries)' : ''));
  const pe = await get('/lvr_points/settings/privateLayout'); console.log('privateLayout flag: ' + JSON.stringify(pe.j));
})().catch(e => console.log('ERROR ' + e.message));
NODE
node /tmp/count-members.js
