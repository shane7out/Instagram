/* LVR-mirrored PIN lock screen — external (CSP script-src 'self' blocks inline JS).
   Wires the keypad via event delegation on [data-key]/[data-del]. PIN 137900. */
(function(){
  var PIN='137900', SS='cc_pin_ok', e='', att=0, lock=false, dots=null, wired=false;

  // engage the lock immediately (before DOM ready) unless already unlocked this session
  try{ if(sessionStorage.getItem(SS)==='1'){ ready(unlockInstant); return; } }catch(x){}
  document.documentElement.classList.add('locked');
  ready(init);

  function ready(fn){ if(document.readyState==='loading') document.addEventListener('DOMContentLoaded',fn); else fn(); }

  function unlockInstant(){ var s=document.getElementById('pin-screen'); document.documentElement.classList.remove('locked'); if(s) s.classList.add('hidden'); }

  function unlock(){
    try{ sessionStorage.setItem(SS,'1'); }catch(x){}
    document.documentElement.classList.remove('locked');
    var s=document.getElementById('pin-screen');
    if(s){ s.style.transition='opacity .25s'; s.style.opacity='0'; setTimeout(function(){ s.classList.add('hidden'); },260); }
  }

  function dd(err){
    if(!dots) dots=[0,1,2,3,4,5].map(function(i){ return document.getElementById('pd'+i); });
    for(var i=0;i<6;i++){ if(!dots[i])continue; var c=err?'pin-dot error':(i<e.length?'pin-dot filled':'pin-dot'); if(dots[i].className!==c) dots[i].className=c; }
  }

  // Apple-style "tock" tap sound
  var ctx=null, cb=null;
  function ac(){ if(!ctx) ctx=new (window.AudioContext||window.webkitAudioContext)(); if(ctx.state==='suspended') ctx.resume(); return ctx; }
  function tock(del){ try{
    var c=ac(), n=c.currentTime, f=del?900:1050, r=del?0.022:0.018;
    if(!cb){ var L=Math.floor(c.sampleRate*0.003); cb=c.createBuffer(1,L,c.sampleRate); var cd=cb.getChannelData(0); for(var i=0;i<L;i++) cd[i]=(Math.random()*2-1)*(1-i/L); }
    var cs=c.createBufferSource(); cs.buffer=cb; var cg=c.createGain(); cg.gain.value=0.35; cs.connect(cg); cg.connect(c.destination); cs.start(n);
    var o=c.createOscillator(), g=c.createGain(); o.type='sine'; o.frequency.value=f; g.gain.setValueAtTime(0.18,n); g.gain.exponentialRampToValueAtTime(0.001,n+r); o.connect(g); g.connect(c.destination); o.start(n); o.stop(n+r);
  }catch(x){} }

  function key(d){ if(lock||e.length>=6) return; tock(false); e+=d; dd(false); if(e.length===6) setTimeout(chk,35); }
  function del(){ if(e.length===0) return; tock(true); e=e.slice(0,-1); dd(false); }

  function chk(){
    if(e===PIN){ att=0; e=''; dd(false); unlock(); return; }
    att++; dd(true);
    var D=document.getElementById('pin-dots'); if(D){ D.classList.remove('shake'); void D.offsetWidth; D.classList.add('shake'); }
    if(navigator.vibrate) try{ navigator.vibrate(200); }catch(x){}
    var msg=document.getElementById('pin-msg');
    if(att>=5){ lock=true; if(msg)msg.textContent='Too many attempts. Locked for 30s.'; setTimeout(function(){ lock=false; att=0; e=''; dd(false); if(msg)msg.textContent=''; },30000); }
    else { if(msg)msg.textContent='Incorrect PIN. '+(5-att)+' tries left.'; setTimeout(function(){ e=''; dd(false); if(msg)msg.textContent=''; },900); }
  }

  function init(){
    if(wired) return; wired=true;
    var screen=document.getElementById('pin-screen');
    if(!screen) return;
    var grid=screen.querySelector('.pin-grid') || screen;
    // one delegated handler for taps + clicks
    function onHit(ev){
      var b=ev.target.closest && ev.target.closest('.pin-key'); if(!b) return;
      ev.preventDefault();
      if(b.hasAttribute('data-del')) del();
      else if(b.hasAttribute('data-key')) key(b.getAttribute('data-key'));
    }
    grid.addEventListener('click', onHit);
    // pressed-state visual on touch
    grid.addEventListener('touchstart', function(ev){ var b=ev.target.closest&&ev.target.closest('.pin-key'); if(b) b.classList.add('pressed'); }, {passive:true});
    grid.addEventListener('touchend', function(ev){ var b=ev.target.closest&&ev.target.closest('.pin-key'); if(b) b.classList.remove('pressed'); }, {passive:true});
    // physical keyboard (desktop)
    document.addEventListener('keydown', function(ev){
      if(screen.classList.contains('hidden')) return;
      if(ev.key>='0'&&ev.key<='9') key(ev.key);
      else if(ev.key==='Backspace'){ ev.preventDefault(); del(); }
    });
  }
})();
