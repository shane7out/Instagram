/* KEY Platform: "Want this for your business?" follow-up form at the end of each demo.
   Sends the visitor's email (and optional name) to the same leads list the site's other forms use,
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
 box.innerHTML='<div class="kp-follow-in"><div><span class="eyebrow">Next step</span><h2 id="kpFollowH">Want this for your business?</h2><p>Leave your email and Key Technologies will reply about <b>'+esc(title)+'</b>. Just a reply about this demo, no mailing list.</p></div>'+
 '<form id="kpFollowForm" novalidate><div class="field"><label for="kfe">Email <span class="req">*</span></label><input id="kfe" name="email" type="email" autocomplete="email" required></div>'+
 '<div class="field"><label for="kfn">Name (optional)</label><input id="kfn" name="name" autocomplete="name" maxlength="80"></div>'+
 '<div class="field" style="position:absolute;left:-9999px" aria-hidden="true"><label for="kfw">Leave this empty</label><input id="kfw" name="website" tabindex="-1" autocomplete="off"></div>'+
 '<button class="btn btn-primary" type="submit" id="kfs">Send my details</button><p class="form-note">We use this only to reply to you. See the <a href="/privacy.html">privacy page</a>. Please do not enter bank, tax or ID numbers.</p><p id="kft" role="status" aria-live="polite" class="form-status"></p></form></div>';
 var anchor=main.querySelector('.demo-strip:last-of-type');
 var foot=main.querySelector('.kp-foot-note');
 if(foot&&foot.parentNode)foot.parentNode.insertBefore(box,foot.nextSibling);else if(anchor)anchor.parentNode.insertBefore(box,anchor);else main.appendChild(box);
 var f=box.querySelector('#kpFollowForm'),st=box.querySelector('#kft');
 f.addEventListener('submit',function(e){e.preventDefault();st.className='form-status';
  var em=f.email.value.trim();if(!/^\S+@\S+\.\S+$/.test(em)){f.email.focus();st.textContent='Please enter a valid email.';st.className='form-status err';return}
  if(f.website.value){st.textContent='Thank you.';st.className='form-status ok';return}
  var d={source:'demo-follow-up',demo:title,demoPage:location.pathname,interests:['Demo: '+title],email:em,createdAt:{'.sv':'timestamp'},landingPage:location.pathname};
  var nm=f.name.value.trim();if(nm)d.name=nm.slice(0,80);
  var b=f.querySelector('#kfs');b.disabled=true;st.textContent='Sending...';
  KTLead.send(LEADS,FS,d).then(function(){
   st.textContent='Thank you. We will reply about this demo soon.';st.className='form-status ok';f.reset();
  }).catch(function(){st.textContent='Something went wrong. Please try again, or use the Contact button at the top.';st.className='form-status err'}).then(function(){b.disabled=false});
 });
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init);else init();
})();
