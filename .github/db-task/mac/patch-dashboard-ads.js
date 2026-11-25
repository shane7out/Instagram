// ADSMSG01 (Shane, 2026-11-25: "When I click on the ads tab, I want a little toggle so I can switch between Las Vegas Restaurants and Key Technologies to determine who gets what message... I don't need to introduce myself in the very beginning anymore.")
// Adds a two-way toggle at the top of the Ads tab (and a box for the business mailing address that is added to the bottom of emails with a plain opt-out line; the address is kept on this device only, never in this file). The choice is remembered on this device. It decides the wording of EVERY Ads-tab DM and email: advertisers (and the category lists), Golf, Models and Influencers.
//   Las Vegas Restaurants = the sponsorship offer as before, but opening with the point (no "My name is Shane Christensen..." paragraph) and without the cell number.
//   Key Technologies      = a professional AI/SI message (DM and email), no price, no introduction up front.
// Marker-fenced and idempotent. Does not change any PIN, any data or any rule. usage: node patch-dashboard-ads.js index.html
const fs = require('fs');
const file = process.argv[2];
if (!file) { console.error('usage: node patch-dashboard-ads.js index.html'); process.exit(1); }
let s = fs.readFileSync(file, 'utf8');
if (/ADSMSG01/.test(s)) { console.log('ADSMSG01 already present, skipping'); process.exit(0); }

// 1) the five places that hold the old sponsorship message (DM, email body, golf, models, influencers)
const reMsg = /'Hello '\+(\w+)\+',\\n\\nMy name is Shane Christensen\.[^;]{0,1800}?\(\d{3}\) \d{3}-\d{4}'/g;
let cMsg = 0;
// the advertiser email first: its subject and body are replaced as a pair
const reMail = /var subject='Sponsorship spot on @lasvegas_restaurants';\s*var body='Hello '\+(\w+)\+',\\n\\nMy name is Shane Christensen\.[^;]{0,1800}?\(\d{3}\) \d{3}-\d{4}';/;
let cMail = 0;
s = s.replace(reMail, (m, v) => { cMail++; return "var _adsMail=_advMailParts(" + v + ");var subject=_adsMail.subject;var body=_adsMail.body;"; });
s = s.replace(reMsg, (m, v) => { cMsg++; return "_advDMText(" + v + ")"; });
console.log('ADSMSG01: email message replaced ' + cMail + ' time(s); DM messages replaced ' + cMsg + ' time(s)');
if (cMail < 1 || cMsg < 1) { console.error('ADSMSG01: the live page does not have the old messages in the expected shape - nothing changed'); process.exit(1); }

// 2) the toggle, at the top of the Ads tab
const TOG =
'<div id="adsmsg-toggle" data-adsmsg="1" style="width:100%;display:flex;flex-direction:column;gap:6px;padding:4px 0 8px;">' +
'<div style="color:rgba(255,255,255,.7);font-size:12px;font-weight:700;letter-spacing:.04em;">MESSAGE FOR THIS TAB</div>' +
'<div role="group" aria-label="Which message to send from the Ads tab" style="display:flex;border:1px solid rgba(255,255,255,.3);border-radius:10px;overflow:hidden;">' +
'<button type="button" id="adsmsg-lvr" onclick="advSetMsgMode(\'lvr\')" style="flex:1;border:0;padding:12px 8px;font-size:14px;font-weight:800;cursor:pointer;">Las Vegas Restaurants</button>' +
'<button type="button" id="adsmsg-kt" onclick="advSetMsgMode(\'kt\')" style="flex:1;border:0;border-left:1px solid rgba(255,255,255,.3);padding:12px 8px;font-size:14px;font-weight:800;cursor:pointer;">Key Technologies</button></div>' +
'<details id="adsmsg-prev"><summary style="color:rgba(255,255,255,.75);font-size:13px;cursor:pointer;padding:4px 0;">See the message and set your mailing address</summary><label for="adsmsg-addr" style="display:block;color:rgba(255,255,255,.75);font-size:12px;margin:8px 0 4px;">Your business mailing address, added to the bottom of emails (the law requires one in business emails). Saved on this device only.</label><input id="adsmsg-addr" type="text" maxlength="160" autocomplete="off" placeholder="Street, city, state ZIP" style="width:100%;box-sizing:border-box;padding:10px 12px;border-radius:10px;border:1px solid rgba(255,255,255,.3);background:rgba(255,255,255,.07);color:#fff;font-size:14px;"><pre id="adsmsg-pre" style="white-space:pre-wrap;word-break:break-word;margin:8px 0 0;padding:10px 12px;border-radius:10px;background:rgba(255,255,255,.07);color:#fff;font:13px/1.45 system-ui,sans-serif;max-height:260px;overflow:auto;"></pre></details></div>';
let anchored = 0;
s = s.replace(/<div id="ads-subtabs"/, (m) => { anchored++; return TOG + m; });
if (!anchored) { s = s.replace(/<div id="adv-search-row"/, (m) => { anchored++; return TOG + m; }); }
if (!anchored) { console.error('ADSMSG01: could not find the top of the Ads tab - nothing changed'); process.exit(2); }

// 3) the messages and the switch
const JS = `
<script>
/* ADSMSG01 */
(function(){
  var KEY='lv_ads_msg_mode_v1';
  function mode(){try{return localStorage.getItem(KEY)==='kt'?'kt':'lvr'}catch(e){return 'lvr'}}
  window.advMsgMode=mode;
  var LVR_DM=function(n){return 'Hello '+n+',\\n\\n'+
    'I am opening up a few sponsorship spots on the Stories page of @lasvegas_restaurants (129K followers, mostly Las Vegas locals) and would love to see if '+n+' is a fit.\\n\\n'+
    'Here is how it works: $50/month, month-to-month, cancel anytime. I repost directly from your page to my Stories twice a month, every two weeks. No extra work on your end: I pick a post or reel you already have and share it with my audience.\\n\\n'+
    'It is a direct line to people in your area. Would you like to try it?\\n\\n'+
    'Best,\\nShane Christensen\\nCreator of @lasvegas_restaurants'};
  var KT_DM=function(n){return 'Hello '+n+', we follow your page and admire what you have built. Key Technologies helps Las Vegas businesses save time with AI/SI: an AI receptionist that answers calls and texts, websites, and custom tools. May we send you a free review with two practical ideas for '+n+'? keytechnologies.si'};
  var KT_MAIL_BODY=function(n){return 'Hello '+n+' team,\\n\\n'+
    'We follow '+n+' and admire what you have built.\\n\\n'+
    'Key Technologies helps Las Vegas businesses save time and win more customers with AI/SI. We build:\\n'+
    '- an AI receptionist that answers calls and texts around the clock\\n'+
    '- websites and booking tools that work on every phone\\n'+
    '- custom tools that take repetitive office work off your plate\\n\\n'+
    'We would like to send you a free review of '+n+': a short, plain-language look at where AI/SI could realistically help, with two practical ideas you can use right away. There is no obligation.\\n\\n'+
    'Would a 10 minute call this week suit you? Reply to this message and we will find a time that works.\\n\\n'+
    'Best regards,\\nShane Christensen\\nKey Technologies\\nkeytechnologies.si'};
  var AKEY='lv_ads_addr_v1';
  function addr(){try{return (localStorage.getItem(AKEY)||'').trim()}catch(e){return ''}}
  function foot(){var a=addr();return '\\n\\nIf you would rather not hear from us, reply "no thanks" and we will not contact you again.'+(a?'\\n'+a:'')}
  window._advDMText=function(n){n=n||'there';return mode()==='kt'?KT_DM(n):LVR_DM(n)};
  window._advMailParts=function(n){n=n||'there';return mode()==='kt'?{subject:'A free AI/SI review for '+n,body:KT_MAIL_BODY(n)+foot()}:{subject:'Sponsorship spot on @lasvegas_restaurants',body:LVR_DM(n)+foot()}};
  function paint(){
    var m=mode(),a=document.getElementById('adsmsg-lvr'),b=document.getElementById('adsmsg-kt'),pre=document.getElementById('adsmsg-pre');
    if(a&&b){
      var on='background:#00BCD4;color:#00212b;',off='background:transparent;color:#fff;';
      a.style.background=m==='lvr'?'#00BCD4':'transparent';a.style.color=m==='lvr'?'#00212b':'#fff';
      b.style.background=m==='kt'?'#00BCD4':'transparent';b.style.color=m==='kt'?'#00212b':'#fff';
      a.setAttribute('aria-pressed',m==='lvr'?'true':'false');b.setAttribute('aria-pressed',m==='kt'?'true':'false');
    }
    var ai=document.getElementById('adsmsg-addr');if(ai&&!ai._wired){ai._wired=true;ai.value=addr();ai.addEventListener('input',function(){try{localStorage.setItem(AKEY,ai.value.trim())}catch(e){}paint()})}
    if(pre){var p=window._advMailParts('Sample Business');pre.textContent='DM:\\n'+window._advDMText('Sample Business')+(m==='kt'?'\\n\\n---\\nEmail subject: '+p.subject+'\\n\\n'+p.body:'\\n\\n---\\nEmail subject: '+p.subject+'\\n\\n'+p.body)+(addr()?'':'\\n\\n(No mailing address saved yet. Type it above before you send emails.)')}
  }
  window.advSetMsgMode=function(m){try{localStorage.setItem(KEY,m==='kt'?'kt':'lvr')}catch(e){}paint();if(typeof showDMToast==='function')showDMToast(m==='kt'?'Now sending the Key Technologies message':'Now sending the Las Vegas Restaurants message')};
  window.advPaintMsgToggle=paint;
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',paint);else paint();
  setTimeout(paint,1500);
})();
</script>
`;
if (!/<\/body>/.test(s)) { console.error('ADSMSG01: no </body> found - nothing changed'); process.exit(3); }
s = s.replace(/<\/body>/, () => '<!--ADSMSG-START-->' + JS + '<!--ADSMSG-END--></body>');
fs.writeFileSync(file, s);
console.log('ADSMSG01 applied (toggle added, ' + (cMail + cMsg) + ' messages now follow it)');
