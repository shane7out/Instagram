#!/bin/bash
# Read-only diagnostic: run the real, unauthenticated Google PageSpeed
# Insights API against the live site (same categories the site's own audit
# tool checks: performance, accessibility, best-practices, seo) to get an
# honest, real score instead of guessing. Also do the same PHP/WordPress
# exposure scan the site's security check does.
set -e
node <<'NODE'
const https = require('https');
function get(url, timeoutMs) {
  return new Promise((resolve) => {
    const req = https.get(url, { timeout: timeoutMs || 30000 }, r => {
      let d = ''; r.on('data', c => d += c); r.on('end', () => resolve({ status: r.statusCode, body: d }));
    });
    req.on('error', e => resolve({ error: e.message }));
    req.on('timeout', () => { req.destroy(); resolve({ error: 'timeout' }); });
  });
}

(async () => {
  console.log('=== PageSpeed Insights (unauthenticated, mobile) ===');
  const target = encodeURIComponent('https://keytechnologies.si/');
  const psiUrl = 'https://www.googleapis.com/pagespeedonline/v5/runPagespeed?url=' + target +
    '&strategy=mobile&category=performance&category=accessibility&category=best-practices&category=seo';
  const r = await get(psiUrl, 45000);
  if (r.error) {
    console.log('PSI request failed:', r.error);
  } else if (r.status !== 200) {
    console.log('PSI HTTP', r.status, '| body (first 500 chars):', r.body.slice(0, 500));
  } else {
    try {
      const data = JSON.parse(r.body);
      const cats = data.lighthouseResult && data.lighthouseResult.categories;
      if (!cats) { console.log('No categories in response. Raw (first 500):', r.body.slice(0,500)); }
      else {
        for (const key of ['performance','accessibility','best-practices','seo']) {
          const c = cats[key];
          if (c) console.log(key + ':', Math.round(c.score * 100));
        }
      }
    } catch (e) {
      console.log('Parse failed:', e.message, '| body (first 500):', r.body.slice(0, 500));
    }
  }

  console.log('\n=== PHP/WordPress exposure check (same logic as the site security scan) ===');
  const home = await get('https://keytechnologies.si/', 15000);
  if (home.error) { console.log('fetch failed:', home.error); }
  else {
    const body = home.body || '';
    const phpSignals = /\.php|wp-content|wp-includes|wp-admin|X-Powered-By.*PHP/i.test(body);
    console.log('PHP/WordPress signals found in homepage HTML:', phpSignals);
  }
})();
NODE
