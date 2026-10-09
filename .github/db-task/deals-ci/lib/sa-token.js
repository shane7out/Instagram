// Exchanges a Google service-account JSON key for an OAuth access token,
// using the JWT-bearer flow directly over HTTPS (no gcloud CLI, no
// googleapis/google-auth-library npm dependency - GH Actions has neither).
// Standard flow: https://developers.google.com/identity/protocols/oauth2/service-account
'use strict';
const crypto = require('crypto');
const https = require('https');

function b64url(input) {
  return Buffer.from(input).toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function post(url, form) {
  return new Promise((resolve, reject) => {
    const body = new URLSearchParams(form).toString();
    const u = new URL(url);
    const req = https.request(u, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'Content-Length': Buffer.byteLength(body) },
    }, (r) => {
      let d = ''; r.on('data', (c) => (d += c)); r.on('end', () => resolve({ status: r.statusCode, body: d }));
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

// scope: space-separated OAuth scopes. Default covers Firebase Hosting deploys.
async function getAccessToken(serviceAccountJson, scope) {
  scope = scope || 'https://www.googleapis.com/auth/cloud-platform';
  const sa = typeof serviceAccountJson === 'string' ? JSON.parse(serviceAccountJson) : serviceAccountJson;
  if (!sa.client_email || !sa.private_key) throw new Error('service account JSON missing client_email/private_key');

  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claim = {
    iss: sa.client_email,
    scope,
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };
  const unsigned = b64url(JSON.stringify(header)) + '.' + b64url(JSON.stringify(claim));
  const signer = crypto.createSign('RSA-SHA256');
  signer.update(unsigned);
  signer.end();
  const signature = signer.sign(sa.private_key).toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
  const jwt = unsigned + '.' + signature;

  const r = await post('https://oauth2.googleapis.com/token', {
    grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
    assertion: jwt,
  });
  let json;
  try { json = JSON.parse(r.body); } catch (e) { throw new Error('token exchange: unparseable response (' + r.status + '): ' + r.body.slice(0, 300)); }
  if (r.status !== 200 || !json.access_token) throw new Error('token exchange failed (' + r.status + '): ' + r.body.slice(0, 300));
  return json.access_token;
}

module.exports = { getAccessToken };
