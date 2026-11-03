// Builds sites/key-technologies/spin-terms.html from the terms in my-account.html (single source of truth).
// Run from the repo root:  node .github/db-task/gen-spin-terms.js
const fs = require('fs');
const src = fs.readFileSync('sites/key-technologies/my-account.html', 'utf8');
const ver = /SPIN_TERMS_VERSION = '([^']+)', SPIN_TERMS_DATE = '([^']+)'/.exec(src);
const fnSrc = /function spinTermsList\(c\) \{[\s\S]*?\n  \}\n/.exec(src)[0];
const hrs = d => Math.round(d * 24);
const cycleText = d => d >= 1 && d === Math.round(d) ? d + (d === 1 ? ' day' : ' days') : hrs(d) + ' hours';
const list = new Function('hrs', 'cycleText', fnSrc + '; return spinTermsList;')(hrs, cycleText)({ waitDays: 7, claimHours: 48, prizeMin: 1, prizeMax: 10 });
const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;');
const html = `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Spin Terms — LVR Rewards</title>
<meta name="description" content="The rules of the free LVR Rewards spin. The number is random and we have no control over it.">
<link rel="canonical" href="https://keytechnologies.si/spin-terms.html">
<meta property="og:type" content="website"><meta property="og:title" content="Spin Terms — LVR Rewards"><meta property="og:description" content="The rules of the free LVR Rewards spin. The number is random and we have no control over it."><meta property="og:url" content="https://keytechnologies.si/spin-terms.html"><meta property="og:image" content="https://keytechnologies.si/og-image.png"><meta name="twitter:card" content="summary_large_image">
<link rel="stylesheet" href="/fonts/lato.css"><style>
  :root{--bg:#0f171e;--card:#232f3e;--ink:#ffffff;--dim:#aab9ca;--gold:#00a8e1;--blue:#00a8e1;--line:#37475a;}
  *{box-sizing:border-box;} body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.6 Lato,Inter,system-ui,-apple-system,Segoe UI,Roboto,sans-serif;}
  header{background:#232f3e;padding:14px 16px;} header a{color:var(--ink);text-decoration:none;font-weight:800;letter-spacing:.02em;} header span{color:var(--blue);}
  main{max-width:640px;margin:0 auto;padding:26px 16px 70px;}
  h1{font-size:28px;line-height:1.2;margin:0 0 6px;} .ver{color:var(--dim);font-size:14px;margin:0 0 18px;}
  .short{background:rgba(0,168,225,.10);border:1px solid rgba(0,168,225,.45);border-radius:12px;padding:13px 15px;margin:0 0 20px;} .short b{color:var(--gold);}
  ol{margin:0;padding:0 0 0 22px;display:grid;gap:14px;} li b{color:var(--ink);} 
  .back{display:inline-block;margin-top:26px;color:var(--blue);font-weight:700;} .note{color:var(--dim);font-size:14px;margin-top:22px;}
  @media print{body{background:#fff;color:#000;} header{display:none;} .short{border-color:#999;background:#f4f4f4;} .back{display:none;}}
</style></head><body>
<header><a href="index.html" style="display:inline-flex;align-items:center;gap:10px"><svg width="37" height="16" viewBox="0 4 116 50" aria-hidden="true" style="display:block;flex:none;filter:drop-shadow(0 0 4px rgba(255,200,40,.6)) drop-shadow(0 0 11px rgba(255,200,40,.35))"><defs><linearGradient id="kgh" x1="0" y1="5" x2="0" y2="53" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#fffdf0"/><stop offset=".22" stop-color="#ffe45c"/><stop offset=".48" stop-color="#e49a00"/><stop offset=".56" stop-color="#b87300"/><stop offset=".68" stop-color="#ffd23a"/><stop offset=".88" stop-color="#fff2a0"/><stop offset="1" stop-color="#d48f00"/></linearGradient></defs><g fill="none" stroke="url(#kgh)"><circle cx="24" cy="30" r="19" stroke-width="8"/><circle cx="24" cy="30" r="8.5" stroke-width="3"/></g><g fill="url(#kgh)"><rect x="42" y="26.5" width="72" height="7" rx="1"/><rect x="45" y="21" width="6" height="18" rx="2"/><rect x="55" y="23" width="5" height="14" rx="2"/><path d="M90,33H98V45H90ZM102,33H114V51H102Z"/></g><g stroke="#fff" stroke-linecap="round" fill="none"><path d="M9,20A17,17 0 0 1 24,12" stroke-width="3" stroke-opacity=".9"/><path d="M46,28H112" stroke-width="1.6" stroke-opacity=".9"/><path d="M104,35V49" stroke-width="1.4" stroke-opacity=".8"/></g></svg><span style="color:var(--ink)">KEY TECHNOLOGIES<span>.SI</span></span></a></header>
<main>
  <h1>LVR Rewards Spin Terms</h1>
  <p class="ver">Version ${ver[2]} · Las Vegas Restaurants</p>
  <div class="short"><b>In short:</b> the number is random and we have no control over it.</div>
  <ol>
${list.map(t => `    <li><b>${esc(t[0])}.</b> ${esc(t[1])}</li>`).join('\n')}
  </ol>
  <p class="note">These terms stay on this page, and under the LVR Rewards menu in the app, for as long as the spin exists. Questions? Message <a href="https://instagram.com/lasvegas_restaurants" style="color:var(--blue);">@LasVegas_Restaurants</a> on Instagram.</p>
  <a class="back" href="my-account.html">&larr; Back to my LVR Rewards</a>
</main></body></html>
`;
fs.writeFileSync('sites/key-technologies/spin-terms.html', html);
console.log('wrote spin-terms.html, version', ver[1], ',', list.length, 'terms');
