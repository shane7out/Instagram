/* KEY Platform: a soft "tap" when you press a demo, with an on/off switch that is remembered in this browser.
   Sound is made in the browser (no audio files). It only plays after a tap or click. */
(function(){
'use strict';
var on=true;
try{on=localStorage.getItem('kpSound')!=='off'}catch(e){}
var ctx=null;
function tick(){
 if(!on)return;
 try{
  var AC=window.AudioContext||window.webkitAudioContext;if(!AC)return;
  ctx=ctx||new AC();if(ctx.state==='suspended')ctx.resume();
  var t=ctx.currentTime,o=ctx.createOscillator(),g=ctx.createGain();
  o.type='sine';o.frequency.setValueAtTime(1250,t);o.frequency.exponentialRampToValueAtTime(760,t+.06);
  g.gain.setValueAtTime(.0001,t);g.gain.exponentialRampToValueAtTime(.07,t+.006);g.gain.exponentialRampToValueAtTime(.0001,t+.09);
  o.connect(g);g.connect(ctx.destination);o.start(t);o.stop(t+.1);
 }catch(e){}
}
var SEL_HOME='a.demo-link,.demo-strip a,a.sw-card,a[data-tap],#mobileMenu a[href*="key-platform"]';
var SEL='a.demo-tile,.demo-link,a.btn,button.primary,button.outline,button.btn,.kp-tabs .nav,.kp-chip,.kp-switch a,.service-card a';
document.addEventListener('click',function(e){
 var t=e.target.closest&&e.target.closest(document.querySelector('.kp-main')?SEL:SEL_HOME);if(!t||t.disabled)return;
 tick();
 // let the tap be heard before another page opens
 if(t.tagName==='A'&&t.href&&e.button===0&&!e.metaKey&&!e.ctrlKey&&!e.shiftKey&&!e.altKey&&!t.target&&t.href.split('#')[0]!==location.href.split('#')[0]){
  e.preventDefault();var href=t.href;document.body.classList.add('kp-leaving');setTimeout(function(){location.href=href},170);
 }
},true);
function addToggle(){
 var row=document.querySelector('.kp-switch');if(!row||document.getElementById('kpSound'))return;
 var b=document.createElement('button');b.type='button';b.id='kpSound';b.className='kp-soundbtn';
 function paint(){b.setAttribute('aria-pressed',on?'true':'false');b.textContent=on?'Sound: on':'Sound: off';b.setAttribute('aria-label',on?'Turn tap sound off':'Turn tap sound on')}
 b.addEventListener('click',function(e){e.stopPropagation();on=!on;try{localStorage.setItem('kpSound',on?'on':'off')}catch(x){}paint();if(on)tick()});
 paint();row.appendChild(b);
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',addToggle);else addToggle();
})();
