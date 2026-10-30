// Builds sites/key-technologies/spin-terms.html from the terms in my-account.html (single source of truth).
// Run from the repo root:  node .github/db-task/gen-spin-terms.js
const fs = require('fs');
const src = fs.readFileSync('sites/key-technologies/my-account.html', 'utf8');
const ver = /SPIN_TERMS_VERSION = '([^']+)', SPIN_TERMS_DATE = '([^']+)'/.exec(src);
const fnSrc = /function spinTermsList\(c\) \{[\s\S]*?\n  \}\n/.exec(src)[0];
const hrs = d => Math.round(d * 24);
const list = new Function('hrs', fnSrc + '; return spinTermsList;')(hrs)({ waitDays: 7, claimHours: 48, prizeMin: 1, prizeMax: 10 });
const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;');
const html = `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Spin Terms — LVR Rewards</title>
<meta name="description" content="The rules of the free LVR Rewards spin. The number is random and we have no control over it.">
<style>
  :root{--bg:#07111f;--card:#11243b;--ink:#eef4fb;--dim:#9fb3c8;--gold:#ffd35c;--blue:#59b5ff;--line:#2c4864;}
  *{box-sizing:border-box;} body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.6 Inter,system-ui,-apple-system,Segoe UI,Roboto,sans-serif;}
  header{background:#0d1d33;padding:14px 16px;} header a{color:var(--ink);text-decoration:none;font-weight:800;letter-spacing:.02em;} header span{color:var(--blue);}
  main{max-width:640px;margin:0 auto;padding:26px 16px 70px;}
  h1{font-size:28px;line-height:1.2;margin:0 0 6px;} .ver{color:var(--dim);font-size:14px;margin:0 0 18px;}
  .short{background:rgba(255,211,92,.08);border:1px solid rgba(255,211,92,.35);border-radius:12px;padding:13px 15px;margin:0 0 20px;} .short b{color:var(--gold);}
  ol{margin:0;padding:0 0 0 22px;display:grid;gap:14px;} li b{color:var(--ink);} 
  .back{display:inline-block;margin-top:26px;color:var(--blue);font-weight:700;} .note{color:var(--dim);font-size:14px;margin-top:22px;}
  @media print{body{background:#fff;color:#000;} header{display:none;} .short{border-color:#999;background:#f4f4f4;} .back{display:none;}}
</style></head><body>
<header><a href="index.html">KEY TECHNOLOGIES<span>.SI</span></a></header>
<main>
  <h1>LVR Rewards Spin Terms</h1>
  <p class="ver">Version ${ver[2]} · Las Vegas Restaurants</p>
  <div class="short"><b>In short:</b> the number is random and we have no control over it.</div>
  <ol>
${list.map(t => `    <li><b>${esc(t[0])}.</b> ${esc(t[1])}</li>`).join('\n')}
  </ol>
  <p class="note">These terms stay on this page, and under the LVR Rewards menu in the app, for as long as the spin exists. Questions? Message <a href="https://instagram.com/lasvegas_restaurants" style="color:var(--blue);">@LasVegas_Restaurants</a> on Instagram.</p>
  <a class="back" href="my-account.html">&larr; Back to my rewards</a>
</main></body></html>
`;
fs.writeFileSync('sites/key-technologies/spin-terms.html', html);
console.log('wrote spin-terms.html, version', ver[1], ',', list.length, 'terms');
