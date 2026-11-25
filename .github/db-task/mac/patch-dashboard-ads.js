// ADSMSG02 (Shane, 2026-11-25): the Ads tab message toggle and the email tools.
//  * a toggle at the top of the Ads tab: Las Vegas Restaurants | Key Technologies (which wording every Ads-tab DM and email uses), remembered on the device;
//  * a second toggle: First hello | Follow-up (a short, gentle second message);
//  * "Email the list": copies a MAIL-MERGE SHEET of the businesses currently shown (name, email, subject, message, kind, status) for Google Sheets + Gmail, or downloads it as a CSV,
//    skips ones with no email, already emailed, bounced, not interested, problem or ghosted (unless you tick "include already emailed"), and "Mark these as emailed" updates the cards after you send;
//  * the business mailing address (kept on this device only) and a plain opt-out line are added to the bottom of every email;
//  * a link to the DM room that opens in the matching mode (same business list, one by one).
// Marker-fenced and idempotent; upgrades the first version (ADSMSG01) in place. Does not change any PIN, any data or any rule. usage: node patch-dashboard-ads.js index.html
const fs = require('fs');
const file = process.argv[2];
if (!file) { console.error('usage: node patch-dashboard-ads.js index.html'); process.exit(1); }
let s = fs.readFileSync(file, 'utf8');
// The contact email for replies is handed in by the deploy script (REPLY_EMAIL, typed by Shane in Terminal) so it is never written into this public file.
const REPLY = (process.env.REPLY_EMAIL || '').trim();
if (REPLY && !/^[^\s@'"\\<>]+@[^\s@'"\\<>]+\.[^\s@'"\\<>]+$/.test(REPLY)) { console.error('ADSMSG02: REPLY_EMAIL does not look like an email address - nothing changed'); process.exit(4); }
if (/ADSMSG02/.test(s)) {
  if (!REPLY) { console.log('ADSMSG02 already present, skipping'); process.exit(0); }
  console.log('ADSMSG02 present: refreshing it with the contact email');
}

// 1) the five places that hold the old sponsorship message. Skipped (not an error) when version 1 already replaced them.
const reMsg = /'Hello '\+(\w+)\+',\\n\\nMy name is Shane Christensen\.[^;]{0,1800}?\(\d{3}\) \d{3}-\d{4}'/g;
const reMail = /var subject='Sponsorship spot on @lasvegas_restaurants';\s*var body='Hello '\+(\w+)\+',\\n\\nMy name is Shane Christensen\.[^;]{0,1800}?\(\d{3}\) \d{3}-\d{4}';/;
let cMail = 0, cMsg = 0;
s = s.replace(reMail, (m, v) => { cMail++; return "var _adsMail=_advMailParts(" + v + ");var subject=_adsMail.subject;var body=_adsMail.body;"; });
s = s.replace(reMsg, (m, v) => { cMsg++; return "_advDMText(" + v + ")"; });
const had1 = /ADSMSG01|_advDMText\(/.test(s);
console.log('ADSMSG02: email message replaced ' + cMail + ' time(s); DM messages replaced ' + cMsg + ' time(s)' + (had1 ? ' (version 1 was already on the page)' : ''));
if ((cMail < 1 || cMsg < 1) && !had1) { console.error('ADSMSG02: the live page does not have the old messages in the expected shape - nothing changed'); process.exit(1); }

// 2) take out version 1 (toggle block and script) if it is there
s = s.replace(/<!--ADSMSG-TOGGLE-START-->[\s\S]*?<!--ADSMSG-TOGGLE-END-->/, '');
s = s.replace(/<div id="adsmsg-toggle"[\s\S]*?<\/pre><\/details><\/div>/, '');
s = s.replace(/<!--ADSMSG-START-->[\s\S]*?<!--ADSMSG-END-->/, '');

// 3) the new toggle + email block, at the top of the Ads tab
const BTN = 'flex:1;border:0;padding:12px 8px;font-size:14px;font-weight:800;cursor:pointer;';
const GRP = 'display:flex;border:1px solid rgba(255,255,255,.3);border-radius:10px;overflow:hidden;';
const LBL = 'color:rgba(255,255,255,.7);font-size:12px;font-weight:700;letter-spacing:.04em;';
const SM = 'color:rgba(255,255,255,.75);font-size:12.5px;line-height:1.45;margin:0;';
const ACT = 'border:0;border-radius:10px;padding:12px 14px;font-size:14px;font-weight:800;cursor:pointer;background:#00BCD4;color:#00212b;';
const GHO = 'border:1px solid rgba(255,255,255,.35);border-radius:10px;padding:12px 14px;font-size:14px;font-weight:700;cursor:pointer;background:transparent;color:#fff;';
const TOG =
'<div id="adsmsg-toggle" data-adsmsg="2" style="width:100%;display:flex;flex-direction:column;gap:8px;padding:4px 0 10px;">' +
'<div style="' + LBL + '">MESSAGE FOR THIS TAB</div>' +
'<div role="group" aria-label="Which message to send from the Ads tab" style="' + GRP + '">' +
'<button type="button" id="adsmsg-lvr" onclick="advSetMsgMode(\'lvr\')" style="' + BTN + '">Las Vegas Restaurants</button>' +
'<button type="button" id="adsmsg-kt" onclick="advSetMsgMode(\'kt\')" style="' + BTN + 'border-left:1px solid rgba(255,255,255,.3);">Key Technologies</button></div>' +
'<div role="group" aria-label="First hello or follow-up" style="' + GRP + '">' +
'<button type="button" id="adsmsg-first" onclick="advSetMsgKind(\'first\')" style="' + BTN + '">First hello</button>' +
'<button type="button" id="adsmsg-follow" onclick="advSetMsgKind(\'follow\')" style="' + BTN + 'border-left:1px solid rgba(255,255,255,.3);">Follow-up</button></div>' +
'<details id="adsmsg-prev"><summary style="color:rgba(255,255,255,.85);font-size:14px;font-weight:700;cursor:pointer;padding:6px 0;">Email the list, preview and mailing address</summary>' +
'<div style="display:flex;flex-direction:column;gap:8px;padding:6px 0 2px;">' +
'<p id="adsmsg-stat" style="' + SM + '"></p>' +
'<label style="' + SM + 'display:flex;gap:8px;align-items:center;"><input type="checkbox" id="adsmsg-incl"> Include ones already emailed</label>' +
'<div style="display:flex;gap:8px;flex-wrap:wrap;"><button type="button" onclick="advCopyMailMerge()" style="' + ACT + '">Copy mail-merge sheet</button><button type="button" onclick="advDownloadMailMerge()" style="' + GHO + '">Download CSV</button><button type="button" onclick="advMarkListEmailed()" style="' + GHO + '">Mark these as emailed</button></div>' +
'<p style="' + SM + '">How: tap Copy, paste into a new Google Sheet (cell A1), then send with a mail-merge add-on connected to your Gmail. About 60 a day is a steady pace that keeps your address healthy. After you send, tap Mark these as emailed. The sheet is exactly the businesses showing below.</p>' +
'<label for="adsmsg-addr" style="' + SM + '">Your business mailing address, added to the bottom of emails (the law requires one in business emails). Saved on this device only.</label>' +
'<input id="adsmsg-addr" type="text" maxlength="160" autocomplete="off" placeholder="Street, city, state ZIP" style="width:100%;box-sizing:border-box;padding:10px 12px;border-radius:10px;border:1px solid rgba(255,255,255,.3);background:rgba(255,255,255,.07);color:#fff;font-size:14px;">' +
'<pre id="adsmsg-pre" style="white-space:pre-wrap;word-break:break-word;margin:4px 0 0;padding:10px 12px;border-radius:10px;background:rgba(255,255,255,.07);color:#fff;font:13px/1.45 system-ui,sans-serif;max-height:280px;overflow:auto;"></pre>' +
'<a href="/kt-outreach.html" onclick="advOpenDmRoom()" style="' + GHO + 'text-align:center;text-decoration:none;">Open the DM room (same list, one by one)</a>' +
'</div></details></div>';
let anchored = 0;
s = s.replace(/<div id="ads-subtabs"/, (m) => { anchored++; return '<!--ADSMSG-TOGGLE-START-->' + TOG + '<!--ADSMSG-TOGGLE-END-->' + m; });
if (!anchored) { s = s.replace(/<div id="adv-search-row"/, (m) => { anchored++; return '<!--ADSMSG-TOGGLE-START-->' + TOG + '<!--ADSMSG-TOGGLE-END-->' + m; }); }
if (!anchored) { console.error('ADSMSG02: could not find the top of the Ads tab - nothing changed'); process.exit(2); }

// 4) the messages, the switches and the email tools
const JS = `
<script>
/* ADSMSG02 */
(function(){
  var MK='lv_ads_msg_mode_v1',KK='lv_ads_msg_kind_v1',AK='lv_ads_addr_v1',REPLY=__REPLY__;
  function ls(k){try{return localStorage.getItem(k)||''}catch(e){return ''}}
  function lset(k,v){try{localStorage.setItem(k,v)}catch(e){}}
  function mode(){return ls(MK)==='kt'?'kt':'lvr'}
  function kind(){return ls(KK)==='follow'?'follow':'first'}
  window.advMsgMode=mode;window.advMsgKind=kind;
  function addr(){return ls(AK).trim()}
  function foot(){var a=addr();return '\\n\\nIf you would rather not hear from us, reply "no thanks" and we will not contact you again.'+(a?'\\n'+a:'')}
  var M={
   lvr:{
    first:{dm:function(n){return 'Hello '+n+',\\n\\n'+
      'I am opening up a few sponsorship spots on the Stories page of @lasvegas_restaurants (129K followers, mostly Las Vegas locals) and would love to see if '+n+' is a fit.\\n\\n'+
      'Here is how it works: $50/month, month-to-month, cancel anytime. I repost directly from your page to my Stories twice a month, every two weeks. No extra work on your end: I pick a post or reel you already have and share it with my audience.\\n\\n'+
      'It is a direct line to people in your area. Would you like to try it?\\n\\n'+
      'Best,\\nShane Christensen\\nCreator of @lasvegas_restaurants'},
      subject:function(n){return 'Sponsorship spot on @lasvegas_restaurants'}},
    follow:{dm:function(n){return 'Hi '+n+', just a quick follow-up on my note about a sponsorship spot on @lasvegas_restaurants. Happy to answer any questions, and no worries at all if now is not the right time!'},
      body:function(n){return 'Hello '+n+',\\n\\nJust a quick follow-up on my note about a sponsorship spot on the @lasvegas_restaurants Stories page. I would be glad to answer any questions.\\n\\nIf now is not the right time, that is completely okay.\\n\\nBest,\\nShane Christensen\\nCreator of @lasvegas_restaurants'},
      subject:function(n){return 'Re: Sponsorship spot on @lasvegas_restaurants'}}
   },
   kt:{
    first:{dm:function(n){return 'Hi '+n+'! We help local Las Vegas businesses save time with AI/SI, like an AI receptionist that answers calls and texts, plus websites and small custom tools. Would you like a free, friendly look at where it could help '+n+'? No pressure at all. keytechnologies.si'},
      body:function(n){return 'Hello '+n+' team,\\n\\n'+
      'We hope your week is going well!\\n\\n'+
      'We help local Las Vegas businesses save time with AI/SI, and we thought '+n+' might enjoy a couple of ideas. Things like:\\n'+
      '- an AI receptionist that answers calls and texts, so nothing gets missed\\n'+
      '- a website or booking page that works nicely on every phone\\n'+
      '- small custom tools that take repetitive office work off your plate\\n\\n'+
      'If that sounds interesting, we would be happy to put together a free, friendly review of '+n+' with two practical ideas. No pressure and no obligation.\\n\\n'+
      'Would a quick 10 minute chat this week be okay? Just reply and we will find a time that works for you.\\n\\n'+
      'Warm regards,\\nShane Christensen\\nKey Technologies\\nkeytechnologies.si'},
      subject:function(n){return 'A free idea or two for '+n}},
    follow:{dm:function(n){return 'Hi '+n+', just a gentle check-in on my note about a free AI/SI review. Happy to share a couple of ideas whenever the timing suits you, and no worries at all if not!'},
      body:function(n){return 'Hello '+n+' team,\\n\\nJust a gentle check-in on my earlier note. If a free, friendly look at where AI/SI could help '+n+' sounds useful, we would be happy to share a couple of ideas whenever the timing suits you.\\n\\nAnd if now is not the right time, no problem at all.\\n\\nWarm regards,\\nShane Christensen\\nKey Technologies\\nkeytechnologies.si'},
      subject:function(n){return 'Re: A free idea or two for '+n}}
   }
  };
  M.lvr.first.body=M.lvr.first.dm; // the first sponsorship message reads the same as an email
  window._advDMText=function(n){n=n||'there';return M[mode()][kind()].dm(n)};
  window._advMailParts=function(n){n=n||'there';var m=M[mode()][kind()];return {subject:m.subject(n),body:m.body(n)+(REPLY?'\\n'+REPLY:'')+foot()}};
  function nm(a){var o=(typeof advNameOverrideMap!=='undefined'&&advNameOverrideMap[a.num]);return o||a.name||'there'}
  function rows(){
    var list=(typeof _advVFiltered!=='undefined'&&_advVFiltered&&_advVFiltered.length)?_advVFiltered:[],incl=!!(document.getElementById('adsmsg-incl')&&document.getElementById('adsmsg-incl').checked);
    var seen={},out=[],st={shown:list.length,noemail:0,sent:0,bounced:0,skipped:0,dupe:0};
    list.forEach(function(it){
      var a=it&&it.a;if(!a||a.num===undefined)return;var num=a.num,em='';
      try{em=(typeof _advGetEmail==='function'?_advGetEmail(num):(a.email||''))||''}catch(e){em=a.email||''}
      em=String(em).trim();
      if(!/^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/.test(em)){st.noemail++;return}
      var bad=(typeof advNotInterestedMap!=='undefined'&&advNotInterestedMap[num])||(typeof advGhostedMap!=='undefined'&&advGhostedMap[num])||(typeof advProblemMap!=='undefined'&&advProblemMap[num])||it.problem||(typeof advDeletedMap!=='undefined'&&advDeletedMap[num]);
      if(bad){st.skipped++;return}
      if(it.status==='bounced'){st.bounced++;return}
      if(it.status==='sent'&&!incl){st.sent++;return}
      var key=em.toLowerCase();if(seen[key]){st.dupe++;return}seen[key]=1;
      var cat='';try{cat=(typeof _advCat==='function'?_advCat(a):'')||''}catch(e){}
      out.push({num:num,name:nm(a),email:em,cat:cat,status:it.status||''});
    });
    return {rows:out,stat:st};
  }
  function q(v){return '"'+String(v==null?'':v).replace(/"/g,'""')+'"'}
  function sheet(sep){
    var r=rows().rows,L=[['Business','Email','Subject','Message','Kind','Status'].map(q).join(sep)];
    r.forEach(function(x){var p=window._advMailParts(x.name);L.push([x.name,x.email,p.subject,p.body,x.cat,x.status||'to email'].map(q).join(sep))});
    return {text:L.join('\\n'),n:r.length};
  }
  function toast(t){if(typeof showDMToast==='function')showDMToast(t);else alert(t)}
  window.advCopyMailMerge=function(){
    var r=sheet('\\t');if(!r.n){toast('Nothing to email in this list. Pick a list below first (the businesses showing).');return}
    function fb(){var ta=document.createElement('textarea');ta.value=r.text;ta.style.cssText='position:fixed;opacity:0';document.body.appendChild(ta);ta.focus();ta.select();try{document.execCommand('copy')}catch(e){}document.body.removeChild(ta);toast('Copied '+r.n+' emails. Paste into a Google Sheet.')}
    if(navigator.clipboard&&navigator.clipboard.writeText)navigator.clipboard.writeText(r.text).then(function(){toast('Copied '+r.n+' emails. Paste into a Google Sheet.')}).catch(fb);else fb();
    paint();
  };
  window.advDownloadMailMerge=function(){
    var r=sheet(',');if(!r.n){toast('Nothing to email in this list. Pick a list below first (the businesses showing).');return}
    try{var b=new Blob(['\\ufeff'+r.text],{type:'text/csv;charset=utf-8'}),u=URL.createObjectURL(b),a=document.createElement('a');a.href=u;a.download='mail-merge-'+mode()+'-'+kind()+'-'+new Date().toISOString().slice(0,10)+'.csv';document.body.appendChild(a);a.click();document.body.removeChild(a);setTimeout(function(){URL.revokeObjectURL(u)},4000);toast('Downloaded '+r.n+' emails')}catch(e){toast('Could not download. Use Copy instead.')}
  };
  window.advMarkListEmailed=function(){
    var r=rows().rows;if(!r.length){toast('Nothing to mark in this list.');return}
    if(!confirm('Mark '+r.length+' businesses as emailed today? Only do this after you have sent the emails.'))return;
    var today=new Date().toISOString();
    r.forEach(function(x){
      var atts=(advAttemptsMap[x.num]||[]).slice(),idx=-1;
      for(var i=atts.length-1;i>=0;i--){if(atts[i].status==='pending'){idx=i;break}}
      if(idx>=0){atts[idx].status='sent';atts[idx].date=today}else atts.push({email:x.email,status:'sent',date:today});
      advAttemptsMap[x.num]=atts;advLastContactedMap[x.num]=today;
    });
    if(typeof advFbSave==='function')advFbSave();
    if(typeof advRender==='function')advRender();
    toast('Marked '+r.length+' as emailed');
  };
  window.advOpenDmRoom=function(){lset('outreachMode',mode()==='kt'?'kt':'lvr')};
  function paint(){
    var m=mode(),k=kind(),B={lvr:'adsmsg-lvr',kt:'adsmsg-kt',first:'adsmsg-first',follow:'adsmsg-follow'};
    [['lvr',m==='lvr'],['kt',m==='kt'],['first',k==='first'],['follow',k==='follow']].forEach(function(p){var b=document.getElementById(B[p[0]]);if(b){b.style.background=p[1]?'#00BCD4':'transparent';b.style.color=p[1]?'#00212b':'#fff';b.setAttribute('aria-pressed',p[1]?'true':'false')}});
    var ai=document.getElementById('adsmsg-addr');if(ai&&!ai._wired){ai._wired=true;ai.value=addr();ai.addEventListener('input',function(){lset(AK,ai.value.trim());paint()})}
    var ic=document.getElementById('adsmsg-incl');if(ic&&!ic._wired){ic._wired=true;ic.addEventListener('change',paint)}
    var det=document.getElementById('adsmsg-prev');if(det&&!det._wired){det._wired=true;det.addEventListener('toggle',paint)}
    var pre=document.getElementById('adsmsg-pre');
    if(pre){var p=window._advMailParts('Sample Business');pre.textContent='DM:\\n'+window._advDMText('Sample Business')+'\\n\\n---\\nEmail subject: '+p.subject+'\\n\\n'+p.body+(addr()?'':'\\n\\n(No mailing address saved yet. Type it above before you send emails.)')}
    var sv=document.getElementById('adsmsg-stat');
    if(sv){var r=rows(),t=r.stat;sv.textContent=r.rows.length+' ready to email from the '+t.shown+' showing below.'+(t.noemail?' '+t.noemail+' have no email.':'')+(t.sent?' '+t.sent+' already emailed.':'')+(t.bounced?' '+t.bounced+' bounced.':'')+(t.skipped?' '+t.skipped+' skipped (not interested, problem or ghosted).':'')+(t.dupe?' '+t.dupe+' duplicate email'+(t.dupe===1?'':'s')+' left out.':'')}
  }
  window.advSetMsgMode=function(m){lset(MK,m==='kt'?'kt':'lvr');paint();toast(m==='kt'?'Now sending the Key Technologies message':'Now sending the Las Vegas Restaurants message')};
  window.advSetMsgKind=function(k){lset(KK,k==='follow'?'follow':'first');paint();toast(k==='follow'?'Now sending the short follow-up':'Now sending the first hello')};
  window.advPaintMsgToggle=paint;
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',paint);else paint();
  setTimeout(paint,1500);
})();
</script>
`;
if (!/<\/body>/.test(s)) { console.error('ADSMSG02: no </body> found - nothing changed'); process.exit(3); }
s = s.replace(/<\/body>/, () => '<!--ADSMSG-START-->' + JS.replace('__REPLY__', JSON.stringify(REPLY)) + '<!--ADSMSG-END--></body>');
fs.writeFileSync(file, s);
console.log('ADSMSG02 applied (toggle, follow-up, mail-merge sheet, mark as emailed, DM room link' + (REPLY ? '; every email ends with the contact email' : '') + ')');
