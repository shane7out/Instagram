#!/bin/bash
# Read-only: business details for Vanilla Rice, Poke Heaven and the "TT Terrace" tea place (no personal emails).
node <<'NODE'
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const GENERIC = /^(info|contact|hello|hi|orders|order|catering|events|reservations|manager|team|admin|office|support|booking|eat)$/i;
const FREE = /@(gmail|yahoo|ymail|hotmail|outlook|live|icloud|aol|msn|me|protonmail|comcast|att|sbcglobal|cox)\./i;
(async () => {
  const crec = await (await fetch(DB + '/dashboard_crec.json')).json() || {};
  const all = Object.keys(crec).map(k => crec[k]).filter(Boolean);
  const hit = all.filter(r => /vanilla|poke\s*heaven|terrace|\btt\b|tea/i.test(String(r.name)));
  console.log('matches: ' + hit.length);
  hit.slice(0, 12).forEach(r => {
    const e = String(r.email || '').trim(); let em = 'none';
    if (e) em = (!FREE.test(e) && GENERIC.test(e.split('@')[0])) ? 'GENERIC ' + e : 'withheld';
    console.log(JSON.stringify({ n: r.name, a: r.address || null, p: r.phone || null, cu: r.cuisine || r.category || null, ig: r.instagram || null, igh: r.igHandle || null, email: em }));
  });
})();
NODE
