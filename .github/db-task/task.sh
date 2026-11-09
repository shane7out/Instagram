#!/bin/bash
# READ-ONLY audit 6 (2026-11-09): confirm why the dashboard stops merging records. Hypothesis: dashboard/customrecords is an array with empty (null) slots and the page's
# rebuild loop throws "Cannot read properties of null (reading 'num')" at the first empty slot, so every record AFTER it is left out of the list and the Total.
# Fetches the array (GET only) and reports where the empty slots are and how many live records come after the first one. Nothing is written.
set +e
cat > /tmp/audit6.js <<'NODE'
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
(async () => {
  const get = async p => (await fetch(DB + p + '.json', { signal: AbortSignal.timeout(90000) })).json();
  const arr = await get('/dashboard/customrecords'), del = await get('/dashboard/deleted') || {};
  if (!Array.isArray(arr)) { console.log('customrecords is not an array: ' + typeof arr); return; }
  const nullIdx = arr.map((v, i) => v == null ? i : -1).filter(i => i >= 0);
  const noNum = arr.map((v, i) => v && v.num == null ? i : -1).filter(i => i >= 0);
  console.log('array length ' + arr.length + ' | empty (null) slots at index: ' + JSON.stringify(nullIdx) + ' | objects without a num at index: ' + JSON.stringify(noNum));
  const live = (v) => v && v.num != null && !del[v.num];
  const first = nullIdx[0];
  const before = arr.slice(0, first).filter(live).length, after = arr.slice(first + 1).filter(live).length;
  console.log('first empty slot = ' + first + ' | live records BEFORE it: ' + before + ' | live records AFTER it: ' + after);
  nullIdx.forEach(i => console.log('around index ' + i + ': prev num ' + (arr[i - 1] && arr[i - 1].num) + ', next num ' + (arr[i + 1] && arr[i + 1].num)));
  const afterNums = arr.slice(first + 1).filter(live).map(v => Number(v.num)).sort((a, b) => a - b);
  console.log('after the first empty slot: lowest num ' + afterNums[0] + ', highest ' + afterNums[afterNums.length - 1] + ', count ' + afterNums.length);
})().catch(e => console.log('ERROR ' + e.message));
NODE
node /tmp/audit6.js
