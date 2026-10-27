#!/bin/bash
# Read-only: for the 7 demo restaurants, report whether the list holds a GENERIC business email
# (info@, contact@, hello@, orders@ ... on the restaurant's own domain). Personal-looking or
# free-mail addresses are NOT printed - only "withheld".
node <<'NODE'
const DB = 'https://lvr-data-a60c1-default-rtdb.firebaseio.com';
const NAMES = ["The Beach House","Black Mountain Griddle","The Irish Spot","Smoking Pig BBQ Company","Samurai Japanese Steakhouse and Sushi","Doanburi","Peru Chicken"];
const GENERIC = /^(info|contact|hello|hi|orders|order|catering|events|reservations|reserve|manager|team|admin|office|support|booking|bookings|mail|eat|dine)$/i;
const FREE = /@(gmail|yahoo|ymail|hotmail|outlook|live|icloud|aol|msn|me|protonmail|comcast|att|sbcglobal|cox)\./i;
(async () => {
  const crec = await (await fetch(DB + '/dashboard_crec.json')).json() || {};
  const all = Object.keys(crec).map(k => crec[k]).filter(Boolean);
  NAMES.forEach(n => {
    const r = all.find(x => String(x.name).trim().toLowerCase() === n.toLowerCase());
    if (!r) { console.log(n + ': record not found'); return; }
    const e = String(r.email || '').trim();
    if (!e) { console.log(n + ': no email on file'); return; }
    const [local] = e.split('@');
    if (!FREE.test(e) && GENERIC.test(local)) console.log(n + ': GENERIC ' + e);
    else console.log(n + ': withheld (' + (FREE.test(e) ? 'free-mail address' : 'personal-looking or unclear') + ')');
  });
})();
NODE
