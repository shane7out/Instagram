#!/bin/bash
# Read-only diagnostic: hit the exact Craigslist search API the Deals scraper
# uses (from _tools/watch-houses.js, area 26 = lasvegas) and report what comes
# back - status code, headers, and a snippet of the body - so we can tell
# whether Craigslist is blocking the request or something else is wrong.
set -e

node <<'NODE'
const https = require('https');

const UA = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)';
const AREA = 26; // lasvegas
const MINP = 10000, MAXP = 99000000;
const url = 'https://sapi.craigslist.org/web/v8/postings/search/full?batch=' + AREA +
  '-0-360-0-0&cc=US&lang=en&searchPath=reo&query=' + encodeURIComponent('house') +
  '&min_price=' + MINP + '&max_price=' + MAXP;

function fetchOnce(u) {
  return new Promise((resolve, reject) => {
    const req = https.get(u, { headers: { 'user-agent': UA, accept: 'application/json' } }, r => {
      const chunks = [];
      r.on('data', c => chunks.push(c));
      r.on('end', () => resolve({ status: r.statusCode, headers: r.headers, buf: Buffer.concat(chunks) }));
    });
    req.on('error', reject);
    req.setTimeout(30000, () => req.destroy(new Error('timeout')));
  });
}

(async () => {
  console.log('Requesting:', url);
  const r = await fetchOnce(url).catch(e => ({ error: e.message }));
  if (r.error) {
    console.log('REQUEST FAILED (network-level):', r.error);
    return;
  }
  console.log('HTTP status:', r.status);
  console.log('Content-Type:', r.headers['content-type']);
  console.log('Content-Length (actual):', r.buf.length);
  const bodyStr = r.buf.toString('utf8');
  console.log('First 1000 chars of body:');
  console.log(bodyStr.slice(0, 1000));
  console.log('---');
  try {
    const parsed = JSON.parse(bodyStr);
    console.log('Parsed as JSON OK. Top-level keys:', Object.keys(parsed));
    console.log('data.items length:', (parsed.data && parsed.data.items || []).length);
  } catch (e) {
    console.log('FAILED to parse body as JSON:', e.message);
  }
})();
NODE
