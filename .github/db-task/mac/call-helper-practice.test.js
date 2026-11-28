// Test for call-helper-practice.js against a FAKE AI service (no key, no network). Run: node call-helper-practice.test.js  (needs Playwright for the page part)
const http = require('http'), { spawn } = require('child_process'), path = require('path');
let fails = 0; const ok = (n, c) => { console.log((c ? 'PASS' : 'FAIL') + '  ' + n); if (!c) fails++; };
const seen = []; let mode = 'good';
const fake = http.createServer((q, r) => { let b = ''; q.on('data', c => b += c); q.on('end', () => {
  const j = JSON.parse(b || '{}'); seen.push({ key: q.headers['x-api-key'], ver: q.headers['anthropic-version'], j });
  if (mode === 'refuse') { r.writeHead(401); return r.end('{}'); }
  if (mode === 'junk') { r.writeHead(200, { 'content-type': 'application/json' }); return r.end(JSON.stringify({ content: [{ type: 'text', text: 'no json here' }] })); }
  r.writeHead(200, { 'content-type': 'application/json' });
  r.end(JSON.stringify({ content: [{ type: 'text', text: 'Sure: {"say":"What monthly amount would feel comfortable to you?","why":"They raised cost.","avoid":"Do not push past their number.","stage":"discover","stop":false}' }] }));
}); });
(async () => {
  await new Promise(r => fake.listen(8791, '127.0.0.1', r));
  const srv = spawn('node', [path.join(__dirname, 'call-helper-practice.js')], { env: Object.assign({}, process.env, { CALL_HELPER_PORT: '8778', CALL_HELPER_KEY: 'test-key-not-real', CALL_HELPER_API: 'http://127.0.0.1:8791/v1/messages' }) });
  await new Promise(r => setTimeout(r, 800));
  const P = 'http://127.0.0.1:8778', J = { 'content-type': 'application/json' };
  const post = (body, h) => fetch(P + '/suggest', { method: 'POST', headers: Object.assign({}, J, h || {}), body: JSON.stringify(body) }).then(async r => ({ s: r.status, j: await r.json().catch(() => null) }));
  const wait = () => new Promise(r => setTimeout(r, 1300));
  let r = await post({ type: 'final', transcript: 'A: What got you thinking about this?\nP: I am on a fixed income and worried about cost' });
  ok('suggestion returned', r.s === 200 && r.j.ok && /monthly amount/.test(r.j.suggestion.say));
  ok('key and version sent upstream, system prompt has the rules', seen[0].key === 'test-key-not-real' && seen[0].ver === '2023-06-01' && /NEVER pressure/.test(seen[0].j.system) && /DATA/.test(seen[0].j.system) && seen[0].j.max_tokens === 300);
  ok('transcript reaches the model as data in the user message', /fixed income/.test(seen[0].j.messages[0].content) && /licensed insurance agent/.test(seen[0].j.messages[0].content));
  await wait(); const before = seen.length;
  r = await post({ type: 'life', transcript: 'A: Hello\nP: please stop calling me' });
  ok('stop request never reaches the AI and says end the call', r.j.suggestion.stop === true && seen.length === before && /take your number off/.test(r.j.suggestion.say));
  r = await post({ type: 'life', transcript: 'x' }); ok('rate limit (too fast)', r.s === 429);
  await wait(); mode = 'junk'; r = await post({ type: 'life', transcript: 'P: hi' }); ok('unclear AI answer is handled', r.j.ok === false);
  await wait(); mode = 'refuse'; r = await post({ type: 'life', transcript: 'P: hi' }); ok('refused key gives a plain message, no upstream text', r.j.ok === false && /refused the key/.test(r.j.error));
  await wait(); mode = 'good'; r = await post({ transcript: '' }); ok('empty transcript refused', r.s === 400);
  r = await fetch(P + '/suggest', { method: 'POST', headers: Object.assign({}, J, { origin: 'http://evil.example' }), body: '{}' }); ok('foreign origin refused', r.status === 403);
  r = await fetch(P + '/'); const html = await r.text(); ok('page served with strict headers', r.status === 200 && /Practice only/.test(html) && /default-src 'none'/.test(r.headers.get('content-security-policy')) && r.headers.get('cache-control') === 'no-store');
  ok('page never uses innerHTML', !/innerHTML/.test(html));
  let pw; try { pw = require('playwright'); } catch (e) { console.log('SKIP page test (no playwright)'); }
  if (pw) {
    const b = await pw.chromium.launch(), p = await b.newPage(); const errs = []; p.on('pageerror', e => errs.push(e.message));
    await p.addInitScript(() => { window.SpeechRecognition = window.webkitSpeechRecognition = function () { this.start = () => { window.__started = true; setTimeout(() => this.onresult && this.onresult({ resultIndex: 0, results: [Object.assign([{ transcript: 'we just had a baby' }], { isFinal: true })] }), 200); }; this.stop = () => {}; }; });
    await p.goto(P + '/');
    ok('buttons locked until consent box ticked', await p.$eval('#mic', e => e.disabled) && await p.$eval('#add', e => e.disabled));
    await p.check('#ok'); ok('unlocked after consent', !(await p.$eval('#mic', e => e.disabled)));
    await p.selectOption('#type', 'life'); await wait(); await p.fill('#typed', 'I have coverage through work'); await p.click('#add'); await p.waitForSelector('#sug:not([hidden])', { timeout: 6000 });
    ok('typed words produce a suggestion card', /monthly amount/.test(await p.textContent('#say')));
    await wait(); await p.click('#spA'); await p.fill('#typed', 'Thanks for telling me'); await p.click('#add'); ok('agent lines logged without asking AI', /Agent: Thanks for telling me/.test(await p.textContent('#log')));
    await p.click('#spP'); await p.fill('#typed', 'do not call me again'); await p.click('#add'); ok('stop shows STOP card at once', /STOP/.test(await p.textContent('#stage')) && (await p.getAttribute('#sug', 'class')).includes('stop'));
    await p.click('#mic'); await p.waitForTimeout(500); ok('speech path adds heard words', /we just had a baby/.test(await p.textContent('#log')) && await p.evaluate(() => window.__started === true));
    await p.click('#clr'); ok('clear empties everything', (await p.textContent('#log')) === '' && await p.$eval('#sug', e => e.hidden));
    await p.fill('#typed', '<img src=x onerror=alert(1)>'); await p.click('#add'); ok('markup in speech is shown as text', (await p.$$('#log img')).length === 0 && /img src/.test(await p.textContent('#log')));
    ok('no page errors', errs.length === 0); await b.close();
  }
  srv.kill(); fake.close(); console.log(fails ? fails + ' FAILED' : 'ALL PASSED'); process.exit(fails ? 1 : 0);
})();
