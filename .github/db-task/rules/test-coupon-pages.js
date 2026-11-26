/* Real-browser test of the two coupon pages against the database emulator (nothing touches the live database).
   Run by run-coupon-pages-test.sh */
const http = require('http'), fs = require('fs'), path = require('path');
const { chromium } = require('playwright');
const NS = 'demo-lvr-default-rtdb', EMU = 'http://127.0.0.1:9000', LIVE = 'lvr-data-a60c1-default-rtdb.firebaseio.com';
const MAC = process.env.MAC_DIR;
const b64u = o => Buffer.from(JSON.stringify(o)).toString('base64url');
const OWNER = b64u({ alg: 'none', typ: 'JWT' }) + '.' + b64u({ uid: 'TESTOWNER', user_id: 'TESTOWNER', sub: 'TESTOWNER', iat: Math.floor(Date.now() / 1000) }) + '.';
let pass = 0, fail = 0;
const ok = (name, cond, extra) => { cond ? pass++ : fail++; console.log((cond ? 'PASS' : 'FAIL') + '  ' + name + (cond ? '' : '  ' + (extra || ''))); };
const emu = async (method, p, body, tok) => { const r = await fetch(`${EMU}${p}.json?ns=${NS}${tok ? '&auth=' + tok : ''}`, { method, headers: { 'Content-Type': 'application/json' }, body: body === undefined ? undefined : JSON.stringify(body) }); return { s: r.status, j: await r.json().catch(() => null) }; };

(async () => {
  const srv = http.createServer((q, s) => { const f = path.join(MAC, q.url.split('?')[0].replace(/^\//, '')); fs.readFile(f, (e, d) => { if (e) { s.writeHead(404); s.end(); } else { s.writeHead(200, { 'Content-Type': 'text/html' }); s.end(d); } }); }).listen(0);
  const base = 'http://127.0.0.1:' + srv.address().port;
  const browser = await chromium.launch();
  const route = (ctx, asOwner) => ctx.route(`https://${LIVE}/**`, async r => {
    const u = new URL(r.request().url()); u.searchParams.set('ns', NS);
    if (asOwner) u.searchParams.set('auth', OWNER);
    const res = await fetch(EMU + u.pathname + u.search, { method: r.request().method(), headers: { 'Content-Type': 'application/json' }, body: ['GET', 'HEAD'].includes(r.request().method()) ? undefined : r.request().postData() });
    await r.fulfill({ status: res.status, headers: { 'access-control-allow-origin': '*', 'content-type': 'application/json' }, body: await res.text() });
  });
  const errors = [];

  await emu('PUT', '/lvr_coupons/programs/van', { bizName: 'Vanilla Rice', offer: 'Free bowl', maxClaims: 5, active: true, welcomeKeys: 1, staffKeys: 2, instructions: 'Show this at the counter.' }, OWNER);
  await emu('PUT', '/lvr_coupons/staff/van/maria-7k3', { name: 'Maria', active: true }, OWNER);

  // ---------- customer page
  const cust = await browser.newContext(); await route(cust, false);
  let page = await cust.newPage(); page.on('pageerror', e => errors.push('claim page: ' + e.message));
  await page.goto(base + '/lvr-coupon.html?biz=van&e=maria-7k3');
  await page.waitForSelector('#claimForm');
  ok('the restaurant name and the offer show', (await page.textContent('#card')).includes('Vanilla Rice') && (await page.textContent('#card')).includes('Free bowl'));
  ok('"5 of 5 left" shows from the public counter', (await page.textContent('#tickerLeft')) === '5');
  ok('the text box starts switched off', await page.isDisabled('#cSms'));
  ok('the email box and the text box are separate and start unticked', !(await page.isChecked('#cEmailOpt')) && !(await page.isChecked('#cSms')));
  await page.fill('#cName', 'Ann Lee'); await page.fill('#cEmail', 'ann@example.com'); await page.fill('#cPhone', '702'); await page.fill('#cIg', '@ann.lee');
  await page.click('#claimBtn');
  ok('a too-short phone number is refused on the page', /phone/i.test(await page.textContent('#claimMsg')) && (await page.$('.code-value')) === null);
  ok('a short phone number keeps the text box off', await page.isDisabled('#cSms'));
  await page.fill('#cPhone', '(702) 555-0100');
  ok('a full phone number switches the text box on', !(await page.isDisabled('#cSms')));
  await page.check('#cSms');
  ok('the text wording names the restaurant and Las Vegas Restaurants and STOP', /Vanilla Rice and Las Vegas Restaurants/.test(await page.textContent('#smsRow')) && /STOP/.test(await page.textContent('#smsRow')));
  await page.click('#claimBtn');
  await page.waitForSelector('.code-value');
  ok('the customer is told about their reward key', /1 reward key/.test(await page.textContent('#card')));
  const code = await page.textContent('.code-value');
  ok('a coupon code is shown', /^VAN-[A-Z0-9]{5}$/.test(code), code);
  const claims = (await emu('GET', '/lvr_coupons/claims/van', undefined, OWNER)).j || {};
  const ids = Object.keys(claims), c = claims[ids[0]] || {};
  ok('exactly one claim was saved', ids.length === 1);
  ok('the claim has name, email, phone, code', c.name === 'Ann Lee' && c.email === 'ann@example.com' && c.phone === '(702) 555-0100' && c.code === code);
  ok('text consent and its exact wording were saved', c.smsOptIn === true && /Vanilla Rice and Las Vegas Restaurants/.test(c.consentText || '') && c.consentVer === 'sms1');
  ok('email marketing stayed off because it was not ticked', c.marketingOptIn === false);
  ok('the Instagram handle was saved without the @', c.ig === 'ann.lee');
  ok('the claim remembers which employee QR it came through', c.ref === 'maria-7k3');
  ok('both duplicate-check entries (email and phone) were saved', Object.keys((await emu('GET', '/lvr_coupons/idx/van', undefined, OWNER)).j || {}).length === 2);
  
  ok('the public counter went to 1', (await emu('GET', '/lvr_coupons/counts/van')).j === 1);
  ok('a stranger cannot read the customer list', (await emu('GET', '/lvr_coupons/claims/van')).s !== 200);
  // same person again
  page = await cust.newPage(); page.on('pageerror', e => errors.push('claim page 2: ' + e.message));
  await page.goto(base + '/lvr-coupon.html?biz=van'); await page.waitForSelector('#claimForm');
  await page.fill('#cName', 'Ann Lee'); await page.fill('#cEmail', ' ANN@example.com '); await page.fill('#cPhone', '7025559999'); await page.click('#claimBtn');
  await page.waitForSelector('.code-value');
  ok('the same email gets the same code back', (await page.textContent('.code-value')) === code && (await page.textContent('#card')).includes('Welcome back'));
  ok('no second claim was created', Object.keys((await emu('GET', '/lvr_coupons/claims/van', undefined, OWNER)).j).length === 1);
  page = await cust.newPage(); await page.goto(base + '/lvr-coupon.html?biz=van&e=maria-7k3'); await page.waitForSelector('#claimForm');
  await page.fill('#cName', 'Ann Again'); await page.fill('#cEmail', 'ann2@example.com'); await page.fill('#cPhone', '702-555-0100'); await page.click('#claimBtn'); await page.waitForSelector('.code-value');
  ok('the same phone with a different email gets the same code back (no farming rewards)', (await page.textContent('.code-value')) === code && Object.keys((await emu('GET', '/lvr_coupons/claims/van', undefined, OWNER)).j).length === 1);
  // a different person, email yes
  page = await cust.newPage(); await page.goto(base + '/lvr-coupon.html?biz=van'); await page.waitForSelector('#claimForm');
  await page.fill('#cName', 'Bo Chen'); await page.fill('#cEmail', 'bo@example.com'); await page.fill('#cPhone', '7025550111'); await page.check('#cEmailOpt'); await page.click('#claimBtn'); await page.waitForSelector('.code-value');
  const all2 = (await emu('GET', '/lvr_coupons/claims/van', undefined, OWNER)).j; const bo = Object.values(all2).find(x => x.email === 'bo@example.com');
  ok('a customer with no Instagram and no employee saves with email yes and texts no', bo && bo.marketingOptIn === true && bo.smsOptIn === false && bo.ig === undefined && bo.ref === undefined);
  page = await cust.newPage(); await page.goto(base + '/lvr-coupon.html?biz=van&e=ghost-zzz'); await page.waitForSelector('#claimForm');
  await page.fill('#cName', 'Cy Diaz'); await page.fill('#cEmail', 'cy@example.com'); await page.fill('#cPhone', '7025550122'); await page.click('#claimBtn'); await page.waitForSelector('.code-value');
  ok('a removed or fake employee code still gets the customer their coupon (without credit to anyone)', Object.values((await emu('GET', '/lvr_coupons/claims/van', undefined, OWNER)).j).some(x => x.email === 'cy@example.com' && x.ref === undefined));
  // honeypot
  page = await cust.newPage(); await page.goto(base + '/lvr-coupon.html?biz=van'); await page.waitForSelector('#claimForm');
  await page.fill('#cName', 'Bot'); await page.fill('#cEmail', 'bot@example.com'); await page.fill('#cPhone', '7025550133'); await page.evaluate(() => { document.getElementById('cWeb').value = 'http://spam'; }); await page.click('#claimBtn'); await page.waitForSelector('.code-value');
  ok('a bot that fills the hidden box stores nothing', Object.keys((await emu('GET', '/lvr_coupons/claims/van', undefined, OWNER)).j).length === 3);
  // limit
  await emu('PUT', '/lvr_coupons/programs/full', { bizName: 'Full House', offer: 'Free soda', maxClaims: 1, active: true }, OWNER);
  await emu('PUT', '/lvr_coupons/counts/full', 1, OWNER);
  page = await cust.newPage(); await page.goto(base + '/lvr-coupon.html?biz=full'); await page.waitForSelector('.state-note');
  ok('a used-up offer says so', /fully claimed/.test(await page.textContent('#card')));
  await emu('PUT', '/lvr_coupons/programs/off', { bizName: 'Off', offer: 'x', active: false }, OWNER);
  page = await cust.newPage(); await page.goto(base + '/lvr-coupon.html?biz=off'); await page.waitForSelector('.state-note');
  ok('a paused offer says so', /isn.t available right now/.test(await page.textContent('#card')));
  page = await cust.newPage(); await page.goto(base + '/lvr-coupon.html?biz=nope'); await page.waitForSelector('.state-note');
  ok('an unknown restaurant says so', /isn.t available/.test(await page.textContent('#card')));

  // ---------- owner page
  const own = await browser.newContext({ acceptDownloads: true }); await route(own, true);
  await own.addInitScript(() => { var cbs = []; window.OWNER_AUTH = { signedIn: () => true, uid: () => 'TESTOWNER', onChange: f => cbs.push(f), dialog() {}, signOut() {} }; });
  const ad = await own.newPage(); ad.on('pageerror', e => errors.push('admin: ' + e.message)); ad.on('dialog', d => d.accept());
  await ad.goto(base + '/lvr-coupons-admin.html');
  await ad.waitForSelector('.program-card');
  const txt = await ad.textContent('#view');
  ok('the owner sees the restaurants', txt.includes('Vanilla Rice') && txt.includes('Full House'));
  ok('the owner sees customer, email and text counts', /3 customers/.test(txt) && /1 OK to email/.test(txt) && /1 OK to text/.test(txt), txt.slice(0, 300));
  ok('the old PIN is gone from the page', !/137900/.test(await ad.content()));
  await ad.click('[data-act="qr"][data-slug="van"]');
  await ad.waitForSelector('#qrBox svg');
  ok('the QR code and sign appear with the restaurant name and link', (await ad.textContent('#printArea')).includes('Vanilla Rice') && (await ad.textContent('#printArea')).includes('lvr-coupon.html?biz=van'));
  const svg = await ad.innerHTML('#qrBox'); ok('the QR code is a real drawing', svg.length > 2000);
  await ad.click('.back-link'); await ad.waitForSelector('.program-card');
  await ad.click('[data-act="claims"][data-slug="van"]'); await ad.waitForSelector('.claim-row');
  ok('the customer list shows names, emails, phone and text consent', /Ann Lee/.test(await ad.textContent('#view')) && /ann@example.com/.test(await ad.textContent('#view')) && /OK to text/.test(await ad.textContent('#view')));
  const [dl] = await Promise.all([ad.waitForEvent('download'), ad.click('#csvText')]);
  const csv = fs.readFileSync(await dl.path(), 'utf8');
  ok('the text list has only the person who agreed, with the wording they agreed to', /Ann Lee/.test(csv) && !/Bo Chen/.test(csv) && /Las Vegas Restaurants/.test(csv) && /sms1/.test(csv), csv.slice(0, 300));
  const [dl2] = await Promise.all([ad.waitForEvent('download'), ad.click('#csvMail')]);
  const csv2 = fs.readFileSync(await dl2.path(), 'utf8');
  ok('the email list has only the person who agreed to email', /Bo Chen/.test(csv2) && !/Ann Lee/.test(csv2));
  await ad.click('[data-redeem]'); await ad.waitForTimeout(500);
  ok('marking a coupon used is saved', Object.values((await emu('GET', '/lvr_coupons/claims/van', undefined, OWNER)).j).some(x => x.redeemed === true && x.redeemedAt));
  const nBefore = Object.keys((await emu('GET', '/lvr_coupons/claims/van', undefined, OWNER)).j).length;
  await ad.click('[data-delclaim]'); await ad.waitForTimeout(600);
  const after = (await emu('GET', '/lvr_coupons/claims/van', undefined, OWNER)).j || {};
  ok('removing a customer deletes the claim and their duplicate-check entry', Object.keys(after).length === nBefore - 1 && Object.keys((await emu('GET', '/lvr_coupons/idx/van', undefined, OWNER)).j || {}).length === 2 * (nBefore - 1));
  // team: one QR code per employee
  await ad.click('.back-link'); await ad.waitForSelector('.program-card');
  await ad.click('[data-act="team"][data-slug="van"]'); await ad.waitForSelector('#addStaff');
  const tt = await ad.textContent('#view');
  ok('the team page counts the employee\'s signups, keys earned and keys still to give', /Maria/.test(tt) && /1 signed up/.test(tt) && /2 keys earned/.test(tt) && /2 keys still to give/.test(tt), tt.slice(0, 400));
  await ad.fill('#fStaffName', 'Jose'); await ad.click('#addStaff'); await ad.waitForSelector('#qrBox svg');
  const staff = (await emu('GET', '/lvr_coupons/staff/van', undefined, OWNER)).j || {};
  const jose = Object.keys(staff).find(k => /^jose-/.test(k));
  ok('adding an employee saves them and shows their own QR code and sign', !!jose && (await ad.textContent('#printArea')).includes('Jose') && (await ad.textContent('#printArea')).includes('&e=' + jose));
  const jsvg = await ad.innerHTML('#qrBox'); const msvg = svg; ok('the employee QR code is different from the restaurant QR code', jsvg !== msvg);
  await ad.click('.back-link'); await ad.waitForSelector('[data-t="paid"]');
  await ad.click('[data-t="paid"]'); await ad.waitForTimeout(500);
  ok('marking the employee\'s keys as given is saved', Object.values((await emu('GET', '/lvr_coupons/claims/van', undefined, OWNER)).j).some(x => x.ref === 'maria-7k3' && x.staffPaid === true));
  await ad.click('.back-link'); await ad.waitForSelector('.program-card');
  await ad.click('[data-act="claims"][data-slug="van"]'); await ad.waitForSelector('.claim-row');
  ok('the customer list shows Instagram and which employee brought them', /@ann\.lee/.test(await ad.textContent('#view')) && /Signed up through Maria/.test(await ad.textContent('#view')));
  await ad.click('[data-wk]'); await ad.waitForTimeout(500);
  ok('marking a customer\'s welcome key as given is saved', Object.values((await emu('GET', '/lvr_coupons/claims/van', undefined, OWNER)).j).some(x => x.welcomePaid === true));
  const [dl3] = await Promise.all([ad.waitForEvent('download'), ad.click('#csvAll')]);
  const csv3 = fs.readFileSync(await dl3.path(), 'utf8');
  ok('the full download has Instagram, the employee and the key columns', /Instagram/.test(csv3) && /@ann\.lee/.test(csv3) && /Maria/.test(csv3) && /Welcome key given/.test(csv3), csv3.slice(0, 300));
  await ad.click('.back-link'); await ad.waitForSelector('.program-card');
  // new program through the form
  await ad.click('#newProgramBtn');
  await ad.fill('#fBizName', 'Noodle Bar'); await ad.fill('#fSlug', 'Noodle Bar'); await ad.fill('#fOffer', 'Free spring rolls'); await ad.fill('#fMaxClaims', '25'); await ad.click('#saveBtn');
  await ad.waitForSelector('#qrBox svg');
  const np = (await emu('GET', '/lvr_coupons/programs/noodle-bar')).j;
  ok('creating a restaurant saves it and goes straight to its QR code', np && np.bizName === 'Noodle Bar' && np.maxClaims === 25 && np.active === true);
  // a signed-out visitor to the admin page
  const stranger = await browser.newContext(); await route(stranger, false);
  const sp = await stranger.newPage(); await sp.goto(base + '/lvr-coupons-admin.html');
  ok('without owner sign-in the admin page stays locked', await sp.isVisible('#pin-screen') && !(await sp.isVisible('#app')));
  ok('no page errors', errors.length === 0, errors.join(' | '));
  console.log(`\n${pass} passed, ${fail} failed`);
  await browser.close(); srv.close(); process.exit(fail ? 1 : 0);
})().catch(e => { console.log('FAIL  crashed: ' + e.stack); process.exit(1); });
