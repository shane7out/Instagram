/* KEY Platform: "Want this for your business?" follow-up form at the end of each demo.
   Sends the visitor's first name, last name, email and phone number to the same leads list the site's other forms use,
   with the demo name, so Key Technologies can reply about that demo. Nothing is sent until the visitor presses the button. */
(function(){
'use strict';
var LEADS='https://lvr-data-a60c1-default-rtdb.firebaseio.com/key_leads/leads.json',FS='https://formspree.io/f/mzeedbyb';
function esc(t){return String(t).replace(/[&<>"]/g,function(x){return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[x]})}
function init(){
 var main=document.querySelector('.kp-main');if(!main||document.getElementById('kpFollow'))return;
 var here=location.pathname.replace(/^.*key-platform\//,'');if(here===''||here==='index.html'||here==='partners.html')return;
 var h1=document.querySelector('.hero h1,.page.active h1,h1');var title=(document.title||'').replace(/\s*\|.*$/,'').replace(/\s+demo$/i,'').trim()||(h1?h1.textContent.trim():'Demo');
 var box=document.createElement('section');box.id='kpFollow';box.className='kp-follow';box.setAttribute('aria-labelledby','kpFollowH');
 box.innerHTML='<div class="kp-follow-in"><div><span class="eyebrow">Next step</span><h2 id="kpFollowH">Want this for your business?</h2><p>Leave your name, business name, email and phone number and Key Technologies will reply about <b>'+esc(title)+'</b>. Just a reply about this demo, no mailing list.</p></div>'+
 '<form id="kpFollowForm" novalidate><div class="name-row" style="display:grid;grid-template-columns:1fr 1fr;gap:10px"><div class="field"><label for="kff">First name <span class="req">*</span></label><input id="kff" name="firstName" autocomplete="given-name" maxlength="40" required></div><div class="field"><label for="kfl">Last name <span class="req">*</span></label><input id="kfl" name="lastName" autocomplete="family-name" maxlength="40" required></div></div>'+
 '<div class="field"><label for="kfb">Business name <span class="req">*</span></label><input id="kfb" name="business" autocomplete="organization" maxlength="100" required></div>'+
 '<div class="field"><label for="kfe">Email <span class="req">*</span></label><input id="kfe" name="email" type="email" autocomplete="email" required></div>'+
 '<div class="field"><label for="kfp">Phone <span class="req">*</span></label><input id="kfp" name="phone" type="tel" autocomplete="tel" maxlength="30" required></div>'+
 '<div class="field" style="position:absolute;left:-9999px" aria-hidden="true"><label for="kfw">Leave this empty</label><input id="kfw" name="website" tabindex="-1" autocomplete="off"></div>'+
 '<button class="btn btn-primary" type="submit" id="kfs">Send my details</button><p class="form-note">We use this only to reply to you. See the <a href="/privacy.html">privacy page</a>. Please do not enter bank, tax or ID numbers.</p><p id="kft" role="status" aria-live="polite" class="form-status"></p></form></div>';
 var anchor=main.querySelector('.demo-strip:last-of-type');
 var foot=main.querySelector('.kp-foot-note');
 if(foot&&foot.parentNode)foot.parentNode.insertBefore(box,foot.nextSibling);else if(anchor)anchor.parentNode.insertBefore(box,anchor);else main.appendChild(box);
 var f=box.querySelector('#kpFollowForm'),st=box.querySelector('#kft');
 f.addEventListener('submit',function(e){e.preventDefault();st.className='form-status';
  var fn=f.firstName.value.trim(),ln=f.lastName.value.trim(),bs=f.business.value.trim(),em=f.email.value.trim(),ph=f.phone.value.trim();
  if(f.website.value){st.textContent='Thank you.';st.className='form-status ok';return}
  var d={source:'demo-follow-up',demo:title,demoPage:location.pathname,interests:['Demo: '+title],email:em,createdAt:{'.sv':'timestamp'},landingPage:location.pathname};
  d.name=(fn+' '+ln).trim().slice(0,80);d.firstName=fn.slice(0,40);d.lastName=ln.slice(0,40);d.phone=ph.slice(0,30);d.business=bs.slice(0,100);
  var b=f.querySelector('#kfs');b.disabled=true;st.textContent='Sending...';
  KTLead.send(LEADS,FS,d).then(function(){
   st.textContent='Thank you. We will reply about this demo soon.';st.className='form-status ok';f.reset();
  }).catch(function(){st.textContent='Something went wrong. Please try again, or use the Contact button at the top.';st.className='form-status err'}).then(function(){b.disabled=false});
 });
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init);else init();
})();
