#!/usr/bin/env python3
"""Builds sites/key-technologies/book.html (the "Book a call" request page) on the shared site shell.
Run from the repo root: python3 docs/key-integration/build_book_page.py
Availability is set at the top of the page script (HOURS, DAYS_AHEAD, BLOCKED)."""
import re
SITE = 'sites/key-technologies/'
idx = open(SITE + 'index.html', encoding='utf-8').read()
def grab(a, b):
    i = idx.index(a); return idx[i:idx.index(b, i) + len(b)]
HEADER = grab('<header>', '</header>'); MENU = grab('<div class="mobile-menu" id="mobileMenu">', '\n</div>\n'); FOOTER = grab('<footer>', '</footer>')
def fix(h):
    h = h.replace('href="#"', 'href="index.html"')
    h = re.sub(r'href="#([a-z-]+)"', lambda m: 'href="index.html#%s"' % m.group(1), h)
    h = h.replace('index.html#lead-short">Book a Call', 'book.html">Book a Call')
    return h.replace('<span id="year"></span>', '<span id="kpYear"></span>')
hub = open(SITE + 'key-platform/index.html', encoding='utf-8').read()
a = hub.index('<script>(function(){var b=document.getElementById("burgerBtn")'); BURGER = hub[a:hub.index('</script>', a) + 9]
body = '''<main id="main" class="wrap kp-main">
<section class="page active" style="display:block;padding-top:6px">
<div class="hero"><span class="eyebrow">Free call</span><h1 style="margin-top:10px">Book a <span>free call</span></h1>
<p>Thirty minutes to talk through your business and where AI/SI could actually help. No pitch, no cost, no obligation. Pick a time below and we will confirm it by reply. Nothing is booked until we confirm.</p></div>
<div class="two-columns" style="margin-top:26px;align-items:start">
<div class="lead-card" aria-labelledby="pickh"><span class="eyebrow">Step 1</span><h2 id="pickh" style="margin-top:6px">Pick a day and time</h2>
<div class="field"><label for="tz">Your time zone</label><select id="tz"></select></div>
<p class="form-note" style="margin:8px 0 6px">Days with open times</p><div class="row" id="days" style="gap:8px" role="group" aria-label="Choose a day"></div>
<p class="form-note" style="margin:14px 0 6px" id="slotlabel">Choose a day to see times</p><div class="row" id="slots" style="gap:8px" role="group" aria-label="Choose a time"></div></div>
<div class="lead-card" aria-labelledby="forh"><span class="eyebrow">Step 2</span><h2 id="forh" style="margin-top:6px">Where do we reach you?</h2>
<div id="chosen" class="note" style="margin:10px 0 0">No time chosen yet.</div>
<form id="bform" novalidate>
<div class="field"><label for="bn">Full name <span class="req">*</span></label><input id="bn" name="name" autocomplete="name" required maxlength="80"></div>
<div class="field"><label for="be">Email <span class="req">*</span></label><input id="be" name="email" type="email" autocomplete="email" required maxlength="120"></div>
<div class="field"><label for="bp">Phone (for a text confirmation)</label><input id="bp" name="phone" type="tel" autocomplete="tel" maxlength="30"></div>
<div class="field"><label for="bt">What do you want to talk about?</label><select id="bt" name="topic"><option>Not sure yet</option><option>Phone and text answering</option><option>Email and follow-up</option><option>Website or CRM</option><option>Social media and content</option><option>Security</option><option>Rewards program</option><option>Something else</option></select></div>
<div class="field"><label for="bm">Anything we should know first? (optional)</label><textarea id="bm" name="notes" rows="3" maxlength="600"></textarea></div>
<div class="field" style="position:absolute;left:-9999px" aria-hidden="true"><label for="bw">Leave this empty</label><input id="bw" name="website" tabindex="-1" autocomplete="off"></div>
<p class="form-note">We use this only to confirm and hold your call. See the <a href="privacy.html">privacy page</a>. Please do not enter bank, tax or ID numbers.</p>
<button class="btn btn-primary" type="submit" id="bs">Request this time</button><p id="bstatus" role="status" aria-live="polite" class="form-status"></p><div id="bdone"></div></form></div></div>
<div class="kp-foot-note"><b>How it works.</b> You request a time. We reply to confirm it, or suggest a nearby time if it is taken, usually within one business day. Calls are by phone or video, in Pacific Time unless you change the time zone above. There is no charge.</div>
</section></main>'''
js = '''<script>(function(){
/* ---- availability: edit here ---- */
var HOURS={start:9,end:17,stepMin:30};      // Pacific Time, last slot starts before "end"
var DAYS_AHEAD=14, MIN_HOURS_NOTICE=24, WEEKDAYS=[1,2,3,4,5]; // 1 = Monday
var BLOCKED=[];                              // dates to close, like "2026-11-26"
var LEADS="https://lvr-data-a60c1-default-rtdb.firebaseio.com/key_leads/leads.json",FS="https://formspree.io/f/mzeedbyb";
var LA="America/Los_Angeles";
function parts(t,tz){var f=new Intl.DateTimeFormat("en-US",{timeZone:tz,year:"numeric",month:"2-digit",day:"2-digit",hour:"2-digit",minute:"2-digit",hourCycle:"h23"}).formatToParts(new Date(t)),o={};f.forEach(function(p){o[p.type]=+p.value});return o}
function laToUtc(y,m,d,h,mi){var want=Date.UTC(y,m-1,d,h,mi),t=want;for(var i=0;i<3;i++){var p=parts(t,LA);t-=Date.UTC(p.year,p.month-1,p.day,p.hour,p.minute)-want}return t}
function fmt(t,tz,o){return new Intl.DateTimeFormat("en-US",Object.assign({timeZone:tz},o)).format(new Date(t))}
var tzSel=document.getElementById("tz"),daysEl=document.getElementById("days"),slotsEl=document.getElementById("slots"),chosenEl=document.getElementById("chosen");
var myTz=(Intl.DateTimeFormat().resolvedOptions().timeZone)||LA;
var zones=[["America/Los_Angeles","Pacific Time"],["America/Denver","Mountain Time"],["America/Phoenix","Arizona"],["America/Chicago","Central Time"],["America/New_York","Eastern Time"]];
if(!zones.some(function(z){return z[0]===myTz}))zones.unshift([myTz,myTz.replace(/_/g," ")]);
zones.forEach(function(z){var o=document.createElement("option");o.value=z[0];o.textContent=z[1];if(z[0]===myTz)o.selected=true;tzSel.appendChild(o)});
// build the open days (Pacific calendar days)
var now=Date.now(),days=[];
for(var k=0;k<DAYS_AHEAD+7&&days.length<DAYS_AHEAD;k++){var base=now+k*86400000,p=parts(base,LA),dt=new Date(Date.UTC(p.year,p.month-1,p.day)),dow=dt.getUTCDay();
 var key=p.year+"-"+("0"+p.month).slice(-2)+"-"+("0"+p.day).slice(-2);
 if(WEEKDAYS.indexOf(dow===0?7:dow)<0||BLOCKED.indexOf(key)>=0)continue;
 var slots=[];for(var m=HOURS.start*60;m<HOURS.end*60;m+=HOURS.stepMin){var t=laToUtc(p.year,p.month,p.day,Math.floor(m/60),m%60);if(t>=now+MIN_HOURS_NOTICE*3600000)slots.push(t)}
 if(slots.length)days.push({key:key,slots:slots,first:slots[0]})}
var selDay=null,selSlot=null;
function drawDays(){daysEl.innerHTML="";days.forEach(function(d){var b=document.createElement("button");b.type="button";b.className="kp-chip";b.setAttribute("aria-pressed",selDay===d?"true":"false");b.textContent=fmt(d.first,tzSel.value,{weekday:"short",month:"short",day:"numeric"});b.onclick=function(){selDay=d;selSlot=null;drawDays();drawSlots();showChosen()};daysEl.appendChild(b)});if(!days.length)daysEl.textContent="No open times right now. Please use the contact form on the main page."}
function drawSlots(){slotsEl.innerHTML="";if(!selDay){document.getElementById("slotlabel").textContent="Choose a day to see times";return}document.getElementById("slotlabel").textContent="Times on "+fmt(selDay.first,tzSel.value,{weekday:"long",month:"long",day:"numeric"})+" ("+tzSel.options[tzSel.selectedIndex].text+")";
 selDay.slots.forEach(function(t){var b=document.createElement("button");b.type="button";b.className="kp-chip";b.setAttribute("aria-pressed",selSlot===t?"true":"false");b.textContent=fmt(t,tzSel.value,{hour:"numeric",minute:"2-digit"});b.onclick=function(){selSlot=t;drawSlots();showChosen()};slotsEl.appendChild(b)})}
function showChosen(){chosenEl.textContent=selSlot?"Requested: "+fmt(selSlot,tzSel.value,{weekday:"long",month:"long",day:"numeric",hour:"numeric",minute:"2-digit"})+" ("+tzSel.options[tzSel.selectedIndex].text+")":"No time chosen yet."}
tzSel.onchange=function(){drawDays();drawSlots();showChosen()};
drawDays();
var f=document.getElementById("bform"),st=document.getElementById("bstatus");
function ics(t,name){function z(n){return ("0"+n).slice(-2)}function d(x){var u=new Date(x);return u.getUTCFullYear()+z(u.getUTCMonth()+1)+z(u.getUTCDate())+"T"+z(u.getUTCHours())+z(u.getUTCMinutes())+"00Z"}
 return "BEGIN:VCALENDAR\\r\\nVERSION:2.0\\r\\nPRODID:-//Key Technologies//Call request//EN\\r\\nBEGIN:VEVENT\\r\\nUID:call-"+t+"@keytechnologies.si\\r\\nDTSTAMP:"+d(Date.now())+"\\r\\nDTSTART:"+d(t)+"\\r\\nDTEND:"+d(t+1800000)+"\\r\\nSTATUS:TENTATIVE\\r\\nSUMMARY:Call with Key Technologies (requested, not yet confirmed)\\r\\nDESCRIPTION:Requested time. Key Technologies will confirm by reply.\\r\\nEND:VEVENT\\r\\nEND:VCALENDAR\\r\\n"}
f.addEventListener("submit",function(e){e.preventDefault();st.className="form-status";
 if(!selSlot){st.textContent="Please choose a day and a time first.";st.className="form-status err";return}
 var nm=f.name.value.trim(),em=f.email.value.trim();if(!nm){f.name.focus();st.textContent="Please enter your name.";st.className="form-status err";return}
 if(!/^\\S+@\\S+\\.\\S+$/.test(em)){f.email.focus();st.textContent="Please enter a valid email.";st.className="form-status err";return}
 if(f.website.value){st.textContent="Thank you.";st.className="form-status ok";return}
 var d={source:"book-a-call",interests:["Book a call"],name:nm.slice(0,80),email:em,phone:f.phone.value.trim().slice(0,30),topic:f.topic.value,notes:f.notes.value.trim().slice(0,600),
  requestedTimeUtc:new Date(selSlot).toISOString(),requestedTimePacific:fmt(selSlot,LA,{weekday:"short",month:"short",day:"numeric",hour:"numeric",minute:"2-digit"})+" PT",visitorTimeZone:tzSel.value,
  createdAt:{".sv":"timestamp"},landingPage:location.pathname};
 var b=document.getElementById("bs");b.disabled=true;st.textContent="Sending...";
 fetch(LEADS,{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify(d)}).then(function(r){if(!r.ok)throw new Error(r.status);
  fetch(FS,{method:"POST",headers:{"Content-Type":"application/json",Accept:"application/json"},body:JSON.stringify(d)}).catch(function(){});
  st.textContent="";var url="data:text/calendar;charset=utf-8,"+encodeURIComponent(ics(selSlot));
  document.getElementById("bdone").innerHTML="<div class=\\"note\\" style=\\"margin-top:14px\\"><b>Request received.</b> "+chosenEl.textContent.replace("Requested: ","")+". We will confirm by reply, or suggest a nearby time. It is not booked until we confirm.<br><a href=\\""+url+"\\" download=\\"key-technologies-call-request.ics\\">Add it to my calendar as tentative</a></div>";
  f.querySelectorAll("input,select,textarea,button").forEach(function(x){x.disabled=true});
 }).catch(function(){st.textContent="Something went wrong. Please try again, or use the contact form on the main page.";st.className="form-status err";b.disabled=false});
});})();</script>'''
page = '''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Book a Free Call | Key Technologies.si</title>
<meta name="description" content="Book a free 30-minute call with Key Technologies to talk through your business and where AI/SI and automation could actually help. Pick a time and we confirm by reply.">
<link rel="canonical" href="https://keytechnologies.si/book.html"><meta name="theme-color" content="#0f171e">
<meta property="og:type" content="website"><meta property="og:title" content="Book a Free Call | Key Technologies.si"><meta property="og:description" content="Thirty minutes, no pitch, no cost. Pick a time and we confirm by reply."><meta property="og:url" content="https://keytechnologies.si/book.html"><meta property="og:image" content="https://keytechnologies.si/og-image.png"><meta name="twitter:card" content="summary_large_image">
<link rel="icon" href="apple-touch-icon.png"><link rel="apple-touch-icon" href="apple-touch-icon.png"><link rel="manifest" href="site.webmanifest">
<link rel="stylesheet" href="/fonts/lato.css">
<link rel="stylesheet" href="key-platform/site-base.css"><link rel="stylesheet" href="key-platform/kp.css"></head><body>
%s
%s
%s
%s
<div id="toast" role="status" aria-live="polite"></div>
%s
%s
</body></html>''' % (fix(HEADER), fix(MENU), body, fix(FOOTER), BURGER, js)
open(SITE + 'book.html', 'w', encoding='utf-8').write(page)
print('wrote book.html')
