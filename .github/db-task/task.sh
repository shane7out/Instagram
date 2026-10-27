#!/bin/bash
# One-off (owner-approved): Free Chicken Bowl costs 13 points; pre-fill (but leave OFF) the welcome bonus at 13 points
# given at sign-up; give Vanilla Rice an earn rate of 1 point per $1 if none is set. Only fills in what is missing/different.
node <<'NODE'
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const put = async (p, v, m) => { const r = await fetch(DB + p + '.json', { method: m || 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(v) }); return r.status; };
const get = async p => (await fetch(DB + p + '.json')).json();
(async () => {
  const cat = await get('/lvr_points/catalog/vanilla-rice') || {};
  for (const id of Object.keys(cat)) {
    if (cat[id] && cat[id].pointCost !== 13) console.log('bowl cost -> 13: HTTP ' + await put('/lvr_points/catalog/vanilla-rice/' + id, { pointCost: 13 }, 'PATCH'));
    else console.log(id + ': already 13');
  }
  const wel = await get('/lvr_points/settings/welcome');
  if (!wel) console.log('welcome bonus (off, 13, at sign-up): HTTP ' + await put('/lvr_points/settings/welcome', { enabled: false, amount: 13, when: 'signup' }));
  else console.log('welcome settings already exist: ' + JSON.stringify(wel));
  const dir = await get('/lvr_points/directory/vanilla-rice') || {};
  if (dir.earnRate == null) console.log('earn rate 1: HTTP ' + await put('/lvr_points/directory/vanilla-rice', { earnRate: 1 }, 'PATCH'));
  else console.log('earnRate already ' + dir.earnRate);
  console.log('directory entry fields: ' + Object.keys(Object.assign({}, dir, { earnRate: 1 })).join(', '));
})();
NODE
