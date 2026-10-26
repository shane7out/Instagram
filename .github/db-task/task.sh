#!/bin/bash
# Read-only diagnostic: now that keytechnologies.si is genuinely live, check
# things that only matter in a real hosted environment - HTTP->HTTPS
# behavior, www subdomain, every real page route, 404 handling, OG image
# reachability, security/cache headers, mixed-content, and whether Firebase/
# Formspree actually respond with CORS headers a live browser needs.
set -e
node <<'NODE'
const https = require('https');
const http = require('http');

function get(url, opts = {}) {
  return new Promise((resolve) => {
    const lib = url.startsWith('https') ? https : http;
    const req = lib.get(url, { timeout: 15000, ...opts }, r => {
      let d = ''; r.on('data', c => d += c); r.on('end', () => resolve({ status: r.statusCode, body: d, headers: r.headers }));
    });
    req.on('error', e => resolve({ error: e.message }));
    req.on('timeout', () => { req.destroy(); resolve({ error: 'timeout' }); });
  });
}

(async () => {
  console.log('=== HTTP -> HTTPS redirect ===');
  const httpR = await get('http://keytechnologies.si/', { headers: { 'User-Agent': 'diag' } });
  if (httpR.error) console.log('http:// request error:', httpR.error);
  else console.log('http:// status:', httpR.status, '| location:', httpR.headers.location || '(none)');

  console.log('\n=== www subdomain ===');
  const wwwR = await get('https://www.keytechnologies.si/');
  if (wwwR.error) console.log('www -> ERROR:', wwwR.error);
  else console.log('www -> status', wwwR.status, '| bytes', wwwR.body.length);

  console.log('\n=== every real page route ===');
  for (const path of ['', 'real-estate.html', 'law.html', 'medical-dental.html', 'ecommerce.html', 'privacy.html', 'terms.html']) {
    const r = await get('https://keytechnologies.si/' + path);
    console.log(path || '(home)', '->', r.error ? 'ERROR: ' + r.error : 'HTTP ' + r.status + ' | ' + r.body.length + ' bytes');
  }

  console.log('\n=== 404 handling (bad path) ===');
  const r404 = await get('https://keytechnologies.si/this-page-does-not-exist-xyz');
  console.log('bad path -> HTTP', r404.status, '| has "That page doesn\'t exist":', (r404.body || '').includes("That page doesn't exist"));

  console.log('\n=== robots.txt / sitemap.xml ===');
  const robots = await get('https://keytechnologies.si/robots.txt');
  console.log('robots.txt -> HTTP', robots.status, '|', (robots.body || '').replace(/\n/g, ' | '));
  const sitemap = await get('https://keytechnologies.si/sitemap.xml');
  console.log('sitemap.xml -> HTTP', sitemap.status, '| bytes', (sitemap.body || '').length);

  console.log('\n=== OG image reachable ===');
  const og = await get('https://keytechnologies.si/og-image.png');
  console.log('og-image.png -> HTTP', og.status, '| content-type', og.headers && og.headers['content-type'], '| bytes', og.body.length);

  console.log('\n=== security/cache headers on homepage ===');
  const home = await get('https://keytechnologies.si/');
  const h = home.headers || {};
  console.log('content-type:', h['content-type']);
  console.log('cache-control:', h['cache-control']);
  console.log('strict-transport-security:', h['strict-transport-security'] || '(none)');
  console.log('x-content-type-options:', h['x-content-type-options'] || '(none)');

  console.log('\n=== mixed content check (http:// refs in the live HTML) ===');
  const body = home.body || '';
  const mixedMatches = [...body.matchAll(/(?:src|href)=["']http:\/\/[^"']+["']/g)].map(m => m[0]);
  console.log('http:// references found:', mixedMatches.length ? mixedMatches.join(', ') : 'none');

  console.log('\n=== canonical tag vs actual domain ===');
  const canonMatch = body.match(/<link rel="canonical" href="([^"]+)"/);
  console.log('canonical tag:', canonMatch ? canonMatch[1] : '(not found)');

  console.log('\n=== Firebase RTDB CORS (lead form target) ===');
  const fb = await get('https://lvr-data-a60c1-default-rtdb.firebaseio.com/key_leads/leads.json', { headers: { Origin: 'https://keytechnologies.si' } });
  console.log('firebase -> HTTP', fb.status, '| access-control-allow-origin:', (fb.headers && fb.headers['access-control-allow-origin']) || '(none)');

  console.log('\n=== Formspree reachability ===');
  const fs = await get('https://formspree.io/f/mzeedbyb');
  console.log('formspree endpoint GET -> HTTP', fs.status, '(GET normally returns 405 Method Not Allowed - that is expected, confirms the endpoint exists)');
})();
NODE
