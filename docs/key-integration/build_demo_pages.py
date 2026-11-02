#!/usr/bin/env python3
"""Generates the KEY Platform demo pages (static, fictional data) into sites/key-technologies/key-platform/.
Run from the repo root:  python3 docs/key-integration/build_demo_pages.py"""
import os
OUT = 'sites/key-technologies/key-platform'
LOGO = '''<svg width="30" height="20" viewBox="0 0 60 40" aria-hidden="true"><circle cx="13" cy="20" r="11" fill="none" stroke="#168fff" stroke-width="5"/><rect x="23" y="17.5" width="32" height="5" rx="2.5" fill="#168fff"/><rect x="42" y="22.5" width="5" height="9" rx="2" fill="#168fff"/><rect x="50" y="22.5" width="5" height="12" rx="2" fill="#168fff"/></svg>'''
def page(slug, title, desc, body, script='', current=''):
    nav = ''.join('<a href="%s"%s>%s</a>' % (h, ' aria-current="page"' if k == current else '', t) for k, h, t in [
        ('hub', 'index.html', 'Demos'), ('voice', 'voice.html', 'Voice'), ('email', 'email.html', 'Email'), ('sales', 'sales.html', 'Sales')])
    return f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{title}</title><meta name="description" content="{desc}"><meta name="robots" content="noindex">
<meta name="theme-color" content="#07111f"><link rel="icon" href="../apple-touch-icon.png">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700;800&display=swap">
<link rel="stylesheet" href="key-platform.css"></head><body>
<header class="kp"><div class="wrap nav-row"><a class="logo" href="../index.html" aria-label="Key Technologies, home">{LOGO}<span>KEY TECHNOLOGIES<span class="logo-si">.SI</span></span></a><nav class="kp-nav" aria-label="Demos">{nav}</nav></div></header>
<div class="demo-banner" role="note"><b>Demo only.</b> Fictional data. Nothing here is sent, booked, charged or paid.</div>
<main class="wrap">{body}</main>
<footer class="kp"><div class="wrap">KEY Technologies.si demo prototypes. Every business, person, message, number and price on these pages is made up. Not connected to any real phone line, mailbox, calendar, payment system or customer record. <a href="../index.html#services">Back to all services</a></div></footer>
<div class="toast" id="toast" role="status" aria-live="polite"></div>
<script>function toast(t){{var e=document.getElementById('toast');e.textContent=t;e.className='toast show';clearTimeout(window.__t);window.__t=setTimeout(function(){{e.className='toast'}},3500);}}
{script}</script></body></html>'''

# ---------------- hub
hub = '''<span class="eyebrow">KEY Platform</span>
<h1>See it working. Then we build yours.</h1>
<p class="lede">Three coordinated services from Key Technologies.si, shown as clearly labeled demos. Tap one to try it. Real phone, email and sales connections are separate, reviewed projects that start only with your approval.</p>
<div class="grid g3">
<a class="card" href="voice.html" style="text-decoration:none;color:inherit"><span class="tag solid">Demo</span><h2 style="margin-top:10px">Voice Services</h2><p class="muted">An AI receptionist that answers every call, captures the lead, routes anything urgent to a person and proposes an appointment.</p><span class="btn">Try the Voice demo</span></a>
<a class="card" href="email.html" style="text-decoration:none;color:inherit"><span class="tag solid">Demo</span><h2 style="margin-top:10px">Email Intelligence</h2><p class="muted">Sorts your inbox, drafts grounded replies from your own information, and waits for a person to approve before anything goes out.</p><span class="btn">Try the Email demo</span></a>
<a class="card" href="sales.html" style="text-decoration:none;color:inherit"><span class="tag solid">Demo</span><h2 style="margin-top:10px">Sales Partner Network</h2><p class="muted">A service catalog, quote builder, pipeline and a transparent commission model for independent sales partners.</p><span class="btn">Try the Sales demo</span></a>
</div>
<div class="card real-panel"><h3>What is real and what is a demo</h3><ul><li><b>Demo today:</b> every screen on these pages, with fictional data.</li><li><b>Not connected:</b> phone lines, mailboxes, calendars, payments, payouts and your customer records.</li><li><b>Before anything goes live:</b> a separate review of security, consent, contracts and costs, and your written approval.</li></ul></div>
<p><a class="btn ghost" href="../index.html#contact">Talk to Key Technologies</a></p>'''

# ---------------- voice
voice = '''<span class="eyebrow">Voice Services</span>
<h1>An AI receptionist that never misses a call</h1>
<p class="lede">Play a sample call to a fictional dental office, or type what a caller might say. Watch the lead, the routing and the proposed appointment fill in.</p>
<div class="grid g2">
<section class="card" aria-labelledby="callh"><div class="row" style="justify-content:space-between"><h2 id="callh">Sample call</h2><span class="tag outline" id="callState">Ready</span></div>
<p class="small muted">Desert Rose Dental (fictional). The caller hears: "This call may be recorded to help us serve you."</p>
<div id="transcript" aria-live="polite" style="min-height:220px;display:grid;gap:8px;margin:10px 0"></div>
<div class="row"><button class="btn" id="play">Play sample call</button><button class="btn ghost" id="reset">Reset</button></div>
<hr class="hr"><label for="say">Or say something to the receptionist</label>
<div class="row" style="flex-wrap:nowrap"><input id="say" placeholder="e.g. What are your hours?" autocomplete="off"><button class="btn" id="send">Send</button></div>
<p class="small muted" style="margin-top:6px">Try: hours, price, book, or "I have a toothache and it is an emergency".</p></section>
<section aria-labelledby="resh"><div class="card"><h2 id="resh">What the system captured</h2>
<table><tr><th>Intent</th><td id="rIntent" class="muted">Waiting for a call</td></tr><tr><th>Caller</th><td id="rName" class="muted">-</td></tr><tr><th>Callback number</th><td id="rPhone" class="muted">-</td></tr><tr><th>Reason</th><td id="rWhy" class="muted">-</td></tr><tr><th>Routing</th><td id="rRoute" class="muted">-</td></tr></table></div>
<div class="card"><h3>Proposed appointment</h3><p id="slot" class="muted">None yet.</p><p class="small muted">In a real setup, a booking is made only after your calendar confirms the time. In this demo nothing is booked.</p></div>
<div class="card"><h3>CRM record (demo)</h3><p id="crm" class="muted">None yet.</p></div></section></div>
<div class="card real-panel"><h3>Built in, in the real version</h3><ul><li>A person can take over at any time, and urgent words route to a human at once.</li><li>Consent notice, call logging rules and retention you control.</li><li>Verified phone-provider webhooks, a daily usage budget, and a full log of every call.</li></ul></div>'''
voice_js = '''
var script=[
['ai','Thank you for calling Desert Rose Dental. This call may be recorded. How can I help?'],
['caller','Hi, I would like to book a cleaning for next week.'],
['ai','Happy to help. May I have your name?'],
['caller','Maria Alvarez.'],
['ai','Thanks Maria. What is the best number to reach you?'],
['caller','Seven oh two, five five five, zero one four two.'],
['ai','We have Thursday at 2:30 PM or Friday at 10:00 AM. Which do you prefer?'],
['caller','Thursday works.'],
['ai','I have noted Thursday at 2:30 PM. A team member will confirm by text shortly. Anything else?'],
['caller','No, thank you.']];
var tr=document.getElementById('transcript'),timers=[];
function line(who,t){var d=document.createElement('div');d.style.cssText='padding:9px 12px;border-radius:12px;max-width:92%;border:1px solid var(--line);'+(who==='ai'?'background:var(--card2);':'background:var(--key-deep);margin-left:auto;');d.innerHTML='<b class="small" style="display:block;color:'+(who==='ai'?'var(--key-light)':'#cfe6ff')+'">'+(who==='ai'?'AI receptionist':'Caller')+'</b>'+t;tr.appendChild(d);}
function set(id,v){var e=document.getElementById(id);e.textContent=v;e.className='';}
function stage(i){if(i===1){set('rIntent','New appointment: cleaning');set('rWhy','Cleaning, next week');}if(i===3)set('rName','Maria Alvarez (fictional)');if(i===5)set('rPhone','702-555-0142 (fictional)');if(i===7){set('slot','Thursday, 2:30 PM (proposed, not booked)');set('rRoute','Front desk to confirm by text');}if(i===9){set('crm','New contact and lead created: Maria Alvarez, source Phone, status Needs confirmation.');document.getElementById('callState').textContent='Call finished';}}
function reset(){timers.forEach(clearTimeout);timers=[];tr.innerHTML='';['rIntent','rName','rPhone','rWhy','rRoute','slot','crm'].forEach(function(id){var e=document.getElementById(id);e.textContent=id==='rIntent'?'Waiting for a call':(id==='slot'||id==='crm'?'None yet.':'-');e.className='muted';});document.getElementById('callState').textContent='Ready';document.getElementById('play').disabled=false;}
document.getElementById('play').onclick=function(){reset();this.disabled=true;document.getElementById('callState').textContent='On the call';script.forEach(function(s,i){timers.push(setTimeout(function(){line(s[0],s[1]);stage(i);if(i===script.length-1)document.getElementById('play').disabled=false;},900*(i+1)));});};
document.getElementById('reset').onclick=reset;
function answer(q){q=q.toLowerCase();if(/emergency|pain|bleed|swell|toothache|urgent/.test(q)){set('rIntent','Urgent: possible dental emergency');set('rRoute','Escalated to a human now (on-call line)');return 'I am sorry you are in pain. I am connecting you to our on-call team right now. If this is life threatening, please call 911.';}
if(/hour|open|close/.test(q))return 'We are open Monday to Friday, 8 AM to 5 PM, and Saturday 9 AM to 1 PM.';
if(/price|cost|how much|insurance/.test(q))return 'A cleaning is quoted at the visit after we check your insurance. I can have the front desk call you with an estimate. May I take your name and number?';
if(/book|appointment|schedule|cleaning/.test(q)){set('rIntent','New appointment request');set('slot','Thursday, 2:30 PM (proposed, not booked)');return 'I can help with that. We have Thursday at 2:30 PM or Friday at 10:00 AM. Which do you prefer?';}
return 'I want to be sure you get the right answer, so I will take a message and a team member will call you back. May I have your name and number?';}
function ask(){var i=document.getElementById('say'),v=i.value.trim();if(!v)return;line('caller',v);i.value='';setTimeout(function(){line('ai',answer(v));},500);}
document.getElementById('send').onclick=ask;document.getElementById('say').addEventListener('keydown',function(e){if(e.key==='Enter')ask();});'''

# ---------------- email
email = '''<span class="eyebrow">Email Intelligence</span>
<h1>Your inbox, sorted, with replies ready for approval</h1>
<p class="lede">Pick a fictional message. See how it is sorted, what the draft is based on, and approve, edit or reject it. Nothing is ever sent without a person.</p>
<div class="card"><div class="row" style="justify-content:space-between"><div><h3 style="margin:0">Mailbox connection (demo)</h3><p class="small muted" style="margin:4px 0 0">Read-only access. We can read and label. We cannot send, delete or change anything.</p></div><span class="tag solid">Read-only</span></div></div>
<div class="grid g2" style="grid-template-columns:minmax(0,1fr)">
<section class="card" aria-labelledby="inh"><h2 id="inh">Inbox</h2><div id="inbox" role="list"></div></section>
<section class="card" id="view" aria-live="polite"></section></div>
<div class="card"><h3>Audit log (demo)</h3><ul id="log" class="small muted" style="margin:0;padding-left:18px"><li>No actions yet.</li></ul></div>
<div class="card real-panel"><h3>Built in, in the real version</h3><ul><li>Secure sign-in with your mail provider, least-privilege read-only first.</li><li>Drafts use only information you approve (your price list, hours, policies), and say so.</li><li>Every send is a manual approval, logged with who and when. Untrusted mail is treated as untrusted.</li></ul></div>'''
email_js = '''
var mails=[
{id:1,from:'Jordan Lee (fictional)',subj:'Quote for 3 offices?',cat:'Sales lead',pri:'High',body:'Hi, we are opening three small offices in Henderson and need phones answered and a shared inbox. Can you send pricing and a time to talk this week?',draft:'Hi Jordan, thanks for reaching out. For three offices we usually start with a short call to learn your hours and how calls should be routed, then send a written quote. I can offer Wednesday 10:00 AM or Thursday 2:00 PM. Which works for you?',src:['Pricing policy: written quote after discovery call','Calendar: Wed 10:00 AM, Thu 2:00 PM open']},
{id:2,from:'Priya Nair (fictional)',subj:'Invoice question',cat:'Billing',pri:'Normal',body:'Hello, my invoice shows a charge I do not recognize from the 12th. Can someone explain it?',draft:'Hi Priya, thank you for flagging this. I am asking our billing team to review the charge from the 12th and I will reply with a clear explanation. You do not need to do anything right now.',src:['Billing policy: explain every line item','No refund promised without approval']},
{id:3,from:'Newsletter (fictional)',subj:'10 tips for spring marketing',cat:'Newsletter',pri:'Low',body:'This week in marketing: tip 1 ... tip 10.',draft:'',src:[]},
{id:4,from:'Unknown sender (fictional)',subj:'URGENT: wire payment today',cat:'Possible scam',pri:'Review',body:'Please wire $4,800 today to the account below. Reply only to this address.',draft:'',src:[]}];
var cur=null,ib=document.getElementById('inbox'),vw=document.getElementById('view');
function addLog(t){var l=document.getElementById('log');if(l.firstChild&&l.firstChild.textContent==='No actions yet.')l.innerHTML='';var li=document.createElement('li');li.textContent=t;l.appendChild(li);}
function renderList(){ib.innerHTML='';mails.forEach(function(m){var b=document.createElement('button');b.className='btn ghost';b.style.cssText='width:100%;justify-content:space-between;text-align:left;margin:0 0 8px;border-radius:12px;height:auto;min-height:56px;flex-wrap:wrap';b.setAttribute('role','listitem');b.innerHTML='<span><b>'+m.subj+'</b><br><span class="small muted">'+m.from+'</span></span><span class="tag '+(m.pri==='High'?'solid':'')+'">'+m.cat+'</span>';b.onclick=function(){open(m.id)};ib.appendChild(b);});}
function open(id){cur=mails.filter(function(m){return m.id===id})[0];var m=cur;var h='<h2>'+m.subj+'</h2><p class="small muted">From '+m.from+'</p><p>'+m.body+'</p><div class="row"><span class="tag">'+m.cat+'</span><span class="tag outline">Priority: '+m.pri+'</span></div><hr class="hr">';
if(m.draft){h+='<h3>Draft reply (needs approval)</h3><textarea id="dr" rows="6" aria-label="Draft reply">'+m.draft+'</textarea><p class="small muted">Based on:</p><div class="row">'+m.src.map(function(s){return '<span class="tag mute">'+s+'</span>'}).join('')+'</div><div class="row" style="margin-top:12px"><button class="btn" id="ap">Approve</button><button class="btn ghost" id="ed">Save edit</button><button class="btn ghost" id="rj">Reject</button></div>';}
else if(m.cat==='Possible scam'){h+='<h3>No reply drafted</h3><p class="muted">This looks like a payment scam: urgent wire request from an unknown sender. It is held for a person and never answered automatically.</p><div class="row"><button class="btn" id="fl">Flag and hold</button></div>';}
else{h+='<h3>No reply needed</h3><p class="muted">Sorted as a newsletter. No draft is created.</p><div class="row"><button class="btn ghost" id="ar">Archive label</button></div>';}
vw.innerHTML=h;addLog('Opened: '+m.subj);
var q=function(i,f){var e=document.getElementById(i);if(e)e.onclick=f;};
q('ap',function(){toast('Demo: approved. In a real setup a person sends it. Nothing was sent.');addLog('Approved draft for "'+m.subj+'" (demo, not sent)');});
q('ed',function(){toast('Demo: edit saved. Nothing was sent.');addLog('Edited draft for "'+m.subj+'"');});
q('rj',function(){toast('Draft rejected.');addLog('Rejected draft for "'+m.subj+'"');});
q('fl',function(){toast('Held for review.');addLog('Flagged "'+m.subj+'" as possible scam');});
q('ar',function(){toast('Demo: labeled, nothing deleted.');addLog('Labeled "'+m.subj+'"');});}
renderList();open(1);'''

# ---------------- sales
sales = '''<span class="eyebrow">Sales Partner Network</span>
<h1>A clear way for partners to sell, and be paid fairly</h1>
<p class="lede">An example service catalog, quote builder, pipeline and commission model. Prices, names and numbers are made up. Real terms need a written agreement and legal review before anyone is enrolled.</p>
<div class="row" role="tablist" aria-label="Sales demo sections" id="tabs" style="margin-bottom:12px"></div>
<section id="p-catalog" class="card"></section><section id="p-quote" class="card" hidden></section><section id="p-pipe" class="card" hidden></section><section id="p-comm" class="card" hidden></section>
<div class="card real-panel"><h3>Not a promise of income</h3><p class="small muted">The commission screen is a calculator with example numbers. Earnings depend on real sales, collected payments, costs and refunds, and are set only by a signed agreement. This is not a job offer or a guarantee of earnings.</p></div>'''
sales_js = '''
var cat=[{n:'Voice receptionist (example)',s:'prototype',setup:0,mo:0},{n:'Email intelligence (example)',s:'prototype',setup:0,mo:0},{n:'Website refresh (example)',s:'approved',setup:1500,mo:99},{n:'Review management (example)',s:'available',setup:300,mo:149},{n:'Scheduling automation (example)',s:'draft',setup:0,mo:0},{n:'Legacy bundle (example)',s:'retired',setup:0,mo:0}];
var live=function(s){return s==='approved'||s==='available'};
var tabs=[['catalog','Catalog'],['quote','Quote'],['pipe','Pipeline'],['comm','Commission']],tb=document.getElementById('tabs');
tabs.forEach(function(t,i){var b=document.createElement('button');b.className='btn '+(i?'ghost':'');b.setAttribute('role','tab');b.setAttribute('aria-selected',i?'false':'true');b.textContent=t[1];b.onclick=function(){show(t[0],b)};tb.appendChild(b);});
function show(id,btn){tabs.forEach(function(t){document.getElementById('p-'+t[0]).hidden=t[0]!==id});[].forEach.call(tb.children,function(c){c.className='btn ghost';c.setAttribute('aria-selected','false')});btn.className='btn';btn.setAttribute('aria-selected','true');}
var tagc={draft:'mute',prototype:'outline',approved:'',available:'solid',retired:'mute'};
document.getElementById('p-catalog').innerHTML='<h2>Service catalog</h2><p class="small muted">Only <b>approved</b> or <b>available</b> services can be quoted or billed as live products. Prototypes and drafts are ideas.</p><table><tr><th>Service</th><th>State</th><th>Setup</th><th>Monthly</th></tr>'+cat.map(function(c){return '<tr><td>'+c.n+'</td><td><span class="tag '+tagc[c.s]+'">'+c.s+'</span></td><td>'+(live(c.s)?'$'+c.setup.toLocaleString():'-')+'</td><td>'+(live(c.s)?'$'+c.mo:'-')+'</td></tr>'}).join('')+'</table>';
var q=document.getElementById('p-quote');q.innerHTML='<h2>Quote builder</h2><p class="small muted">Multi-service quote. Services that are not approved or available cannot be added.</p><div id="qs"></div><hr class="hr"><table><tr><th>One-time setup</th><td id="qSetup">$0</td></tr><tr><th>Monthly</th><td id="qMo">$0</td></tr><tr><th>First-year total</th><td id="qYr"><b>$0</b></td></tr></table><p class="small muted">Example pricing, not an offer.</p><div class="row"><button class="btn" id="qsend">Save quote (demo)</button></div>';
var qs=document.getElementById('qs');cat.forEach(function(c,i){var d=document.createElement('label');d.style.cssText='display:flex;gap:10px;align-items:center;font-weight:600';d.innerHTML='<input type="checkbox" style="width:auto;min-height:0" data-i="'+i+'"'+(live(c.s)?'':' disabled')+'> '+c.n+' <span class="tag '+tagc[c.s]+'">'+c.s+'</span>';qs.appendChild(d);});
function calc(){var su=0,mo=0;[].forEach.call(qs.querySelectorAll('input:checked'),function(i){var c=cat[i.getAttribute('data-i')];su+=c.setup;mo+=c.mo;});document.getElementById('qSetup').textContent='$'+su.toLocaleString();document.getElementById('qMo').textContent='$'+mo.toLocaleString();document.getElementById('qYr').innerHTML='<b>$'+(su+mo*12).toLocaleString()+'</b>';}
qs.addEventListener('change',calc);document.getElementById('qsend').onclick=function(){toast('Demo: quote saved to a fictional CRM. Nothing was sent to a customer.');};
var stages=['New lead','Qualified','Proposal sent','Won','Lost'],deals=[{n:'Harbor Cafe (fictional)',s:0,v:'$1,800'},{n:'Peak Fitness (fictional)',s:1,v:'$2,400'},{n:'Sunrise Dental (fictional)',s:2,v:'$3,100'},{n:'Oak Legal (fictional)',s:3,v:'$1,500'}];
function drawPipe(){var p=document.getElementById('p-pipe');p.innerHTML='<h2>Pipeline</h2><p class="small muted">Move a deal with the buttons. Demo data only.</p><div class="grid" style="grid-template-columns:repeat(auto-fit,minmax(170px,1fr))">'+stages.map(function(st,si){return '<div class="card" style="margin:0;background:var(--bg2)"><h3>'+st+'</h3>'+deals.filter(function(d){return d.s===si}).map(function(d,di){var idx=deals.indexOf(d);return '<div class="card" style="padding:10px"><b>'+d.n+'</b><div class="small muted">'+d.v+'</div><div class="row" style="margin-top:8px"><button class="btn ghost" style="min-height:36px;padding:6px 10px" data-m="'+idx+'" data-d="-1" '+(si===0?'disabled':'')+'>Back</button><button class="btn" style="min-height:36px;padding:6px 10px" data-m="'+idx+'" data-d="1" '+(si===4?'disabled':'')+'>Next</button></div></div>'}).join('')+'</div>'}).join('')+'</div>';[].forEach.call(p.querySelectorAll('button[data-m]'),function(b){b.onclick=function(){deals[+b.getAttribute('data-m')].s+= +b.getAttribute('data-d');drawPipe();}});}
drawPipe();
var c=document.getElementById('p-comm');c.innerHTML='<h2>Commission calculator (example)</h2><p class="small muted">Modelled policy for discussion: 50% of defined commissionable collected revenue on a partner\\'s own attributed customers, after approved direct variable costs and refunds. The exact definition must be set in a signed agreement.</p><div class="grid g2"><div><label for="cr">Collected revenue ($)</label><input id="cr" type="number" min="0" value="2000"><label for="cc">Approved direct variable costs ($)</label><input id="cc" type="number" min="0" value="200"><label for="cf">Refunds ($)</label><input id="cf" type="number" min="0" value="0"></div><div class="card" style="margin:0"><h3>Estimate</h3><p class="small muted" style="margin:0">Commissionable revenue</p><p style="font-size:22px;margin:0 0 8px" id="co">$0</p><p class="small muted" style="margin:0">Estimated commission (50%)</p><p style="font-size:26px;margin:0" id="cm"><b>$0</b></p></div></div><hr class="hr"><h3>Commission ledger states</h3><p class="small muted">Every amount moves through states, each tied to an immutable payment reference. Refunds and chargebacks create reversals.</p><div class="row"><span class="tag outline">estimated</span><span class="tag mute">held</span><span class="tag">earned</span><span class="tag solid">paid</span><span class="tag pale">reversed</span></div><hr class="hr"><h3>Proposed performance levels</h3><table><tr><th>Level</th><th>Idea</th></tr><tr><td>Partner</td><td>Sells own customers</td></tr><tr><td>Senior partner</td><td>Consistent verified sales</td></tr><tr><td>Team leader</td><td>Mentors partners (bonus only under a written, owner-approved policy)</td></tr><tr><td>Regional director</td><td>Region results and quality</td></tr><tr><td>National director</td><td>Network results and quality</td></tr></table><p class="small muted">No reward for recruiting alone. Levels and any leadership bonus need owner approval and legal review before use.</p>';
function comm(){var r=+document.getElementById('cr').value||0,x=+document.getElementById('cc').value||0,f=+document.getElementById('cf').value||0;var base=Math.max(0,r-x-f);document.getElementById('co').textContent='$'+base.toLocaleString();document.getElementById('cm').innerHTML='<b>$'+(Math.round(base*50)/100).toLocaleString()+'</b>';}
['cr','cc','cf'].forEach(function(i){document.getElementById(i).oninput=comm;});comm();'''

for name, title, desc, body, js, cur in [
    ('index', 'KEY Platform demos | Key Technologies.si', 'Clearly labeled demos of Voice, Email and Sales services.', hub, '', 'hub'),
    ('voice', 'Voice Services demo | Key Technologies.si', 'Demo of an AI receptionist: calls, lead capture and routing.', voice, voice_js, 'voice'),
    ('email', 'Email Intelligence demo | Key Technologies.si', 'Demo of inbox triage and approval-first draft replies.', email, email_js, 'email'),
    ('sales', 'Sales Partner Network demo | Key Technologies.si', 'Demo of a service catalog, quotes, pipeline and commission model.', sales, sales_js, 'sales')]:
    open(os.path.join(OUT, name + '.html'), 'w').write(page(name, title, desc, body, js, cur))
    print('wrote', name)
