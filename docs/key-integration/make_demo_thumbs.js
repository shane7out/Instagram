/* Makes the small preview picture for each demo tile (sites/key-technologies/key-platform/demos/thumbs/*.jpg).
   Run with the site served locally:  cd sites/key-technologies && python3 -m http.server 8765
   then (Playwright installed):       NODE_PATH=$(npm root -g) node docs/key-integration/make_demo_thumbs.js
   Re-run it after changing how a demo looks. */
const {chromium}=require('playwright');const fs=require('fs');
const ROOT='http://localhost:8765/key-platform/';const OUT=__dirname+'/../../sites/key-technologies/key-platform/demos/thumbs/';
const ONLY=(process.env.ONLY||'').split(',').filter(Boolean);
const LIST0=JSON.parse(fs.readFileSync(__dirname+'/../../sites/key-technologies/key-platform/demos/list.json'));
const LIST=LIST0.filter(x=>!ONLY.length||ONLY.includes(x.thumb.replace(/^.*thumbs\//,'').replace(/\.jpg$/,'')));
fs.mkdirSync(OUT,{recursive:true});
const STEPS={ // optional action so the picture shows the demo doing something
 'content-creators':async p=>{await p.click('#cg')},
 'business-automation':async p=>{await p.click('#wr');await p.waitForTimeout(2800)},
 'ai-agents':async p=>{await p.click('#ar');await p.waitForTimeout(2200)},
 'data-knowledge':async p=>{await p.fill('#kq','What are your hours?');await p.click('#kg')},
 'customer-experience':async p=>{await p.click('#xg')},
 'cybersecurity':async p=>{await p.click('#hr');await p.waitForTimeout(4200)},
 'private-llm':async p=>{await p.click('#ra')},
 'social-media':async p=>{await p.click('#sg [data-i="2"]')},
 'booking-scheduling':async p=>{await p.click('[data-t="0"]');await p.fill('#bn','Maria');await p.click('#bk')},
 'reviews-reputation':async p=>{await p.click('[data-d="1"]')},
 'rewards':async p=>{await p.click('#pe3')},
 'voice':async p=>{await p.evaluate(()=>document.querySelector('.kp-tabs [data-page=live-demo]').click());await p.click('#runCall');await p.waitForTimeout(5200)},
 'email':async p=>{await p.evaluate(()=>document.querySelector('.kp-tabs [data-page=inbox]').click());await p.click('#generate');await p.waitForTimeout(600)},
 'sales':async p=>{await p.evaluate(()=>document.querySelector('.kp-tabs [data-page=services]').click());await p.waitForTimeout(300)}
};
(async()=>{const b=await chromium.launch();
for(const x of LIST){const slug=x.thumb.replace(/^.*thumbs\//,'').replace(/\.jpg$/,'');
 const c=await b.newContext({viewport:{width:1100,height:900},deviceScaleFactor:0.6});const p=await c.newPage();
 await p.goto(ROOT+x.href,{waitUntil:'domcontentloaded'});await p.waitForTimeout(500);
 if(STEPS[slug]){try{await STEPS[slug](p)}catch(e){console.log('step failed',slug,e.message.slice(0,60))}}
 await p.addStyleTag({content:'header,.kp-tourbar,#toast{visibility:hidden!important}'});await p.waitForTimeout(250);
 const sel=await p.$('#widget')?'#widget':'.page.active';const box=await (await p.$(sel)).boundingBox();const sy=await p.evaluate(()=>window.scrollY);box.y+=sy;
 await p.screenshot({path:OUT+slug+'.jpg',type:'jpeg',quality:72,fullPage:true,clip:{x:0,y:Math.max(0,box.y-8),width:1100,height:Math.min(520,box.height+16)}});
 console.log('thumb',slug);await c.close()}
await b.close()})();
