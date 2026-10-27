#!/bin/bash
# Follow-up: (1) get the rest of lvr-rewards.html to see if it's signup-only
# or also shows an existing member their own points (answers Shane's "I'm
# gonna also need a demo for them to see what they see" question).
# (2) sanity-check the live hosting manifest to understand why
# deploy-key-room.sh's live-check showed 404 for all 8 standalone tool pages
# right after a "successful" deploy.
set -e
node <<'NODE'
const https = require('https');
function get(url, timeoutMs) {
  return new Promise((resolve) => {
    const req = https.get(url, { timeout: timeoutMs || 15000 }, r => {
      let d = ''; r.on('data', c => d += c); r.on('end', () => resolve({ status: r.statusCode, body: d }));
    });
    req.on('error', e => resolve({ error: e.message }));
    req.on('timeout', () => { req.destroy(); resolve({ error: 'timeout' }); });
  });
}

(async () => {
  const page = await get('https://lvr-data-a60c1.web.app/lvr-rewards.html', 15000);
  const body = page.body || '';
  console.log('=== lvr-rewards.html full fetch ===');
  console.log('status:', page.status, 'bytes:', body.length);

  console.log('\n=== signals: signup-only vs. also a "view my points" mode ===');
  const signals = ['lookup', 'Lookup', 'My Points', 'my-points', 'Check my', 'phone number to', 'existing member', 'already signed up', 'view your', 'Welcome back', 'search', 'Search'];
  for (const s of signals) {
    const n = (body.match(new RegExp(s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g')) || []).length;
    if (n) console.log(`  "${s}": ${n} occurrence(s)`);
  }

  // print the JS logic block(s) so we can see the actual flow, not just CSS
  const scripts = [...body.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/g)].map(m => m[1]);
  console.log('\n=== script blocks found:', scripts.length, '===');
  scripts.forEach((s, i) => {
    console.log(`\n--- script ${i} (${s.length} chars) ---`);
    console.log(s.slice(0, 4000));
  });

  // also grab the visible form fields / headings from the HTML body (not just <style>)
  const bodyTagMatch = body.match(/<body[^>]*>([\s\S]*)<\/body>/);
  if (bodyTagMatch) {
    const htmlOnly = bodyTagMatch[1].replace(/<script[\s\S]*?<\/script>/g, '');
    console.log('\n=== body HTML (scripts stripped), first 4000 chars ===');
    console.log(htmlOnly.slice(0, 4000));
  }

  console.log('\n\n=== hosting manifest check: are the 8 standalone tool files actually hosted? ===');
  // Firebase Hosting doesn't expose a public manifest list endpoint normally,
  // so just re-check live status + content-length for each, plus whether
  // Firebase is serving a SPA fallback (200 for literally anything) vs a
  // real 404.
  const files = ['key-room.html','key-leads.html','kt-crm.html','key-advertisers.html','lvr-coupons-admin.html','lvr-wallet.html','lvr-points-admin.html','lvr-restaurant-portal.html','lvr-coupon.html','rewards.html'];
  for (const f of files) {
    const r = await get(`https://lvr-data-a60c1.web.app/${f}`, 15000);
    console.log(`${f}: status ${r.status || r.error}, bytes ${r.body ? r.body.length : 0}`);
  }
  // also a known-never-existed filename, to see what a TRUE 404 looks like
  // on this host vs. what the real files return
  const bogus = await get('https://lvr-data-a60c1.web.app/this-file-does-not-exist-xyz123.html', 15000);
  console.log(`[control] bogus filename: status ${bogus.status || bogus.error}, bytes ${bogus.body ? bogus.body.length : 0}`);
})();
NODE
