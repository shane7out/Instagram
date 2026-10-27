#!/bin/bash
# One-off: give the Vanilla Rice menu header its real restaurant name (only bizName is written).
node <<'NODE'
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
(async () => {
  const cur = await (await fetch(DB + '/lvr_points/directory/vanilla-rice.json')).json();
  console.log('directory entry exists: ' + !!cur + (cur ? ', fields: ' + Object.keys(cur).join(',') : ''));
  if (cur && cur.bizName) { console.log('bizName already set - nothing changed'); return; }
  const r = await fetch(DB + '/lvr_points/directory/vanilla-rice/bizName.json', { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify('Vanilla Rice Hibachi House') });
  console.log('write HTTP ' + r.status);
})();
NODE
